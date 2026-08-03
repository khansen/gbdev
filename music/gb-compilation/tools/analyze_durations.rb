#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require_relative "catalog_lib"

FRAMES_PER_SECOND = 60
MUSIC_TRACK_COUNT = 4
MAX_ANALYSIS_FRAMES = 60 * 60 * 20

Section = Struct.new(:items, :bytes, :words, keyword_init: true)
Track = Struct.new(
  :active,
  :speed,
  :tick,
  :row_count,
  :row,
  :row_status,
  :order_pos,
  :pattern_label,
  :pattern_bytes,
  :pattern_ptr,
  :loop_frame,
  :rows_processed,
  keyword_init: true
)

Result = Struct.new(
  :song,
  :frames,
  :seconds,
  :track_frames,
  :rows,
  :speed_changes,
  :warnings,
  keyword_init: true
)

class AsmData
  attr_reader :path

  def initialize(path)
    @path = path
    @sections = {}
  end

  def self.load(path)
    new(path).tap(&:parse)
  end

  def section(label)
    @sections.fetch(label) do
      raise "#{path}: missing label #{label}"
    end
  end

  def parse
    current = nil
    File.readlines(path).each_with_index do |line, line_no|
      line = line.sub(/;.*/, "").strip
      next if line.empty?

      if (match = line.match(/\A([A-Za-z_][A-Za-z0-9_]*):\z/))
        current = (@sections[match[1]] = Section.new(items: [], bytes: [], words: []))
        next
      end

      next if current.nil?

      if (match = line.match(/\A\.?db\s+(.+)\z/i))
        parse_operands(match[1]).each do |operand|
          value = parse_number(operand, line_no)
          current.items << [:db, value]
          current.bytes << value
        end
      elsif (match = line.match(/\A\.?dw\s+(.+)\z/i))
        parse_operands(match[1]).each do |operand|
          value = numeric?(operand) ? parse_number(operand, line_no) : operand
          current.items << [:dw, value]
          current.words << value
        end
      else
        raise "#{path}:#{line_no}: unsupported generated asm line: #{line}"
      end
    end
  end

  private

  def parse_operands(text)
    text.split(",").map(&:strip).reject(&:empty?)
  end

  def numeric?(operand)
    operand.match?(/\A(?:\$[0-9a-f]+|0x[0-9a-f]+|\d+)\z/i)
  end

  def parse_number(operand, line_no)
    value =
      if operand.start_with?("$")
        Integer(operand[1..], 16)
      elsif operand.match?(/\A0x/i)
        Integer(operand, 16)
      else
        Integer(operand, 10)
      end
    raise "#{path}:#{line_no}: byte value out of range: #{operand}" unless value.between?(0, 0xff)

    value
  end
end

class DurationAnalyzer
  attr_reader :song, :data, :speed_changes, :warnings

  def initialize(song, generated_dir)
    @song = song
    @data = AsmData.load(File.join(generated_dir, "#{song.slug}.inc"))
    @speed_changes = []
    @warnings = []
  end

  def analyze
    read_song_descriptor
    simulate_until_first_loop
    frames = @tracks.select(&:active).map(&:loop_frame).compact.max
    seconds = (frames + FRAMES_PER_SECOND - 1) / FRAMES_PER_SECOND

    Result.new(
      song: song,
      frames: frames,
      seconds: seconds,
      track_frames: @tracks.map(&:loop_frame),
      rows: @tracks.map(&:rows_processed),
      speed_changes: speed_changes,
      warnings: warnings
    )
  end

  private

  def read_song_descriptor
    items = data.section("#{song.prefix}_song").items
    cursor = 0
    @tracks = MUSIC_TRACK_COUNT.times.map do |track_index|
      order_pos = expect_item(items, cursor, :db, "track #{track_index} order position")
      speed = expect_item(items, cursor + 1, :db, "track #{track_index} speed")
      cursor += 2
      Track.new(
        active: order_pos != 0xff,
        speed: speed,
        tick: speed == 0xff ? 0xff : speed - 1,
        row_count: 1,
        row: 0,
        row_status: 0,
        order_pos: order_pos,
        pattern_label: nil,
        pattern_bytes: nil,
        pattern_ptr: 0,
        loop_frame: nil,
        rows_processed: 0
      )
    end

    expect_item(items, cursor, :dw, "instrument table")
    pattern_table_label = expect_item(items, cursor + 1, :dw, "pattern table")
    cursor += 2

    @pattern_table = data.section(pattern_table_label).words
    @order_data = items[cursor..].map do |kind, value|
      raise "#{song.slug}: order data contains #{kind}, expected db" unless kind == :db

      value
    end
  end

  def expect_item(items, index, expected_kind, description)
    kind, value = items.fetch(index) do
      raise "#{song.slug}: missing #{description}"
    end
    raise "#{song.slug}: #{description} is #{kind}, expected #{expected_kind}" unless kind == expected_kind

    value
  end

  def simulate_until_first_loop
    @frame = 0
    until @tracks.select(&:active).all?(&:loop_frame)
      raise "#{song.slug}: no loop found within #{MAX_ANALYSIS_FRAMES} frames" if @frame > MAX_ANALYSIS_FRAMES

      @tracks.each_with_index do |track, track_index|
        next unless track.active

        speed = track.speed
        raise "#{song.slug}: track #{track_index} has invalid speed #{speed}" unless speed.between?(1, 0xfe)

        track.tick = (track.tick + 1) & 0xff
        next unless track.tick == speed

        track.tick = 0
        process_next_row(track, track_index)
      end
      @frame += 1
    end
  end

  def process_next_row(track, track_index)
    track.row = (track.row + 1) & 0xff
    if track.row == track.row_count
      load_next_pattern(track, track_index)
    else
      process_current_row(track, track_index)
    end
  end

  def load_next_pattern(track, track_index)
    order_fetches = 0
    loop do
      order_pos = track.order_pos
      order_byte = fetch_order_byte(order_pos, track_index)
      track.order_pos = order_pos + 1

      if order_byte >= 0xf0
        target = fetch_order_byte(order_pos + 1, track_index)
        track.loop_frame ||= @frame if target <= order_pos
        track.order_pos = target
        order_fetches += 1
        raise "#{song.slug}: track #{track_index} order loop did not resolve" if order_fetches > @order_data.length

        next
      end

      track.pattern_label = @pattern_table.fetch(order_byte) do
        raise "#{song.slug}: track #{track_index} pattern #{order_byte} missing"
      end
      track.pattern_bytes = data.section(track.pattern_label).bytes
      track.row_count = track.pattern_bytes.fetch(0) do
        raise "#{song.slug}: #{track.pattern_label} has no row count"
      end
      track.row = 0
      track.row_status = 0
      track.pattern_ptr = 1
      process_current_row(track, track_index)
      return
    end
  end

  def fetch_order_byte(index, track_index)
    @order_data.fetch(index) do
      raise "#{song.slug}: track #{track_index} order offset #{index} is out of range"
    end
  end

  def process_current_row(track, track_index)
    track.rows_processed += 1
    if (track.row & 7).zero?
      track.row_status = fetch_pattern_byte(track)
    end

    has_data = (track.row_status & 1) != 0
    track.row_status >>= 1
    return unless has_data

    row_bytes = 0
    loop do
      byte = fetch_pattern_byte(track)
      row_bytes += 1
      raise "#{song.slug}: #{track.pattern_label} row #{track.row} did not terminate" if row_bytes > 64

      case byte
      when 0x00..0xaf
        return
      when 0xb0..0xbf
        next
      when 0xc0..0xcf
        set_speed((byte & 0x0f) + 1, track_index, track.pattern_label, track.row)
      when 0xd0..0xdf
        next
      when 0xe0..0xef
        fetch_pattern_byte(track) unless (byte & 0x0f).zero?
      when 0xf0
        fetch_pattern_byte(track)
      when 0xf1
        next
      when 0xf2
        set_speed(fetch_pattern_byte(track), track_index, track.pattern_label, track.row)
      when 0xf3
        return
      when 0xf4..0xf6
        next
      when 0xf7
        fetch_pattern_byte(track)
      else
        raise "#{song.slug}: unsupported pattern command #{format('$%02X', byte)} " \
              "in #{track.pattern_label} row #{track.row}"
      end
    end
  end

  def fetch_pattern_byte(track)
    track.pattern_bytes.fetch(track.pattern_ptr) do
      raise "#{song.slug}: #{track.pattern_label} read past pattern data"
    end.tap do
      track.pattern_ptr += 1
    end
  end

  def set_speed(speed, track_index, pattern_label, row)
    raise "#{song.slug}: invalid speed #{speed} in #{pattern_label} row #{row}" unless speed.between?(1, 0xfe)

    old_speed = @tracks.fetch(track_index).speed
    @tracks.each { |track| track.speed = speed if track.active }
    speed_changes << {
      frame: @frame,
      track: track_index,
      row: row,
      pattern: pattern_label,
      old_speed: old_speed,
      new_speed: speed
    }
  end
end

def parse_options
  options = {
    format: "table",
    margin_seconds: 0
  }
  OptionParser.new do |parser|
    parser.banner = "usage: #{$PROGRAM_NAME} [options] <songs.mk> <generated-dir>"
    parser.on("--format=FORMAT", "table or manifest") { |value| options[:format] = value }
    parser.on("--margin-seconds=N", Integer) { |value| options[:margin_seconds] = value }
  end.parse!
  raise "usage: #{$PROGRAM_NAME} [options] <songs.mk> <generated-dir>" unless ARGV.length == 2
  raise "unsupported format #{options[:format].inspect}" unless %w[table manifest].include?(options[:format])

  options
end

def format_track_frames(track_frames)
  track_frames.map { |frames| frames.nil? ? "-" : frames.to_s }.join("/")
end

def print_table(results, margin_seconds)
  puts "slug                                      frames  seconds  tracks                 speed changes"
  puts "----                                      ------  -------  ------                 -------------"
  results.each do |result|
    seconds = result.seconds + margin_seconds
    printf(
      "%-40s %6d  %7d  %-21s %13d\n",
      result.song.slug,
      result.frames,
      seconds,
      format_track_frames(result.track_frames),
      result.speed_changes.length
    )
    result.warnings.each { |warning| warn "warning: #{result.song.slug}: #{warning}" }
  end

  puts
  puts "Suggested songs.mk entries:"
  print_manifest_entries(results, margin_seconds)
end

def print_manifest_entries(results, margin_seconds)
  results.each do |result|
    puts "#{result.song.slug}_DURATION_SECONDS := #{result.seconds + margin_seconds}"
  end
end

begin
  options = parse_options
  manifest_path, generated_dir = ARGV
  songs = CatalogLib.load_manifest(manifest_path)
  results = songs.map { |song| DurationAnalyzer.new(song, generated_dir).analyze }

  case options[:format]
  when "table"
    print_table(results, options[:margin_seconds])
  when "manifest"
    print_manifest_entries(results, options[:margin_seconds])
  end
rescue StandardError => e
  warn "error: #{e.message}"
  exit 1
end
