#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "standalone_verify_common"

module VerifySoundEngineRefactor
  module_function

  def baseline_ref
    ref = ENV["BASELINE_REF"]
    return ref unless ref.nil? || ref.empty?

    raise <<~ERROR
      BASELINE_REF is required.

      This verifier compares two shared-engine revisions. Set BASELINE_REF to a
      ref that already contains lib/gb, for example:

        BASELINE_REF=origin/master ruby lib/gb/tools/verify_sound_engine_refactor.rb

      Use verify_standalone_migration.rb for the historical embedded-engine to
      shared-engine migration check.
    ERROR
  end

  def copy_baseline_shared_lib(repo_root, ref, build_root)
    unless StandaloneVerifyCommon.ref_has_path?(repo_root, ref, "lib/gb/sound-engine.s")
      raise <<~ERROR
        #{ref} does not contain lib/gb/sound-engine.s.

        verify_sound_engine_refactor.rb compares two shared-engine revisions.
        Use BASELINE_REF to point at a ref that already contains lib/gb, or use
        verify_standalone_migration.rb for the historical embedded-engine
        migration check.
      ERROR
    end

    lib_files = StandaloneVerifyCommon.tracked_files_at_ref(repo_root, ref, "lib/gb")
    destination = build_root + "baseline-lib" + "gb"
    StandaloneVerifyCommon.copy_files_from_ref(repo_root, ref, lib_files, "lib/gb", destination)
    destination
  end

  def compare_project(repo_root, project, ref, build_root, python, verifier, baseline_lib)
    slug = File.basename(project)
    baseline_dir = build_root + "baseline" + slug
    current_dir = build_root + "current" + slug
    current_lib = repo_root + "lib/gb"

    baseline_files = StandaloneVerifyCommon.tracked_files_at_ref(repo_root, ref, project)
    current_files = StandaloneVerifyCommon.tracked_files_in_worktree(repo_root, project)
    raise "#{project}: no tracked files at #{ref}" if baseline_files.empty?
    raise "#{project}: no tracked files in current worktree" if current_files.empty?

    puts "== #{project} =="
    StandaloneVerifyCommon.copy_files_from_ref(repo_root, ref, baseline_files, project, baseline_dir)
    StandaloneVerifyCommon.copy_files_from_worktree(repo_root, current_files, project, current_dir)

    baseline_rom, baseline_sym =
      StandaloneVerifyCommon.build_project(baseline_dir, shared_gb_lib: baseline_lib)
    current_rom, current_sym =
      StandaloneVerifyCommon.build_project(current_dir, shared_gb_lib: current_lib)
    StandaloneVerifyCommon.run(
      python,
      verifier.to_s,
      current_rom.to_s,
      baseline_rom.to_s,
      "--current-sym",
      current_sym.to_s,
      "--reference-sym",
      baseline_sym.to_s,
      *StandaloneVerifyCommon.audio_compare_args
    )
  end

  def run
    root = StandaloneVerifyCommon.repo_root
    ref = baseline_ref
    build_root = root + "build/verify-sound-engine-refactor"
    verifier = root + "lib/gb/tools/verify_audio.py"
    projects = ARGV.empty? ? StandaloneVerifyCommon::RGBASM_STANDALONE_PROJECTS : ARGV
    python = StandaloneVerifyCommon.ensure_python(build_root)
    baseline_lib = copy_baseline_shared_lib(root, ref, build_root)

    projects.each do |project|
      compare_project(root, project, ref, build_root, python, verifier, baseline_lib)
    end
    puts "verified #{projects.length} shared-engine refactor(s)"
  end
end

begin
  VerifySoundEngineRefactor.run
rescue StandardError => e
  warn e.message
  exit 1
end
