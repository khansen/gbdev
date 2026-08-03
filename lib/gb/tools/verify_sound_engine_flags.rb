#!/usr/bin/env ruby
# frozen_string_literal: true

require "English"
require "fileutils"
require "open3"
require "pathname"
require "shellwords"

FLAGS = %w[
  NO_SONG_SPEED_ADJUSTMENT
  SOUND_ENGINE_ENABLE_SFX
  SOUND_ENGINE_ENABLE_PAUSE
  SOUND_ENGINE_ENABLE_STOP
  SOUND_ENGINE_ENABLE_PATTERN_ROW_CALLBACK
  SOUND_ENGINE_ENABLE_PREROLL
].freeze

def repo_root
  stdout, status = Open3.capture2("git", "rev-parse", "--show-toplevel")
  raise "not inside a git repository" unless status.success?

  Pathname.new(stdout.strip)
end

def run(*args)
  puts "+ #{args.shelljoin}"
  ok = system(*args)
  raise "command failed with status #{$CHILD_STATUS.exitstatus}: #{args.shelljoin}" unless ok
end

def write_support_file(path)
  path.write(<<~ASM)
    SECTION "Sound Engine Flag Verify SFX Data", ROM0

    EXPORT SFXPatternTable
    EXPORT SFXInstrumentTable

    SFXPatternTable:
        dw .empty_pattern

    .empty_pattern:
        db 1, 0

    SFXInstrumentTable:
        ds 8
  ASM
end

begin
  root = repo_root
  build_root = root + "build/verify-sound-engine-flags"
  FileUtils.rm_rf(build_root)
  FileUtils.mkdir_p(build_root)

  support_s = build_root + "support.s"
  support_o = build_root + "support.o"
  write_support_file(support_s)
  run("rgbasm", "-o", support_o.to_s, support_s.to_s)

  combo_count = 1 << FLAGS.length
  combo_count.times do |mask|
    enabled = FLAGS.each_with_index.map do |flag, index|
      (mask & (1 << index)) != 0 ? flag : nil
    end.compact
    suffix = enabled.empty? ? "none" : enabled.join("-")
    object = build_root + "sound-engine-#{mask.to_s(16).rjust(2, "0")}-#{suffix}.o"
    rom = build_root + "sound-engine-#{mask.to_s(16).rjust(2, "0")}-#{suffix}.gb"
    args = ["rgbasm"]
    enabled.each do |flag|
      args << "-D" << flag
    end
    args += [
      "-I",
      (root + "music/super-mario-land").to_s,
      "-I",
      (root + "lib/gb").to_s,
      "-o",
      object.to_s,
      (root + "lib/gb/sound-engine.s").to_s
    ]
    run(*args)
    run("rgblink", "-o", rom.to_s, object.to_s, support_o.to_s)
  end

  puts "verified #{combo_count} sound-engine flag combination(s)"
rescue StandardError => e
  warn e.message
  exit 1
end
