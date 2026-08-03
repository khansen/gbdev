#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "catalog_lib"

unless [3, 4].include?(ARGV.length)
  warn "usage: #{$PROGRAM_NAME} <manifest.mk> <songs-per-page> <output.inc> [duration-override-seconds]"
  exit 64
end

manifest_path, songs_per_page_text, output_path, duration_override_text = ARGV
songs = CatalogLib.load_manifest(manifest_path)
songs_per_page = Integer(songs_per_page_text, exception: false)
duration_override = if duration_override_text && !duration_override_text.empty?
                      Integer(duration_override_text, exception: false)
                    end

max_title_length = 16
max_songs_per_page = 12

if songs_per_page.nil? || songs_per_page < 1 || songs_per_page > max_songs_per_page
  warn "songs per page must be between 1 and #{max_songs_per_page}: #{songs_per_page_text.inspect}"
  exit 1
end

page_count = (songs.length + songs_per_page - 1) / songs_per_page

songs.each do |song|
  if song.title.length > max_title_length
    warn "#{song.slug} title is too long for the initial menu: #{song.title.inspect}"
    exit 1
  end

  duration_seconds = duration_override || song.duration_seconds
  duration_frames = duration_seconds * 60
  if duration_frames < 1 || duration_frames > 65_535
    warn "#{song.slug} duration must convert to 1..65535 frames: #{duration_seconds.inspect}"
    exit 1
  end
end

lines = []
lines << "; Generated from #{manifest_path}; do not edit."
lines << "def SONG_COUNT equ #{songs.length}"
lines << "def SONG_CATALOG_ENTRY_SIZE equ 14"
lines << "def SONGS_PER_PAGE equ #{songs_per_page}"
lines << "def SONG_PAGE_COUNT equ #{page_count}"
lines << ""
lines << "SongCatalog:"
songs.each do |song|
  duration_seconds = duration_override || song.duration_seconds
  lines << "    db #{song.bank}"
  lines << "    dw #{duration_seconds * 60}"
  lines << "    dw #{song.prefix}_song"
  lines << "    dw #{song.prefix}_wave_ram"
  lines << "    db #{song.visualizer_bank}"
  lines << "    dw #{song.visualizer_init}"
  lines << "    dw #{song.visualizer_update}"
  lines << "    dw #{song.visualizer_teardown}"
end
lines << "SongCatalogEnd:"
lines << ""
lines << "MenuConfig:"
lines << "    db SONGS_PER_PAGE"
lines << "    db SONG_PAGE_COUNT"
lines << ""
lines << "SongTitlePointers:"
songs.each do |song|
  lines << "    dw SongTitle_#{song.prefix}"
end
lines << ""
songs.each do |song|
  lines << "SongTitle_#{song.prefix}:"
  lines << format('    db %d, "%s"', song.title.length, song.title)
end
lines << ""
lines << "PageIndicatorPointers:"
page_count.times do |index|
  lines << "    dw PageIndicator_#{index}"
end
lines << ""
page_count.times do |index|
  text = "PAGE #{index + 1} OF #{page_count}"
  lines << "PageIndicator_#{index}:"
  lines << format('    db %d, "%s"', text.length, text)
end
lines << ""

content = lines.join("\n") + "\n"
if File.exist?(output_path) && File.binread(output_path) == content
  exit 0
end

File.write(output_path, content)
