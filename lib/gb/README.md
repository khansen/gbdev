# Shared Game Boy Sound Engine

This directory contains the shared RGBDS Game Boy sound engine used by the GB
music projects. It plays `xm2gb` song data and is intended to replace the older
embedded engine copies in standalone projects.

## Build Pattern

Add `lib/gb` to the RGBASM include path, assemble the engine as its own object,
and link it with the project objects:

```make
SHARED_GB_LIB := ../../lib/gb
SOUND_ENGINE_FLAGS ?= -D NO_SONG_SPEED_ADJUSTMENT

$(PROGRAM).gb: $(PROGRAM).o sound-engine.o
	rgblink -n $(PROGRAM).sym -m $(PROGRAM).map -o $@ $^
	rgbfix -v -p 0xFF $@

$(PROGRAM).o: main.s song.s song.inc hardware.inc $(SHARED_GB_LIB)/sound-engine.inc
	rgbasm -I $(SHARED_GB_LIB)/ -o $@ main.s

sound-engine.o: $(SHARED_GB_LIB)/sound-engine.s $(SHARED_GB_LIB)/sound-engine.inc hardware.inc
	rgbasm $(SOUND_ENGINE_FLAGS) -I . -I $(SHARED_GB_LIB)/ -o $@ $(SHARED_GB_LIB)/sound-engine.s
```

`hardware.inc` must be available on the include path. The engine references the
project's hardware register symbols from that file.

## Caller Contract

The caller provides:

- a song descriptor and instrument table generated for the `xm2gb` format
- wave RAM data; `DefaultWavRam` remains project-owned for now
- `hardware.inc` on the engine include path
- SFX data tables when `SOUND_ENGINE_ENABLE_SFX` is defined

Call `StartSong` with `HL` pointing at the song descriptor. Call `UpdateSound`
once per frame, normally during VBlank. If song data lives in a switchable ROM
bank, select that bank before `StartSong` and before every `UpdateSound`, since
the engine stores pointers into the active song data.

## Public API

- `StartSong`: initialize playback from `HL = song descriptor`
- `UpdateSound`: advance and render music once
- `GetMutedChannelsMask`: read the channel mute bits into the low nibble of `A`
- `SetMutedChannelsMask`: set channel mute bits from the low nibble of `A`
  while preserving other sound status bits

When `SOUND_ENGINE_ENABLE_PAUSE` is defined, the engine also exports:

- `PauseMusic`: set the paused bit so playback stops advancing
- `UnpauseMusic`: clear the paused bit
- `QueueSoundOutputMask`: apply a temporary output routing mask after the next
  `UpdateSound` render, without changing the preserved routing shadow
- `SilenceSoundOutput`: disconnect sound output while preserving the shadow
- `RestoreSoundOutput`: restore the preserved sound output routing

When `SOUND_ENGINE_ENABLE_STOP` is defined, the engine also exports:

- `StopSound`: stop all tracks

When `SOUND_ENGINE_ENABLE_SFX` is defined, the engine also exports:

- `PlayTrack0SFX`
- `PlayTrack1SFX`
- `PlayTrack2SFX`
- `PlayTrack3SFX`

When `SOUND_ENGINE_ENABLE_PATTERN_ROW_CALLBACK` is defined, the engine also
exports:

- `SetPatternRowCallback`: set a callback invoked while processing pattern rows

When `SOUND_ENGINE_ENABLE_PREROLL` is defined, the engine also exports:

- `hSoundPrerollRowsRemaining`: row countdown before pattern rows are rendered

## Status And Volume

The engine keeps internal sound status bits for mute, pause, and pending output
routing state:

- bit 0: channel 1 muted
- bit 1: channel 2 muted
- bit 2: channel 3 muted
- bit 3: channel 4 muted
- bit 4: paused, when `SOUND_ENGINE_ENABLE_PAUSE` is defined
- bit 5: pending temporary output mask, engine-owned internal state when
  `SOUND_ENGINE_ENABLE_PAUSE` is defined

Use `GetMutedChannelsMask` and `SetMutedChannelsMask` for channel mute changes.
The raw status byte is not exported.

`hMasterVol` controls master volume. The high nibble is used as the visible
volume value by current consumers.

The engine also exports shadow registers used by visualizers:

- `hShadowNR12`
- `hShadowNR22`
- `hShadowNR32`
- `hShadowNR42`

## Output Routing

Normal music routing is owned by the engine. `StartSong` routes all channels to
both outputs and updates the preserved routing shadow. `RestoreSoundOutput`
restores that preserved routing after a pause, and panning effects update the
preserved shadow while paused.

Use `QueueSoundOutputMask` only for temporary routing that must become audible
after the next `UpdateSound` render. The main use case is playing an SFX while
music is paused or otherwise disconnected:

1. call `SilenceSoundOutput`
2. start the SFX track
3. call `QueueSoundOutputMask` with the SFX routing mask
4. call `UpdateSound` on the normal frame cadence

The queued mask is applied after `UpdateSound` renders channel registers, so it
does not expose stale music register state for a frame before the SFX starts.
It does not update the preserved routing shadow; when the temporary SFX ends,
call `SilenceSoundOutput` to return to paused silence or `RestoreSoundOutput`
to resume the preserved music routing.

Do not use `QueueSoundOutputMask` for normal song start, resume, permanent
panning, or global routing setup.

## Compile-Time Options

Compile-time options are independent unless stated otherwise.

`NO_SONG_SPEED_ADJUSTMENT`

By default, `StartSong` follows the `games/d-pad-hero` convention and decrements
the descriptor speed value when initializing tracks. Define
`NO_SONG_SPEED_ADJUSTMENT` to use descriptor speeds as-is. Migrated standalone
music projects and the compilation ROM define this flag.

`SOUND_ENGINE_ENABLE_SFX`

SFX support is opt-in. Projects that do not define this flag do not pay the ROM
or RAM cost for SFX tracks. Projects that enable it must provide the SFX data
tables referenced by the engine.

`SOUND_ENGINE_ENABLE_PAUSE`

Pause support is opt-in. Projects that do not define this flag do not pay the
ROM cost for pause/unpause handling, paused render muting, or pause-safe output
routing, and do not pay the HRAM cost for the output-routing shadow/pending
mask.
Projects that enable it can call `PauseMusic`, `UnpauseMusic`,
`QueueSoundOutputMask`, `SilenceSoundOutput`, and `RestoreSoundOutput`.

`SOUND_ENGINE_ENABLE_STOP`

Hard-stop support is opt-in. Projects that do not define this flag do not pay
the ROM cost for `StopSound`. Projects that enable it can call `StopSound` to
mark every track stopped and silence the APU registers.

`SOUND_ENGINE_ENABLE_PATTERN_ROW_CALLBACK`

Pattern-row callback support is opt-in. Projects that do not define this flag
do not pay the ROM cost for the callback trampoline or the HRAM cost for the
callback pointer. Projects that enable it can call `SetPatternRowCallback` with
`HL` pointing at a callback routine. The callback receives the channel number in
`B` and must preserve `BC` and `DE`.

`SOUND_ENGINE_ENABLE_PREROLL`

Pre-roll support is opt-in. Projects that do not define this flag do not pay
the ROM cost for pre-roll row handling or the HRAM cost for the pre-roll
counter. Projects that enable it can write `hSoundPrerollRowsRemaining` with
the number of channel-0 rows to process before rendering pattern rows. This
feature is intended for D-Pad Hero-style gameplay synchronization.

## Compatibility Policy

The latest shared engine behavior is canonical. When migrating older projects,
adapt song data as needed rather than preserving older engine quirks in the
shared engine.

This migration is audio-equivalent, not byte-identical. Some standalone
`song.s` files intentionally contain data compensations so they sound the same
with the canonical shared engine.

### Envelope Timing Cleanup

Some migrated songs contain one-tick no-op volume envelope points such as
`db $00,$VV,$01` to compensate for older embedded engines that loaded a new
envelope point, then waited until the next tick before processing it. The
shared engine currently processes newly loaded envelope points immediately.

These compensation points are acceptable for the shared-engine migration, but
they are not the desired long-term authoring style: they make hand-edited
envelopes harder to read. Do not add a per-song runtime switch for this.
Instead, treat envelope timing as a follow-up reconciliation task: decide the
intended engine/tooling semantics, update affected song data or tooling in one
coherent pass, and remove redundant compensation points where possible.

## Verification

Migrated standalone projects should:

- build successfully
- compare audio-equivalent to their pre-migration standalone ROMs
- pass `ruby lib/gb/tools/verify_sound_engine_flags.rb` after compile-time
  option changes
- receive a manual listen when aggregate audio comparison reports a meaningful
  difference

Use the historical migration verifier only when comparing this branch to a
pre-shared-engine baseline:

```sh
REFERENCE_REF=origin/master ruby lib/gb/tools/verify_standalone_migration.rb
```

`REFERENCE_REF` is required so the command cannot silently become stale after
the shared engine has been merged.

For future pure refactors or bug fixes to the shared engine, compare the current
worktree against a baseline that already contains `lib/gb`:

```sh
BASELINE_REF=origin/master ruby lib/gb/tools/verify_sound_engine_refactor.rb
```

`BASELINE_REF` is required. The refactor verifier builds each standalone
project from `BASELINE_REF` with that ref's `lib/gb`, then builds the current
worktree with the current `lib/gb`. Pass project paths as arguments to limit
the sweep, for example `music/super-mario-land music/ribbon`.

Both verifiers use `verify_audio.py` to compare aggregate APU behavior. They
compare register-change rates, distinct state counts, distinct frequency counts,
track speeds when symbols are available, and audio RMS ratio. They do not
require frame-exact register equality. Use `AUDIO_COMPARE_ARGS` to pass custom
`verify_audio.py` options when investigating expected audio changes.
