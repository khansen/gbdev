#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "standalone_verify_common"

module VerifyStandaloneMigration
  module_function

  def reference_ref
    ref = ENV["REFERENCE_REF"]
    return ref unless ref.nil? || ref.empty?

    raise <<~ERROR
      REFERENCE_REF is required.

      This verifier is the historical embedded-engine to shared-engine migration
      check. Set REFERENCE_REF to the pre-migration ref, for example:

        REFERENCE_REF=origin/master ruby lib/gb/tools/verify_standalone_migration.rb

      For future shared-engine refactors after this branch lands, use
      verify_sound_engine_refactor.rb instead.
    ERROR
  end

  def compare_project(repo_root, project, ref, build_root, python, verifier)
    slug = File.basename(project)
    old_dir = build_root + "old" + slug
    current_dir = build_root + "current" + slug
    shared_gb_lib = repo_root + "lib/gb"

    old_files = StandaloneVerifyCommon.tracked_files_at_ref(repo_root, ref, project)
    current_files = StandaloneVerifyCommon.tracked_files_in_worktree(repo_root, project)
    raise "#{project}: no tracked files at #{ref}" if old_files.empty?
    raise "#{project}: no tracked files in current worktree" if current_files.empty?

    puts "== #{project} =="
    StandaloneVerifyCommon.copy_files_from_ref(repo_root, ref, old_files, project, old_dir)
    StandaloneVerifyCommon.copy_files_from_worktree(repo_root, current_files, project, current_dir)

    old_rom, old_sym = StandaloneVerifyCommon.build_project(old_dir)
    current_rom, current_sym =
      StandaloneVerifyCommon.build_project(current_dir, shared_gb_lib: shared_gb_lib)
    StandaloneVerifyCommon.run(
      python,
      verifier.to_s,
      current_rom.to_s,
      old_rom.to_s,
      "--current-sym",
      current_sym.to_s,
      "--reference-sym",
      old_sym.to_s,
      *StandaloneVerifyCommon.audio_compare_args
    )
  end

  def run
    root = StandaloneVerifyCommon.repo_root
    ref = reference_ref
    build_root = root + "build/verify-shared-engine"
    verifier = root + "lib/gb/tools/verify_audio.py"
    projects = ARGV.empty? ? StandaloneVerifyCommon::RGBASM_STANDALONE_PROJECTS : ARGV
    python = StandaloneVerifyCommon.ensure_python(build_root)

    projects.each do |project|
      compare_project(root, project, ref, build_root, python, verifier)
    end
    puts "verified #{projects.length} standalone migration(s)"
  end
end

begin
  VerifyStandaloneMigration.run
rescue StandardError => e
  warn e.message
  exit 1
end
