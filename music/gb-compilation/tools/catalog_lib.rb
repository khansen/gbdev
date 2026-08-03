# frozen_string_literal: true

Song = Struct.new(
  :slug,
  :source,
  :xm,
  :instruments,
  :song_asm,
  :main_asm,
  :source_assembler,
  :prefix,
  :bank,
  :title,
  :duration_seconds,
  :visualizer_bank,
  :visualizer_init,
  :visualizer_update,
  :visualizer_teardown,
  :diff_args,
  keyword_init: true
)

module CatalogLib
  module_function

  def load_manifest(path)
    vars = {}
    logical_manifest_lines(path).each do |line|
      next if line.empty?

      match = line.match(/\A([A-Za-z0-9_-]+)\s*(?::=|\?=|=)\s*(.*)\z/)
      raise "invalid manifest line: #{line}" unless match

      vars[match[1]] = match[2].strip
    end

    slugs = fetch(vars, "SONGS", "manifest").split(/\s+/)
    default_duration_seconds = Integer(vars.fetch("DEFAULT_SONG_DURATION_SECONDS", "90"), 10)
    slugs.map do |slug|
      duration_seconds = Integer(vars.fetch("#{slug}_DURATION_SECONDS", default_duration_seconds.to_s), 10)
      Song.new(
        slug: slug,
        source: fetch(vars, "#{slug}_SOURCE", slug),
        xm: fetch(vars, "#{slug}_XM", slug),
        instruments: fetch(vars, "#{slug}_INSTRUMENTS", slug),
        song_asm: fetch(vars, "#{slug}_SONG_ASM", slug),
        main_asm: fetch(vars, "#{slug}_MAIN_ASM", slug),
        source_assembler: vars.fetch("#{slug}_SOURCE_ASSEMBLER", "rgbasm"),
        prefix: fetch(vars, "#{slug}_PREFIX", slug),
        bank: Integer(fetch(vars, "#{slug}_BANK", slug), 10),
        title: fetch(vars, "#{slug}_TITLE", slug),
        duration_seconds: duration_seconds,
        visualizer_bank: Integer(vars.fetch("#{slug}_VISUALIZER_BANK", "0"), 10),
        visualizer_init: vars.fetch("#{slug}_VISUALIZER_INIT", "GenericVisualizerInit"),
        visualizer_update: vars.fetch("#{slug}_VISUALIZER_UPDATE", "GenericVisualizerUpdate"),
        visualizer_teardown: vars.fetch("#{slug}_VISUALIZER_TEARDOWN", "GenericVisualizerTeardown"),
        diff_args: vars.fetch("#{slug}_DIFF_ARGS", "")
      )
    end
  end

  def logical_manifest_lines(path)
    lines = []
    pending = +""
    File.readlines(path).each do |line|
      line = line.sub(/#.*/, "").rstrip
      next if line.empty? && pending.empty?

      if line.end_with?("\\")
        pending << line.delete_suffix("\\").rstrip << " "
        next
      end

      lines << (pending << line.strip).strip
      pending = +""
    end
    raise "unterminated manifest continuation: #{path}" unless pending.empty?

    lines
  end

  def fetch(vars, key, context)
    value = vars[key]
    raise "missing #{key} for #{context}" if value.nil? || value.empty?

    value
  end
end
