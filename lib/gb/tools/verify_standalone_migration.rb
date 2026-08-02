#!/usr/bin/env ruby
# frozen_string_literal: true

require "English"
require "fileutils"
require "open3"
require "pathname"
require "shellwords"

DEFAULT_PROJECTS = %w[
  music/super-mario-land
  music/ribbon
  music/eh-eh-nothing-else-i-can-say
  music/save-your-tears
  music/cyndi-lauper-medley
  music/a-few-knights-in-gerudo-valley
  music/dire-dire-docks
  music/koopas-road
  music/bob-omb-battlefield
  music/file-select
  music/there-must-be-an-angel
  music/welcome-to-paradise
  music/rockin-around-the-christmas-tree
  music/live-and-learn
  music/green-hill-zone
  music/ice-cap-zone
  music/take-on-me
  music/bubble-bop
  music/smooth-criminal
  music/severance
  music/rain-man
  music/super-mario-64-staff-roll
  music/what-im-made-of
  music/its-8bit-time
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

def capture(*args)
  stdout, status = Open3.capture2(*args)
  raise "command failed with status #{status.exitstatus}: #{args.shelljoin}" unless status.success?

  stdout
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

def tracked_files_at_ref(repo_root, ref, project)
  capture("git", "-C", repo_root.to_s, "ls-tree", "-r", "--name-only", ref, "--", project)
    .lines
    .map(&:chomp)
    .reject(&:empty?)
end

def tracked_files_in_worktree(repo_root, project)
  capture("git", "-C", repo_root.to_s, "ls-files", "--", project)
    .lines
    .map(&:chomp)
    .reject(&:empty?)
end

def copy_files_from_ref(repo_root, ref, files, project, destination)
  FileUtils.rm_rf(destination)
  FileUtils.mkdir_p(destination)
  prefix = "#{project}/"
  files.each do |rel|
    target = destination + rel.delete_prefix(prefix)
    FileUtils.mkdir_p(target.dirname)
    bytes = capture("git", "-C", repo_root.to_s, "show", "#{ref}:#{rel}")
    File.binwrite(target, bytes)
  end
end

def copy_files_from_worktree(repo_root, files, project, destination)
  FileUtils.rm_rf(destination)
  FileUtils.mkdir_p(destination)
  prefix = "#{project}/"
  files.each do |rel|
    target = destination + rel.delete_prefix(prefix)
    FileUtils.mkdir_p(target.dirname)
    FileUtils.cp(repo_root + rel, target)
  end
end

def ensure_python(build_root)
  return ENV.fetch("PYTHON") if ENV["PYTHON"] && !ENV["PYTHON"].empty?

  FileUtils.mkdir_p(build_root)
  venv = build_root + "venv"
  python = venv + "bin/python"
  run("python3", "-m", "venv", venv.to_s) unless python.file?

  import_ok = system(python.to_s, "-c", "import pyboy, numpy", out: File::NULL, err: File::NULL)
  run((venv + "bin/pip").to_s, "install", "-q", "pyboy", "numpy") unless import_ok
  python.to_s
end

def build_project(project_dir, shared_gb_lib: nil)
  makefile = project_dir + "Makefile"
  program = parse_program_name(makefile)
  args = ["make", "-B", "-C", project_dir.to_s]
  args << "SHARED_GB_LIB=#{shared_gb_lib}" if shared_gb_lib
  run(*args)

  rom = project_dir + "#{program}.gb"
  sym = project_dir + "#{program}.sym"
  raise "expected ROM was not built: #{rom}" unless rom.file?

  [rom, sym]
end

def compare_project(repo_root, project, reference_ref, build_root, python, verifier)
  slug = File.basename(project)
  old_dir = build_root + "old" + slug
  current_dir = build_root + "current" + slug
  shared_gb_lib = repo_root + "lib/gb"

  old_files = tracked_files_at_ref(repo_root, reference_ref, project)
  current_files = tracked_files_in_worktree(repo_root, project)
  raise "#{project}: no tracked files at #{reference_ref}" if old_files.empty?
  raise "#{project}: no tracked files in current worktree" if current_files.empty?

  puts "== #{project} =="
  copy_files_from_ref(repo_root, reference_ref, old_files, project, old_dir)
  copy_files_from_worktree(repo_root, current_files, project, current_dir)

  old_rom, old_sym = build_project(old_dir)
  current_rom, current_sym = build_project(current_dir, shared_gb_lib: shared_gb_lib)
  run(
    python,
    verifier.to_s,
    current_rom.to_s,
    old_rom.to_s,
    "--current-sym",
    current_sym.to_s,
    "--reference-sym",
    old_sym.to_s
  )
end

begin
  root = repo_root
  reference_ref = ENV.fetch("REFERENCE_REF", "origin/master")
  build_root = root + "build/verify-shared-engine"
  verifier = root + "lib/gb/tools/verify_audio.py"
  projects = ARGV.empty? ? DEFAULT_PROJECTS : ARGV
  python = ensure_python(build_root)

  projects.each do |project|
    compare_project(root, project, reference_ref, build_root, python, verifier)
  end
  puts "verified #{projects.length} standalone migration(s)"
rescue StandardError => e
  warn e.message
  exit 1
end
