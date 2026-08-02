#!/usr/bin/env ruby
# frozen_string_literal: true

if ARGV.length != 8
  warn "usage: #{$PROGRAM_NAME} <slug> <prefix> <bank> " \
       "<source-song.s> <source-main.s> <generated-song.inc> <output.s> " \
       "<source-assembler>"
  exit 64
end

def parse_db_values(line)
  line = line.sub(/;.*/, "")
  return [] unless line.match?(/\A\s*\.?db\s+/i)

  line.sub(/\A\s*\.?db\s+/i, "").split(",").map do |token|
    token = token.strip
    if token.start_with?("$")
      Integer(token[1..], 16)
    elsif token.match?(/\A0x[0-9a-f]+\z/i)
      Integer(token, 16)
    else
      Integer(token, 10)
    end
  end
end

def extract_wave_ram(path)
  values = []
  in_table = false

  File.readlines(path).each do |line|
    if !in_table
      in_table = true if line.match?(/\A\s*DefaultWavRam:/)
      next
    end

    parsed = parse_db_values(line)
    next if parsed.empty? && values.empty?
    break if parsed.empty?

    values.concat(parsed)
    break if values.length >= 16
  end

  raise "could not extract 16 DefaultWavRam bytes from #{path}" if values.length < 16

  values.take(16).each_slice(8).map do |row|
    "db " + row.map { |value| format("$%02x", value & 0xff) }.join(",")
  end.join("\n")
end

def normalize_source_line(line, source_assembler)
  case source_assembler
  when "rgbasm"
    line
  when "wla-gb"
    line.sub(/\A(\s*)\.(db|dw)\b/i, "\\1\\2")
  else
    raise "unsupported source assembler #{source_assembler.inspect}"
  end
end

slug, prefix, bank, source_path, main_path, generated_inc_path, output_path,
  source_assembler = ARGV
source = File.read(source_path)
wave_ram = extract_wave_ram(main_path)

labels = source.scan(/^([A-Za-z_][A-Za-z0-9_]*):/).flatten
rewrites = labels.to_h { |label| [label, "#{prefix}_#{label}"] }
rewrites["SONG_instrument_table"] = "#{prefix}_instrument_table"
rewrites["song_instrument_table"] = "#{prefix}_instrument_table"

rewritten_lines = source.lines.map do |line|
  next nil if line =~ /^\s*\.?include\s+"song\.inc"\s*$/i

  line = line.dup
  rewrites.keys.sort_by { |label| -label.length }.each do |label|
    line.gsub!(/\b#{Regexp.escape(label)}\b/, rewrites.fetch(label))
  end
  normalize_source_line(line, source_assembler)
end.compact

File.write(output_path, <<~ASM)
  EXPORT #{prefix}_song
  EXPORT #{prefix}_wave_ram
  EXPORT #{prefix}_instrument_table

  SECTION "Song #{slug}", ROMX, BANK[#{bank}]

  #{prefix}_wave_ram:
  ; Generated from #{main_path} DefaultWavRam.
  #{wave_ram}

  ; Generated from #{source_path}
  #{rewritten_lines.join}
  INCLUDE "#{generated_inc_path}"
ASM
