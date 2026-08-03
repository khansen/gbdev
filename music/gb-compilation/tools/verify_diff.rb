#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "English"
require "fileutils"
require "open3"
require "pathname"
require "shellwords"
require_relative "catalog_lib"

if ARGV.length < 4
  warn "usage: #{$PROGRAM_NAME} <manifest.mk> <compilation.gb> " \
       "<compilation.sym> <python> [song-slug ...]"
  exit 64
end

manifest_arg, rom_arg, sym_arg, python_arg, *requested_slugs = ARGV
project_root = Pathname.new(File.expand_path("..", __dir__))
verifier_path = project_root + "tools/verify_playback.py"

def project_path(project_root, path)
  pathname = Pathname.new(path)
  pathname.absolute? ? pathname : project_root + pathname
end

def git_repo_root(project_root)
  stdout, status = Open3.capture2(
    "git",
    "-C",
    project_root.to_s,
    "rev-parse",
    "--show-toplevel"
  )
  raise "not inside a git repository" unless status.success?

  Pathname.new(stdout.strip)
end

def repo_relative(repo_root, path)
  Pathname.new(path).expand_path.relative_path_from(repo_root).to_s
end

def tracked_files_under(repo_root, path)
  rel = repo_relative(repo_root, path)
  stdout, status = Open3.capture2(
    "git",
    "-C",
    repo_root.to_s,
    "ls-files",
    "--",
    rel
  )
  raise "git ls-files failed for #{path}" unless status.success?

  stdout.lines.map(&:chomp).reject(&:empty?)
end

def digest_tracked_files(repo_root, tracked_files)
  tracked_files.to_h do |rel|
    path = repo_root + rel
    digest = File.file?(path) ? Digest::SHA256.file(path).hexdigest : nil
    [rel, digest]
  end
end

def changed_files(before, after)
  (before.keys | after.keys).select { |rel| before[rel] != after[rel] }
end

def parse_program_name(makefile)
  File.readlines(makefile).each do |line|
    line = line.sub(/#.*/, "").strip
    next if line.empty?

    match = line.match(/\APROGRAM\s*[:?]?=\s*(\S+)\s*\z/)
    return match[1] if match
  end

  raise "could not find PROGRAM assignment in #{makefile}"
end

def run(*args)
  puts "+ #{args.shelljoin}"
  ok = system(*args)
  raise "command failed with status #{$CHILD_STATUS.exitstatus}: #{args.shelljoin}" unless ok
end

def capture(*args)
  puts "+ #{args.shelljoin}"
  stdout, status = Open3.capture2(*args)
  raise "command failed with status #{status.exitstatus}: #{args.shelljoin}" unless status.success?

  stdout
end

def copy_source_tree(repo_root, tracked_files, source_dir, destination_dir)
  FileUtils.rm_rf(destination_dir)
  FileUtils.mkdir_p(destination_dir)

  source_rel = repo_relative(repo_root, source_dir)
  source_prefix = "#{source_rel}/"
  tracked_files.each do |rel|
    next unless rel.start_with?(source_prefix)

    target = destination_dir + rel.delete_prefix(source_prefix)
    FileUtils.mkdir_p(target.dirname)
    FileUtils.cp(repo_root + rel, target)
  end
end

def rgbds_song_inc_to_wla(source)
  source.lines.map do |line|
    line.sub(/\A(\s*)(db|dw)\b/i, "\\1.\\2")
  end.join
end

def prepare_wla_gb_song_inc(source_dir, song)
  generated = capture(
    "xm2gb",
    "--instruments-map=#{source_dir + song.instruments}",
    (source_dir + song.xm).to_s
  )
  File.write(source_dir + "song.inc", rgbds_song_inc_to_wla(generated))
end

manifest_path = project_path(project_root, manifest_arg)
rom_path = project_path(project_root, rom_arg)
sym_path = project_path(project_root, sym_arg)
python_path = project_path(project_root, python_arg)
shared_gb_lib = (project_root + "../../lib/gb").expand_path
standalone_build_root = project_root + "build/verify-standalone"
begin
  repo_root = git_repo_root(project_root)
  songs = CatalogLib.load_manifest(manifest_path)

  selected_songs =
    if requested_slugs.empty?
      songs.each_with_index.to_a
    else
      requested_slugs.map do |slug|
        index = songs.index { |song| song.slug == slug }
        raise "unknown song slug #{slug.inspect}" if index.nil?

        [songs[index], index]
      end
    end

  selected_songs.each do |song, index|
    source_dir = project_path(project_root, song.source)
    makefile = source_dir + "Makefile"
    program = parse_program_name(makefile)
    verify_source_dir = standalone_build_root + song.slug
    standalone_rom = verify_source_dir + "#{program}.gb"
    tracked_files = tracked_files_under(repo_root, source_dir)
    before = digest_tracked_files(repo_root, tracked_files)

    puts "== #{song.slug} =="
    copy_source_tree(repo_root, tracked_files, source_dir, verify_source_dir)
    make_args = ["make", "-C", verify_source_dir.to_s, "SHARED_GB_LIB=#{shared_gb_lib}"]
    if song.source_assembler == "wla-gb"
      prepare_wla_gb_song_inc(verify_source_dir, song)
    else
      make_args.insert(1, "-B")
    end
    run(*make_args)

    after = digest_tracked_files(repo_root, tracked_files)
    modified = changed_files(before, after)
    unless modified.empty?
      raise "#{song.slug}: standalone build modified tracked source files:\n  " \
            "#{modified.join("\n  ")}"
    end
    raise "#{song.slug}: standalone ROM not found: #{standalone_rom}" unless standalone_rom.file?

    diff_command = [
      python_path.to_s,
      verifier_path.to_s,
      rom_path.to_s,
      "--sym",
      sym_path.to_s,
      "--diff",
      standalone_rom.to_s,
      "--diff-song-index",
      index.to_s,
      "--diff-only",
      "--diff-frames",
      "1800",
      *Shellwords.split(song.diff_args)
    ]
    run(*diff_command)
  end

  puts "verified #{selected_songs.length} standalone diff(s)"
rescue StandardError => e
  warn e.message
  exit 1
end
