#!/usr/bin/env ruby
# frozen_string_literal: true

if ARGV.length != 1
  warn "usage: #{$PROGRAM_NAME} <map-file>"
  exit 64
end

map_path = ARGV.fetch(0)
current_romx_bank = nil
songs = []

File.readlines(map_path).each do |line|
  if (match = line.match(/\A\s*(ROM0|ROMX|WRAM0|HRAM):\s+(\d+) bytes used \/ (\d+) free(?: in (\d+) banks)?/))
    total = match[2].to_i + match[3].to_i
    bank_count = match[4] ? " in #{match[4]} bank(s)" : ""
    puts format("%-5s %5d / %5d bytes used%s", match[1], match[2].to_i, total, bank_count)
    next
  end

  if (match = line.match(/\AROMX bank #(\d+):/))
    current_romx_bank = match[1].to_i
    next
  end

  match = line.match(/SECTION: \$[0-9a-f]+-\$[0-9a-f]+ \(\$([0-9a-f]+) bytes\) \["Song (.+)"\]/i)
  next unless match && current_romx_bank

  songs << [current_romx_bank, match[2], match[1].to_i(16)]
end

unless songs.empty?
  puts
  puts "Song banks:"
  songs.each do |bank, slug, bytes|
    puts format("  bank %3d  %-32s %5d / 16384 bytes (%5.1f%%)", bank, slug, bytes, bytes * 100.0 / 16_384)
  end
end
