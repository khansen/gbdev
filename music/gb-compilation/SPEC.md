# Game Boy Music Compilation Specification

## Goal

Create a Game Boy ROM that collects selected tracked music projects from `music/`
into one menu-driven compilation cartridge.

The first implementation started as a two-song proof of concept. The current
version expands that proof to a small multi-song edition while keeping the
project structured so later editions can add more songs by updating a manifest,
not by duplicating the whole program.

## Confirmed Requirements

- Source projects live under `music/`.
- Eligible source projects are identified from tracked `Makefile` files that
  contain `rgbasm`, plus explicitly selected tracked WLA-GB projects that use
  the same song data format.
- Files not added to git are ignored for source project discovery.
- The compilation project must not track copied song assets that can be derived
  from the standalone source projects.
- Song source assets are consumed directly from the standalone projects and
  regenerated under `build/generated/` when their source files change.
- The ROM has a root menu with `ALBUM`, `SHUFFLE`, and `SINGLES` playback
  modes.
- `SINGLES` opens the song list UI.
- Song lists that do not fit on one screen use page switching, not smooth
  scrolling.
- Selecting a song in `SINGLES`, or choosing `ALBUM` or `SHUFFLE`, enters Play
  Mode.
- `ALBUM` plays songs in manifest order and loops back to the beginning.
- The manifest song order is chronological by each selected project's
  `SNOWBRO NNN` header string. The same order is used for `ALBUM`,
  `SINGLES`, and Previous/Next Song.
- `SHUFFLE` plays songs in a pseudo-random shuffled order and avoids repeating
  the same song until the current shuffle bag is exhausted.
- Play Mode owns the full background nametable so future per-song
  visualizations can use the whole screen.
- Play Mode supports toggling individual sound channels on and off.
- Play Mode supports pausing with START.
- Pausing opens a menu with Resume, Restart, Previous Song, Next Song, and Quit.
- The pause menu is rendered with the Game Boy window feature so it can overlay
  the Play Mode screen without destroying the visualization nametable.
- Pausing must silence audio.
- Resume continues the song, Restart starts the current song from the beginning,
  Previous Song and Next Song immediately start the adjacent song for the active
  playback mode, and Quit exits to the root menu for `ALBUM`/`SHUFFLE` or the
  song list for `SINGLES`.
- `ALBUM` and `SHUFFLE` auto-advance by per-song duration metadata from
  `songs.mk`; version 1 does not infer song endings from order-loop wraparound.
- Version 1 uses the generic channel-indicator visualization shared by many
  standalone projects. Custom per-song visualizations come later.
- Version 1 should not copy per-song visualization assets. The priority is
  proving music playback first, then scaling toward ten or more songs.
- Bank switching is required. The design must assume the combined song data and
  future per-song visualization code/data will exceed 32 KiB.
- Version 1 uses an MBC5 ROM-only cartridge configuration.
- One shared music engine implementation should be used for all songs and should
  stay in the fixed bank if feasible.
- The ROM must work on DMG hardware. CGB enhancements may be added later only if
  they fall back cleanly on DMG.

## Tracked Candidate Projects

The following tracked projects were found with:

```sh
git grep -l rgbasm -- 'music/**/Makefile'
```

- `a-few-knights-in-gerudo-valley`
- `bob-omb-battlefield`
- `bubble-bop`
- `cyndi-lauper-medley`
- `dire-dire-docks`
- `eh-eh-nothing-else-i-can-say`
- `file-select`
- `green-hill-zone`
- `ice-cap-zone`
- `its-8bit-time`
- `koopas-road`
- `live-and-learn`
- `rain-man`
- `ribbon`
- `rockin-around-the-christmas-tree`
- `save-your-tears`
- `severance`
- `smooth-criminal`
- `super-mario-64-staff-roll`
- `super-mario-land`
- `take-on-me`
- `there-must-be-an-angel`
- `welcome-to-paradise`
- `what-im-made-of`

The following tracked WLA-GB-compatible project is also selected explicitly:

- `risa-furanku-420`

Non-`rgbasm` Game Boy projects are not part of the automatic discovery set, but
may be added explicitly when their source assets are tracked and their
hand-authored song wrapper syntax is supported by the generator. `risa-furanku-420`
is included this way with `SOURCE_ASSEMBLER := wla-gb`. SMS/GG projects, GBA
projects, and untracked directories remain excluded from this Game Boy
compilation unless a future manifest entry and converter path intentionally
support them.

## User-Facing Design

### Root Menu

- The first screen is a root menu, not a splash screen.
- The root menu contents should be vertically centered on the screen.
- The root menu has three choices:
  - `ALBUM`: play songs in manifest order, then loop back to the first song
  - `SHUFFLE`: play songs in pseudo-random shuffled order
  - `SINGLES`: open the paged manual song list
- UP and DOWN move the cursor.
- A or START chooses the highlighted mode.
- Cursor movement should play the D-Pad Hero menu-change sound effect.
- A and START confirmation should not play a sound effect.
- Choosing `ALBUM` starts the first song in album order and enters Play Mode.
- Choosing `SHUFFLE` initializes a shuffle bag, chooses the first shuffled song,
  and enters Play Mode.
- Choosing `SINGLES` opens the paged song list with the first song selected.
  Selection from `ALBUM` or `SHUFFLE` must not bleed into `SINGLES`.

### Singles Song List

- The song list is the manual-selection screen for `SINGLES` mode.
- The list shows the available songs and a cursor on the selected song.
- UP and DOWN move the cursor.
- A or START starts the selected song and enters Play Mode.
- B returns to the root menu so the user can choose another playback mode
  without resetting the Game Boy.
- The current catalog exceeds the default visible-row capacity, so the song list
  uses page switching when the list exceeds the available song rows.
- The menu should show enough text to identify each song without relying on the
  source directory name alone.
- The menu should not spend rows on obvious instruction text such as
  `A OR START PLAY`, `UP DOWN SELECT`, or stopped-status text. Reserve the
  visible rows for song titles plus a compact title/page indicator.

### Paged Song Selection

The long-list menu should switch between complete pages instead of smooth
scrolling one row at a time.

- Keep the selected song as an absolute catalog index.
- Keep the current page explicitly, or derive it from the selected song index
  and the configured rows per page.
- The rows per page should be a named constant, chosen from the final menu
  layout rather than hard-coded throughout the input and drawing code.
- When DOWN moves past the last visible song on a page, select the first song on
  the next page and redraw the full menu page.
- When UP moves before the first visible song on a page, select the last song on
  the previous page and redraw the full menu page.
- LEFT and RIGHT should switch to the previous or next menu page and redraw the
  full menu page. Preserve the selected row on the destination page when that
  row exists; clamp to the last song on a short final page. LEFT on the first
  page wraps to the last page, and RIGHT on the last page wraps to page 0.
- Moving past the last catalog song should wrap to the first song and page 0.
- Moving before the first catalog song should wrap to the last song and its
  page.
- Show a compact page indicator, such as `PAGE 1 OF 2`, when there is more than
  one page. The text must use glyphs present in the current menu font.
- Page redraws should use the safe LCD-off transition path, not incremental
  VBlank tilemap updates. A page can contain 10 or more song rows, and clearing
  and rewriting that many rows is simpler and less fragile with the LCD off.
- The default layout should use the full available song-list capacity. The
  current menu reserves rows 4 through 15 for song titles, so the default is
  `SONGS_PER_PAGE=12`.
- `make verify` should also build a separate paging fixture with
  `SONGS_PER_PAGE=1` so page transitions are exercised without changing the
  production default.
- Returning from Play Mode should redraw the page containing the previously
  selected song, with that song still selected, when the active playback mode is
  `SINGLES`.
- The build should allow more songs than one page can display; it should fail
  only when a title cannot fit in one menu row or a catalog/bank-size constraint
  is violated.

### Automatic Playback Modes

`ALBUM` and `SHUFFLE` are automatic playback modes intended for unattended or
visitor-facing convention use. They should not show the song list between songs.

- `ALBUM` order is the `SONGS` order from `songs.mk`. Keep that manifest order
  chronological by each selected project's `SNOWBRO NNN` header string.
- The `SINGLES` song list should use the same chronological `SONGS` order so
  the menu, `SONG X OF Y`, and Previous/Next Song behavior all agree.
- `SHUFFLE` should use a shuffle bag: fill a WRAM array with each selected song
  index once, shuffle it with a small PRNG, and consume entries until the bag is
  exhausted. Refill and reshuffle after exhaustion.
- Keep a shuffle position cursor into the current bag. `NEXT SONG` advances the
  cursor and refills the bag when it moves past the last entry. `PREV SONG`
  moves the cursor backward when possible; at the first entry of a bag, wrap to
  the last entry of the current bag rather than reshuffling. This gives the
  pause-menu Previous Song command deterministic behavior without needing a
  longer cross-bag history.
- The shuffle PRNG can be seeded from input timing and `DIV`/timer state. The
  exact order does not need to be reproducible.
- Avoid immediate repeats across shuffle-bag boundaries when practical.
- A song in `ALBUM` or `SHUFFLE` advances when its manifest duration expires.
  Do not try to infer an end-of-song event from pattern/order wraparound for
  version 1. The song conversion output currently loops by order commands, and
  wrap detection through pattern-row callbacks would be fragile.
- Auto-advance should transition directly from the current Play Mode screen to
  the next Play Mode screen. It should not show the root menu or song list
  between songs.
- Use the same safe LCD-off Play Mode reinitialization path as Restart when the
  next song requires a full-screen nametable redraw.

### Play Mode

- Playback starts immediately after selecting a song or automatic playback mode.
- The song list is not part of Play Mode.
- Entering Play Mode should transition to a full-screen Play Mode nametable.
- For version 1, the Play Mode nametable shows the selected song title near the
  top and the generic four-channel indicator strip used by many standalone
  projects.
- The generic indicator implementation lives in `ROM0`, uses the shared
  engine's `hShadowNR12`, `hShadowNR22`, `hShadowNR32`, `hShadowNR42`, and
  `GetMutedChannelsMask` values, and draws the shared `ball.bin` tiles.
- The generic indicator labels each channel slot with 2x2 background-tile
  button icons from `src/ui/udlr.bin`, in UP, DOWN, LEFT, RIGHT order.
- Play Mode shows a shared `MASTER VOL: N` readout below the visualization,
  where `N` is the upper nibble of the shared engine's `hMasterVol` value in
  hexadecimal (`0` through `F`).
- In `ALBUM` mode only, Play Mode shows `SONG X OF Y` at the bottom of the
  background nametable, where `X` is the 1-based album-order song index and
  `Y` is the total song count. The display may assume `Y <= 99`.
- The generic indicator must use the same VRAM-buffer update path as the
  standalone projects that define `DrawChannelIndicators`: `DrawChannelIndicators`
  emits row commands with `BeginVramString`/`EndVramString`, and the VBlank
  handler flushes those commands with `FlushVramBuffer` early in the next
  VBlank.
- Muted channels show the 2x2 background-tile mute icon from
  `src/ui/mute.bin`, so a manually muted channel can be distinguished from an
  unmuted channel that is currently silent.
- Future per-song visualizations can replace or extend the generic indicators
  and use the whole background nametable.
- Per-song visualizations use catalog-provided lifecycle hooks: `init`,
  `update`, and `teardown`. Version 1 assigns every song to the ROM0 generic
  visualizer: no-op `init`, generic channel-indicator `update`, and no-op
  `teardown`.

### Pause Window

The pause menu should use the Game Boy window layer instead of writing over the
Play Mode background.

- Keep the Play Mode background nametable intact while paused.
- Store window X/Y positions in HRAM shadow variables, following the
  `music/severance/main.s` pattern with `hWindowX` and `hWindowY` synced to
  `rWX` and `rWY` during VBlank.
- Use `WX = 7` for a left-aligned window.
- Hide the window by moving it off-screen, for example `WY = 144`.
- Show the pause window near the bottom of the screen, leaving the song title
  and upper visualization area visible. A five-item pause menu plus heading
  needs six rows; place the window one tile row above the bottom of the screen
  so there is a row of breathing room below it.
- Indent pause-window contents by two tiles so the heading aligns with
  `NOW PLAYING` on the Play Mode background.
- Render `RESUME`, `RESTART`, `PREV SONG`, `NEXT SONG`, and `QUIT` into the
  window tilemap, preferably `$9C00` with `LCDC_WIN9C00`, so the pause menu and
  Play Mode background have separate tilemaps.
- While paused, stop visualization updates or put the active visualizer into a
  paused state.
- On Resume, hide the window, restore sound output, and continue the song and
  visualization without reinitializing them.
- On Restart, hide the window, reinitialize the current song and visualizer, and
  start playback from the beginning.
- On Previous Song or Next Song, hide the window, stop the current song, choose
  the adjacent song according to the active playback mode, and re-enter Play
  Mode without showing the root menu or song list.
- On Quit, stop the song, silence audio, and hide the window. In `ALBUM` and
  `SHUFFLE`, rebuild the root menu background nametable and return to root menu
  controls. In `SINGLES`, rebuild the song-list background nametable for the
  current page/selection and return to song-list controls without resetting the
  selected song.

### LCD Transitions

Full-screen menu/play-mode redraws must use the safe `TurnOffLCD` pattern from
`games/d-pad-hero/main.s`.

- Keep an `hShadowLCDC` HRAM value for the desired LCDC state.
- The VBlank handler must copy `hShadowLCDC` to `rLCDC`.
- `TurnOffLCD` must clear `LCDCF_ON` in `hShadowLCDC` only.
- `TurnOffLCD` must not write directly to `rLCDC`; the actual LCD-off hardware
  write must happen from VBlank.
- Code that needs to rewrite the whole background nametable should call
  `TurnOffLCD`, then advance `hMainState` to an init/redraw handler. The next
  VBlank applies the shadowed LCD-off value to `rLCDC` before dispatching that
  handler, matching the `games/d-pad-hero/main.s` `GoMainFunction` pattern.
- Turning the LCD on may write `hShadowLCDC` and `rLCDC` immediately, following
  the D-Pad Hero `TurnOnLCD` pattern, because enabling LCDC is not restricted to
  VBlank.
- Do not use ad hoc `ldh [rLCDC], a` writes for LCD-off transitions.

### VRAM Updates

Do not invent new low-level drawing primitives for LCD-on dynamic tilemap
updates. Use the canonical VRAM buffer mechanism from the standalone GB music
projects:

- build commands in `wVramBuffer`
- append commands with `BeginVramString`
- terminate and commit the pending offset with `EndVramString`
- flush pending commands early from the VBlank handler with `FlushVramBuffer`,
  before `UpdateSound` or main-state dispatch can consume VBlank time

Full-screen redraws that have already gone through the safe LCD-off transition
may write directly to VRAM. Repeated Play Mode UI and visualization updates,
including `DrawChannelIndicators`, should use the buffer path.

### Controls

- Root Menu:
  - UP/DOWN: move selection
  - A or START: choose `ALBUM`, `SHUFFLE`, or `SINGLES`
  - selection changes play the D-Pad Hero menu-change sound effect
- Singles Song List:
  - UP/DOWN: move selection
  - A or START: play selected song
  - B: return to the root menu
  - selection and page changes play the D-Pad Hero menu-change sound effect
- Play Mode:
  - A: increase `hMasterVol` by `$10`, saturating at `$F0`
  - B: decrease `hMasterVol` by `$10`, saturating at `$00`
  - UP: toggle channel 1
  - DOWN: toggle channel 2
  - LEFT: toggle channel 3
  - RIGHT: toggle channel 4
  - START: open the pause menu and silence audio
- Paused:
  - UP/DOWN: move selection
  - SELECT: move to the next item
  - A or START: choose the highlighted item
  - B: cancel the pause menu and resume the song
  - selection changes play the D-Pad Hero menu-change sound effect

Rationale: the standalone ROMs already use the D-pad for channel toggles. Once a
song is playing, the Play Mode screen replaces the song list so future per-song
visualizations can use the full background nametable.

A, START, and B confirmation/cancel actions should not play sound effects.

The pause menu has five items:

- `RESUME`: return to Play Mode and continue the song without restarting
- `RESTART`: restart the current song from the beginning
- `PREV SONG`: start the previous song for the active playback mode
- `NEXT SONG`: start the next song for the active playback mode
- `QUIT`: stop playback and return to the root menu for `ALBUM`/`SHUFFLE` or
  the song list for `SINGLES`

Pressing B while the pause menu is open always cancels the menu and resumes the
song, regardless of the highlighted item.

## Version 1 Song Set

The version 1 song set is the selected entries in `music/gb-compilation/songs.mk`.
The current edition contains the 24 tracked `rgbasm` Game Boy songs plus the
explicit WLA-GB-compatible `risa-furanku-420` entry. Menu display titles are the
manifest `*_TITLE` values, and each title must fit one 20-tile Game Boy row with
the current menu margins.

Reason: `super-mario-land` and `ribbon` were the low-risk pair used to validate
the shared engine, bank switching, and menu/play state transitions. The full
manifest now stresses the source-driven generation path, paging, bank switching,
and verification across the tracked compatible Game Boy song catalog without
adding per-song visualization assets yet.

The full `ribbon` remix title is `Save Your Kisses For The Ole Rubber Duck`.
Version 1 should use `Save Your Kisses` because it fits the 20-character Game
Boy text width with side spacing. Scrolling or multi-line titles can be added
later.

## Cartridge And Bank Model

### Cartridge Type

- Use MBC5 without external RAM.
- Build with `rgbfix -v -p 0xFF -m MBC5`.
- Keep the header's ROM size byte under `rgbfix` control.
- Keep RAM size as no RAM unless a future feature needs save data.

MBC5 is the cartridge mapper for version 1 because it is simpler to program and
gives more room for later editions. It uses straightforward ROM bank selection,
avoids MBC1's unavailable-bank edge cases, and supports much larger ROM images.

For small physical runs or flash carts, current ready-made MBC5 ROM-only boards
are practical and inexpensive enough that the engineering simplicity is worth
keeping. A 512 KiB/32 KiB ROM-only MBC5 cart can be enough for early editions;
2 MiB ROM-only MBC5 leaves more headroom while still avoiding save RAM.

### DMG And CGB Mode

- Version 1 must run on DMG hardware.
- Do not require CGB-only features.
- If later editions add CGB enhancements, use a CGB-compatible header mode and
  keep a tested DMG fallback.
- Do not use a CGB-only header for this compilation.
- Version 1 should use DMG-compatible graphics, palettes, and input behavior.

### ROM Layout

Use one fixed bank plus one or more switchable banks. A Game Boy ROM bank is
16 KiB. `ROM0` is the fixed 16 KiB region at `$0000-$3FFF`; each `ROMX` bank is
one 16 KiB switchable region mapped at `$4000-$7FFF`.

- `ROM0` fixed bank:
  - interrupt vectors and header
  - boot/init
  - VBlank handler
  - input polling
  - OAM DMA helper
  - VRAM update helpers
  - menu and generic Play Mode UI
  - shared sound engine code and lookup tables
  - song catalog table
  - bank-switch helper
- `ROMX` song banks:
  - one song per bank for version 1
  - the song descriptor
  - generated song patterns/order data
  - hand-authored instrument table and envelope data
  - per-song wave RAM bytes
  - placeholder or future per-song visualization code/data

The one-song-per-bank rule is intentionally conservative for version 1. Later
editions can pack multiple small songs into one bank after the build can report
per-section sizes reliably.

Current selected GB music projects all fit within one 16 KiB bank for
audio-only content. The measured largest current song banks are:

- `cyndi-lauper-medley`: 14,282 bytes, 87.2% of one bank
- `a-few-knights-in-gerudo-valley`: 13,779 bytes, 84.1% of one bank
- `rockin-around-the-christmas-tree`: 10,699 bytes, 65.3% of one bank
- `what-im-made-of`: 10,339 bytes, 63.1% of one bank
- `ribbon`: 9,824 bytes, 60.0% of one bank

The current 25-song edition uses banks 1-25 for audio-only song data. The
explicit WLA-GB `risa-furanku-420` entry uses 4,610 bytes, 28.1% of one bank.
With one song per bank, the 25 selected songs use 25 switchable song banks plus
the fixed bank. That fits in a 512 KiB MBC5 ROM image configuration, which
provides 32 total 16 KiB banks. Future per-song visualization code/data may
require giving large songs extra banks or moving visualizers to separate banks.

### Bank Switching Rules

- Keep `wActiveSongBank` or an HRAM equivalent with the selected song's bank.
- Select the active song bank before calling `StartSong`.
- Ensure the active song bank is selected before every `UpdateSound` call, since
  the engine stores 16-bit pointers into the selected bank's song data.
- Future visualization code must either:
  - live in the same bank as its song, or
  - switch banks only around calls that do not overlap with `UpdateSound`, then
    restore the active song bank before returning.
- Do not rely on bank 0 aliases for song data.

## Shared Music Engine

The standalone ROMs historically embedded the sound engine in each `main.s`.
The canonical shared RGBDS engine for tracked GB music projects lives under:

```text
lib/gb/sound-engine.s
lib/gb/sound-engine.inc
lib/gb/README.md
```

`lib/gb/README.md` owns the shared engine API, feature flags, caller contract,
and migration verification policy. This spec should describe only how the
compilation consumes that engine.

The compilation uses these shared engine APIs:

- `StartSong`: input `HL = song descriptor in the active ROMX bank`
- `UpdateSound`: called from the active playback state once per VBlank while
  playback is active; when paused, it must not advance music track data if it is
  called
- `StopSound`: new helper for silencing all four channels on exit or quit
- `SilenceSoundOutput`: new helper for pause-time audio silence that does not
  modify track state or channel mute bits
- `RestoreSoundOutput`: new helper for resuming the output routing after pause
- `GetMutedChannelsMask` and `SetMutedChannelsMask` for channel mute bits
- exported shadow registers `hShadowNR12`, `hShadowNR22`, `hShadowNR32`,
  and `hShadowNR42` for existing project visualizers

The compilation must assemble `lib/gb/sound-engine.s` with:

- `-D NO_SONG_SPEED_ADJUSTMENT`
- `-D SOUND_ENGINE_ENABLE_PAUSE`
- `-D SOUND_ENGINE_ENABLE_STOP`
- `-D SOUND_ENGINE_ENABLE_SFX`

The compilation defines `SOUND_ENGINE_ENABLE_SFX` for menu-change feedback and
provides the D-Pad Hero SFX data tables in ROM0. It should not define
`SOUND_ENGINE_ENABLE_PATTERN_ROW_CALLBACK` or `SOUND_ENGINE_ENABLE_PREROLL`
unless those APIs become part of the compilation behavior.

Channel status bits follow the shared engine contract:

- bit 0: channel 1 muted
- bit 1: channel 2 muted
- bit 2: channel 3 muted
- bit 3: channel 4 muted
- bit 4: paused, because the compilation enables `SOUND_ENGINE_ENABLE_PAUSE`

`PauseMusic` should set the paused bit, and `UnpauseMusic` should clear it.
While paused, `UpdateSound` must not advance the music tracks. Pausing can
silence all four music channels immediately. This pause-time silence must not
call `StopSound`, because `StopSound` clears active track state and would break
Resume. The channel mute bits should remain unchanged so Resume restores the
user's channel-toggle choices.

The migrated GB music standalones and `gb-compilation` should assemble the
shared engine with `-D NO_SONG_SPEED_ADJUSTMENT`. The older standalone engines
used the XM song speed directly; omitting this define decrements the initial
song speed and makes affected songs play too fast. Projects that intentionally
want the D-Pad Hero speed adjustment should opt into that behavior explicitly.

`DefaultWavRam` is not part of the shared engine. Each song project owns its
active wave-RAM table, and the compilation imports that per-song table from the
source project.

The original two-song proof of concept used `super-mario-land` and `ribbon` as a
small first integration set. Per-song projects and the compilation project are
assumed to use the latest sound-engine contract, so selected songs are treated as
compatible with the shared engine.

The main extraction risk was that `games/d-pad-hero/main.s` was monolithic: the
sound engine, SFX support, WRAM/HRAM state, lookup tables, and game-specific
logic all lived in one source file. The first implementation step isolated the
engine and proved that one banked song played before building the full menu
scaffold.

## Standalone Engine Drift

The standalone music projects are authoritative for song assets. They should link
the shared engine instead of embedding private engine copies, so engine fixes and
optional SFX-capable behavior are picked up uniformly.

Historically, the tracked `rgbasm` standalone music projects fell into multiple
embedded engine variants. That drift made standalone audio comparisons hard to
interpret. With the shared-engine migration in place, `make verify-diff` is still
an aggregate regression guard rather than a frame-exact proof: the compilation
and standalone ROMs have different startup code, UI work, and main-loop timing.

When `make verify-diff` reports a divergence:

- first check whether both ROMs link the current shared engine
- confirm that the source project's active `DefaultWavRam` table is present and
  is the one the compilation imports
- treat documented per-song `DIFF_ARGS` as calibration for known ROM-level
  timing differences, not as evidence that the compilation is less accurate
- use listening checks or hardware/emulator review when a drift may be audible

Future repo-wide cleanup should keep the library boundary narrow:

- new GB music projects should include `sound-engine.inc` and link
  `sound-engine.s` instead of copying engine code into `main.s`
- the generic channel visualizer used by many standalones is implemented in the
  compilation ROM0 code first and is a candidate for a later shared library
  module
- per-song custom visualizers should remain separate from the shared sound
  engine unless a genuinely reusable visualization API emerges

Shared-engine migrations are not proven by successful assembly alone. When a
standalone project moves from an embedded engine copy to `lib/gb/sound-engine.s`,
or when the shared engine changes in a way that may affect playback, compare the
new standalone ROM against the previous standalone ROM with
`tools/verify_playback.py --standalone-diff --diff <old-rom>`. Treat frequency
count changes as high-risk because they can indicate wrong notes. Register
change-rate and RMS differences can come from timing, envelope, and effect
behavior changes; review those by listening when the delta is measurable. If a
released standalone must preserve old audio exactly, either adjust the song data
for the shared engine or document a temporary engine exception.

The D-Pad Hero-derived immediate envelope processing is the canonical shared
engine behavior. Older embedded engines sometimes returned immediately after
loading an envelope point, effectively adding a one-tick delay before that point
was processed. Migrate those songs by adjusting envelope data, not by adding a
legacy engine mode. The source-data equivalent is an explicit no-op envelope
point before each real point: `db $00,<current-volume>,$01`, where
`<current-volume>` is the previous point's destination, or the envelope start
volume before the first point.

When `.sym` files are available, `--standalone-diff` should also compare the
runtime `wTracks` speed values after warmup. A speed mismatch is a hard failure
because it usually means `NO_SONG_SPEED_ADJUSTMENT` was omitted or applied
incorrectly.

## Song Asset Model

The standalone music project remains the source of truth for song assets. The
compilation project should not track copied `.xm`, `instruments.txt`, `song.s`,
or extracted wave-RAM files when those files can be derived from tracked
standalone projects.

This deliberately trades snapshot isolation for simpler source-of-truth builds.
The compilation is not self-contained: it requires the sibling standalone source
projects from the repository checkout. Rebuilding after a selected source song is
edited will update the compilation output automatically, so a compilation
edition is not pinned against later source-song changes. If release editions need
to be reproducible across future source edits, add a separate pinning mechanism
such as a `songs.lock` file that records expected source commits or content
hashes.

Suggested layout:

```text
lib/gb/
  sound-engine.s
  sound-engine.inc

music/gb-compilation/
  SPEC.md
  Makefile
  songs.mk
  src/
    main.s
    hardware.inc
    ui/
      ball.bin
      font.bin
  tools/
    catalog_lib.rb
    generate_catalog_asm.rb
    generate_song_asm.rb
    report_sizes.rb
    verify_diff.rb
    verify_playback.py
    verify_sources.rb
  build/
    generated/
```

For each selected song, the manifest records:

- the source project directory
- the XM filename
- the instrument-map filename
- the hand-authored `song.s` filename
- the source `main.s` filename used to extract the active `DefaultWavRam`
- the source assembler syntax, defaulting to `rgbasm`; `wla-gb` is supported
  for explicitly selected compatible Game Boy projects
- the assembly label prefix
- the target ROM bank
- the menu title
- optional verifier-only `DIFF_ARGS` used by `make verify-diff` when a
  standalone ROM needs narrowly documented aggregate comparison tolerances

The `SONGS` list is the user-facing album/menu order. It must follow the
chronological `SNOWBRO NNN` header string from each selected source project's
`main.s`. Keep the physical `<slug>_BANK` values explicit; they do not have to
match the user-facing order as long as they remain valid and unique.

The build should depend directly on those source files. If a source XM,
instrument map, `song.s`, or source `main.s` is touched, Make should regenerate
the affected files under `build/generated/` without any manual import step.

The standalone `song.inc` should be treated as rebuildable generated output, not
as the canonical source. Regenerate it from the source XM and instrument map.

## Source Asset Workflow

The build must validate selected source projects before generating song data:

- verify the source project directory is tracked or contains tracked files
- verify the source `Makefile` is tracked and contains the manifest-selected
  source assembler (`rgbasm` by default, or `wla-gb` for explicit WLA-GB
  compatibility entries)
- verify the source XM, instrument map, `song.s`, and source `main.s` files are
  tracked by git; tracked files may still have local working-tree edits, and the
  build should use the working-tree contents
- parse each selected source `main.s` for its `SNOWBRO NNN` header string,
  reject duplicate release numbers, and verify that `SONGS` is chronological by
  that number
- write no timestamps, absolute paths, or environment-specific data to generated
  files
- never modify source project files

Generated song files are rebuildable artifacts and should live under
`build/generated/`, which is ignored by git.

## Song Generation And Namespacing

Each song needs a stable assembly prefix derived from its slug. Example:

```text
super-mario-land -> super_mario_land
ribbon -> ribbon
```

Generate song pattern/order data with:

```sh
xm2gb --label-prefix=<prefix> \
  --instruments-map=<source>/<instruments.txt> \
  <source>/<song.xm> > build/generated/<slug>.inc
```

`xm2gb --label-prefix` produces labels like `<prefix>_song` and expects an
instrument table named `<prefix>_instrument_table`.

Because source `song.s` is hand-authored and contains global labels such as
`env0`, `song_instrument_table`, or `SONG_instrument_table`, the build must
generate a namespaced assembly file per song. Do not include multiple source
`song.s` files directly without namespacing.

For WLA-GB source projects, the generator should normalize only the supported
data-wrapper syntax needed by the shared song format: `.db` to `db`, `.dw` to
`dw`, and `.include "song.inc"` as the generated-include marker. The generated
compilation assembly remains RGBDS syntax and must still be assembled with
`rgbasm`.

Recommended generated shape:

```asm
SECTION "Song <slug>", ROMX, BANK[<bank>]

; Generated from <source>/song.s with labels rewritten to <prefix>_*
<prefix>_instrument_table:
    dw <prefix>_env0
    ; ...

<prefix>_env0:
<prefix>_wave_ram:
    ; Generated from <source>/main.s DefaultWavRam.
    db ...

INCLUDE "build/generated/<slug>.inc"
```

The namespacing step should be implemented by a small deterministic script or a
strict Makefile rule. It should only rewrite labels and references known to come
from the source song instrument file.

## Song Catalog

Keep a single source of truth for song metadata in `songs.mk`, which is included
by the Makefile and parsed by the source-validation and catalog tools.

Current manifest excerpt:

```text
SONGS := super-mario-land ribbon eh-eh-nothing-else-i-can-say \
    save-your-tears cyndi-lauper-medley a-few-knights-in-gerudo-valley
DEFAULT_SONG_DURATION_SECONDS ?= 90

super-mario-land_SOURCE := ../super-mario-land
super-mario-land_XM := SONG.XM
super-mario-land_INSTRUMENTS := instruments.txt
super-mario-land_SONG_ASM := song.s
super-mario-land_MAIN_ASM := main.s
super-mario-land_PREFIX := super_mario_land
super-mario-land_BANK := 1
super-mario-land_TITLE := SUPER MARIO LAND
super-mario-land_DURATION_SECONDS := 198

ribbon_SOURCE := ../ribbon
ribbon_XM := SONG.XM
ribbon_INSTRUMENTS := instruments.txt
ribbon_SONG_ASM := song.s
ribbon_MAIN_ASM := main.s
ribbon_PREFIX := ribbon
ribbon_BANK := 2
ribbon_TITLE := SAVE YOUR KISSES
ribbon_DURATION_SECONDS := 158

eh-eh-nothing-else-i-can-say_SOURCE := ../eh-eh-nothing-else-i-can-say
eh-eh-nothing-else-i-can-say_XM := SONG.XM
eh-eh-nothing-else-i-can-say_INSTRUMENTS := instruments.txt
eh-eh-nothing-else-i-can-say_SONG_ASM := song.s
eh-eh-nothing-else-i-can-say_MAIN_ASM := main.s
eh-eh-nothing-else-i-can-say_PREFIX := eh_eh_nothing_else_i_can_say
eh-eh-nothing-else-i-can-say_BANK := 13
eh-eh-nothing-else-i-can-say_TITLE := EH EH NOTHING
eh-eh-nothing-else-i-can-say_DURATION_SECONDS := 149
```

`*_DURATION_SECONDS` controls auto-advance timing for `ALBUM` and `SHUFFLE`.
If a song omits it, the catalog generator should use
`DEFAULT_SONG_DURATION_SECONDS`. The generated frame count can use
`seconds * 60`; exact wall-clock precision is not required for convention
playback. The generated frame count must fit in a 16-bit countdown value; the
build should fail if `seconds * 60 > 65535`.

Durations should be maintained with `make duration-report`, which analyzes the
generated song data that the compilation actually assembles. The analyzer should
simulate the shared engine's order, pattern-row, and speed-command behavior well
enough to report the first loop point for each song, including songs that change
speed during playback. The Makefile applies `DURATION_MARGIN_SECONDS ?= -1` by
default so auto-advance happens just before the loop point instead of after the
first repeated second. Manual listening is still useful to check the musical
transition, but stopwatch timing should not be the source of truth. If a song is
designed as a seamless loop and the default margin cuts the phrase short, keep a
documented per-song override in `songs.mk`.

Generated catalog data in assembly should include:

- display title pointer
- optional display subtitle pointer
- automatic playback duration in frames, preferably as a 16-bit countdown value
- ROM bank number
- song descriptor pointer, such as `super_mario_land_song`
- wave RAM pointer
- visualization bank number, where `0` means a ROM0 visualizer
- visualization init/update/teardown pointers

The default generated visualizer fields should point at the ROM0 generic
visualizer handlers. Custom per-song visualizers can opt in later by adding
manifest fields for their visualizer bank and lifecycle pointers.

The visualizer dispatcher must restore the active song bank after each hook
returns, so banked visualization code cannot break later sound-engine reads.
A nonzero visualizer bank means the hook runs from that bank, not necessarily
from the song data bank. If a custom visualizer needs song-bank data, it should
either live in the same bank as the song, read bank-independent shared state
such as HRAM/WRAM shadows, or use a ROM0 helper/trampoline for cross-bank reads.
Do not switch away from the currently executing ROMX hook bank and then continue
executing hook code from ROMX.

## Playback Lifecycle

### Singles Menu Page Change

1. Update the selected song index to the first or last song on the destination
   page, depending on navigation direction.
2. Hide the window.
3. Call the D-Pad Hero-derived `TurnOffLCD` procedure.
4. Advance `hMainState` to the menu-page redraw handler.
5. On the next VBlank, clear the background nametable.
6. Render the destination menu page, including the selected-song cursor and page
   indicator.
7. Turn the LCD back on.
8. Restore menu controls.

### Enter Automatic Playback

1. Set `hPlaybackMode` to `ALBUM` or `SHUFFLE`.
2. For `ALBUM`, select the first manifest song, or preserve the last album
   position if a later UX decision wants resume-like behavior.
3. For `SHUFFLE`, initialize or refill the shuffle bag, seed the PRNG from
   input timing and timer state, and select the first bag entry.
4. Enter Play Mode for the selected catalog entry without showing the song
   list.

### Enter Play Mode

1. Stop any current song and silence hardware channels.
2. Load selected song metadata from the catalog.
3. Hide the window.
4. Call the D-Pad Hero-derived `TurnOffLCD` procedure.
5. Advance `hMainState` to the Play Mode init handler.
6. On the next VBlank, switch to the selected song bank before reading per-song
   visualization data.
7. Clear the background nametable.
8. Clear the window nametable.
9. Pre-render the pause menu's static window contents while the LCD is off.
10. Draw the Play Mode nametable, including the selected song title near the top
    and the generic channel visualizer or selected custom visualization.
11. Call the selected visualizer's `init` hook with the LCD still off.
12. Turn the LCD back on.
13. Copy the selected song's wave RAM bytes to wave channel RAM.
14. Set `HL` to the selected song descriptor.
15. Clear mute/pause state.
16. Call `StartSong`.
17. Load the selected song's generated duration into an auto-advance countdown.
    `SINGLES` may load it too, but should not consume it for automatic
    advancement.
18. In the VBlank handler, after `FlushVramBuffer` and input polling, select
    the active song bank and call `UpdateSound`.
19. In the Play Mode state handler, call the selected visualizer's `update`
    hook. The default generic update queues the channel indicator for the next
    VBlank flush.
20. In `ALBUM` or `SHUFFLE`, decrement the auto-advance countdown once per Play
    Mode frame. Do not decrement while paused. When it reaches zero, advance to
    the next song for the active playback mode.

### Pause

1. Call `PauseMusic`.
2. Call `SilenceSoundOutput` to silence audio immediately without changing
   track state.
3. Reset the pause cursor to `RESUME` by queuing cursor tile updates through
   the VRAM buffer.
4. Show the pre-rendered window near the bottom of the screen. Because
   `FlushVramBuffer` runs before the VBlank handler applies `hWindowY` to
   `rWY`, the cursor reset is flushed before the window becomes visible.
5. Move the pause cursor by queuing one-tile VRAM buffer updates.
6. Keep channel mute state unchanged.

### Resume

1. Hide the window.
2. Restore the active song bank.
3. Call `UnpauseMusic`.
4. Call `RestoreSoundOutput`.
5. Return to the Play Mode state handler so `UpdateSound` and visualization
   updates resume on the next VBlank dispatch.

### Restart

1. Call the selected visualizer's `teardown` hook.
2. Hide the window.
3. Call the D-Pad Hero-derived `TurnOffLCD` procedure.
4. Advance `hMainState` to the Play Mode init handler.
5. On the next VBlank, stop the current song, silence hardware channels, and
   reinitialize the current song's Play Mode nametable and visualization state.
6. Restore the active song bank.
7. Re-enter Play Mode for the current catalog entry.

### Previous Or Next Song

1. Call the selected visualizer's `teardown` hook.
2. Hide the window.
3. Choose the adjacent song according to `hPlaybackMode`:
   - `SINGLES`: previous or next catalog index, wrapping at the ends
   - `ALBUM`: previous or next manifest-order index, wrapping at the ends
   - `SHUFFLE`: previous or next entry in the current shuffle bag. Next refills
     the bag after the last entry. Previous from the first entry wraps to the
     current bag's last entry rather than reshuffling.
4. Call the D-Pad Hero-derived `TurnOffLCD` procedure.
5. Advance `hMainState` to the Play Mode init handler.
6. On the next VBlank, stop the current song, silence hardware channels, reset
   the duration countdown, and initialize Play Mode for the newly selected song.

### Automatic Advance

1. When the active mode is `ALBUM` or `SHUFFLE` and the duration countdown
   reaches zero, follow the Next Song lifecycle.
2. Automatic advance must not run while paused.
3. Automatic advance must not return to the root menu or the song list.

### Exit From Play Mode

1. Call the selected visualizer's `teardown` hook.
2. Stop advancing song data.
3. Silence all four channels.
4. Clear active song state.
5. Hide the window.
6. Call the D-Pad Hero-derived `TurnOffLCD` procedure.
7. If `hPlaybackMode` is `ALBUM` or `SHUFFLE`, advance `hMainState` to the root
   menu redraw handler. If it is `SINGLES`, advance `hMainState` to the song-list
   redraw handler.
8. On the next VBlank, clear the background nametable.
9. Rebuild the root menu for `ALBUM`/`SHUFFLE`, or rebuild the song-list menu
   for the page containing the selected song for `SINGLES`.
10. Turn the LCD back on.
11. Restore menu controls.

## Implementation Proposal

Implement the project in this order:

1. Extract the shared engine from `games/d-pad-hero/main.s`, add the
   compilation pause-silence helpers, and promote it to
   `lib/gb/sound-engine.s` and `lib/gb/sound-engine.inc`.
2. Build a minimal MBC5 ROM that keeps the engine in `ROM0`, puts
   `super-mario-land` in one `ROMX` bank, switches to that bank, and starts the
   song.
3. Verify playback, pause, resume, restart, quit/silence, and channel toggles
   against that single-song build before adding catalog complexity.
4. Add the manifest, direct source-asset validation,
   `xm2gb --label-prefix` generation, and deterministic per-song assembly
   generation under `build/generated/`.
5. Add the song catalog and menu UI, using `games/d-pad-hero` as the reference
   for song selection and pause menu behavior.
6. Add `ribbon` as the second song and verify that bank switching, restart, and
   return-to-menu do not retain stale state from the previous song. Then add
   more tracked GB songs in small batches and verify that each starts, advances,
   produces audio, pauses, and quits cleanly.
7. Add the map-size report so later editions can scale to the rest of the
   tracked songs and eventually to visualization banks.
8. Use the paged menu before adding enough songs to exceed one screen.
9. Add the generic channel-indicator visualizer to `ROM0`, using the shared
   engine shadow registers and mute bits.
10. Add per-song visualizer hooks once the full-screen Play Mode nametable,
    generic visualizer, and window-backed pause menu are in place.
11. Add custom visualizers incrementally by overriding the generated hook fields
    for one song at a time.
12. Add the root menu and playback modes: `ALBUM`, `SHUFFLE`, and `SINGLES`.
    Extend the catalog generator with per-song durations, add shuffle-bag state,
    and expand the pause window with Previous Song and Next Song before wiring
    automatic advance.

## Build Workflow

The first version should support:

```sh
make
make clean
make duration-report
make size-report
make verify
make verify-diff
```

The Makefile should expose `SONGS_PER_PAGE`. The current default is
`SONGS_PER_PAGE=12`, matching the title rows available in the menu layout.
`make verify` should build a dedicated one-song-per-page fixture in
`build/verify-paging/` for page-transition coverage.
The Makefile should also expose a verifier-only duration override, such as
`SONG_DURATION_SECONDS_OVERRIDE=1`, and `make verify` should build a dedicated
short-duration fixture in `build/verify-auto/` so `ALBUM` auto-advance,
`SHUFFLE` bag behavior, and pause-menu Previous/Next Song can be tested in a
bounded number of frames.

Expected build steps:

1. Read the manifest.
2. Verify each selected source project is tracked and still matches the
   manifest-selected source assembler rule.
3. Verify each selected source XM, instrument map, `song.s`, and source
   `main.s` is tracked by git.
4. Regenerate `<slug>.inc` from the source XM and instrument map using
   `xm2gb --label-prefix`.
5. Generate namespaced per-song assembly from the source `song.s`, and extract
   `<prefix>_wave_ram` from the source `main.s` `DefaultWavRam` table.
6. Assemble fixed code and generated song bank code with `rgbasm`.
7. Link with `rgblink -n Notube4meMusic.sym -m Notube4meMusic.map`.
8. Fix and pad with
   `rgbfix -v -p 0xFF -m MBC5 -t "NOTUBE4ME MUSIC" Notube4meMusic.gb`.
9. For `make duration-report`, generate the selected songs' `.inc` files and
   run the offline duration analyzer against `build/generated/`.
10. For `make verify`, create `build/venv` when missing, install the PyBoy/numpy
   verifier dependencies there, run `tools/verify_playback.py` against the
   default ROM and generated symbol file, then build separate fixture ROMs:
   `SONGS_PER_PAGE=1` in `build/verify-paging/` for page-turn assertions, and a
   short-duration build in `build/verify-auto/` for auto-advance assertions.
11. For `make verify-diff`, copy each selected standalone source project into
    `build/verify-standalone/<slug>/`, using only git-tracked source files so
    ignored standalone build artifacts cannot be reused accidentally.
12. Build that copy and compare the matching compilation song against the
    temporary standalone ROM with `tools/verify_playback.py --diff-only --diff`.
    For `rgbasm` source projects, build with `make -B` so the standalone
    reference regenerates `song.inc` from the source XM and instrument map. For
    WLA-GB source projects, generate `song.inc` in the temp copy with current
    `xm2gb`, normalize its `db`/`dw` directives to WLA `.db`/`.dw`, then build
    without forcing the WLA Makefile to regenerate the file again. Never rewrite
    tracked files in the real source project.
12. Use a longer comparison window than the default one-off `--diff` command,
    and allow per-song manifest `DIFF_ARGS` only for documented tolerance
    calibration. The driver must still check that the standalone build did not
    modify any tracked source-project files, because source assets are
    canonical and the compilation build must never rewrite them.

The build should fail if:

- a selected song source project is untracked
- a selected project's tracked Makefile no longer contains the selected source
  assembler
- a selected source asset is missing or untracked
- two songs produce the same label prefix
- two songs use the same explicit song bank
- two selected songs use the same `SNOWBRO NNN` release number
- `SONGS` is not ordered by selected projects' `SNOWBRO NNN` release numbers
- a menu title is too long for one menu row
- a song duration converts to more than 65535 frames
- `SONGS_PER_PAGE` is zero or larger than the supported visible row count
- a song bank overflows
- fixed-bank code overflows

## Size And Map Inspection

Standalone ROMs are currently padded to 32 KiB by `rgbfix -p 0xFF`, so their
file size alone does not show real code/data usage.

Implementation should inspect `Notube4meMusic.map` after linking and report:

- total fixed-bank usage
- usage per song bank
- remaining bytes per bank
- generated song data size per song
- visualization code/data size per song when visualizers are added

For the POC, exact size packing is less important than proving the banked engine
contract. Later editions should use the map data to decide whether multiple
songs can share a bank.

## Testing And Acceptance Criteria

Version 1 is acceptable when:

- The compilation ROM builds from a clean checkout plus tracked selected assets.
- Only the songs selected in `songs.mk` appear in the menu.
- The root menu can choose `ALBUM`, `SHUFFLE`, or `SINGLES`.
- Root-menu, song-list, and pause-menu selection changes play the D-Pad Hero
  menu-change sound effect; confirmation and cancel actions do not.
- `SINGLES` opens the paged song list.
- `ALBUM` and `SINGLES` use the chronological `SNOWBRO NNN` release order from
  the selected source projects.
- Entering `SINGLES` from the root menu resets the selected song to the first
  song, even if `ALBUM` or `SHUFFLE` last played a different song.
- B from the `SINGLES` song list returns to the root menu.
- The song-list selection can move and start each song.
- `ALBUM` starts songs in manifest order and advances by per-song duration,
  using a short-duration verifier fixture for bounded automated coverage.
- `ALBUM` Play Mode shows `SONG X OF Y` and updates the value after automatic,
  previous-song, and next-song transitions.
- `SHUFFLE` starts songs from a shuffled bag, advances by per-song duration, and
  avoids immediate repeats when the bag is refilled, using the same
  short-duration verifier fixture for bounded automated coverage.
- Each selected song starts from the beginning.
- Playback continues correctly across pattern/order boundaries.
- Channel toggles affect the correct hardware channels.
- START opens the pause menu and silences audio.
- The pause menu can resume, restart, skip to the previous song, skip to the
  next song, or quit.
- B cancels the pause menu and resumes the song, regardless of the highlighted
  item.
- Resume continues playback without restarting the song and preserves channel
  mute state.
- Restart starts the current song from the beginning.
- Previous Song and Next Song re-enter Play Mode directly, reset stale playback
  state, and choose songs according to the active playback mode.
- Quit returns to the root menu for `ALBUM`/`SHUFFLE`, returns to the song list
  for `SINGLES` without resetting the selected song, and silences audio.
- Starting a different song after exit does not use stale state from the prior
  song.
- Starting a previously played song again after playing a different song
  selects the correct bank and does not inherit channel mute state.
- The final ROM header identifies an MBC cartridge, not ROM-only.
- `Notube4meMusic.map` shows song data in `ROMX`, not `ROM0`.
- `make verify` boots the default ROM and the one-song-per-page paging fixture
  headlessly. Together, they should check playback advancement, root-menu
  selection, song-list selection, page transitions, returning from Play Mode to
  the page containing the selected song in `SINGLES`, `ALBUM` auto-advance,
  `SHUFFLE` bag behavior, playback advancement for all selected songs,
  pause-time silence, pause-menu resume/restart/previous/next/quit,
  B-button pause-menu cancel, quit-time silence, channel-toggle state,
  channel-indicator tilemap state, mute icons in the generic visualizer, reverse
  song switching, mute-state reset, Play Mode screen replacement, window
  position state, pause-menu window tilemap text, and representative background
  tilemap text.
- Later long-list verification should cover page wraparound once the catalog has
  enough songs to distinguish ordinary page changes from list wraparound.
- Later per-song visualization verification should cover each custom
  visualizer's init/update/teardown behavior and ensure the pause-menu window
  overlays without clobbering the Play Mode background.
- Touching or editing a source XM, instrument map, `song.s`, or source `main.s`
  rebuilds the affected generated song files under `build/generated/` without
  requiring an import command.
- `make verify-diff` can be run as a slower fidelity check. It builds temporary
  copies of the selected standalone ROMs with `make -B`, verifies that doing so
  did not modify tracked source-project files, and compares aggregate APU
  behavior for each compilation song against its source-regenerated standalone
  ROM. Songs that need non-default aggregate thresholds should declare those
  thresholds in `songs.mk`, not in the verifier script.

Suggested emulator/hardware smoke tests:

- BGB or SameBoy for debugger-visible bank/register checks.
- mGBA or SameBoy for quick playback sanity.
- `tools/verify_playback.py --diff <standalone.gb>` for optional aggregate APU
  comparison against a standalone ROM. This mode should compare channel register
  behavior over a window, not require byte-identical per-frame register streams,
  because different ROM init paths are not cycle-aligned.
- `tools/verify_playback.py --standalone-diff --diff <old.gb> <new.gb>` for
  pre/post standalone comparisons during shared-engine migrations.
- `make verify-diff` to run the aggregate APU comparison for every selected
  manifest song against the ROM built from that song's standalone Makefile.
- Real hardware or target flash cart if the MBC choice is meant for a physical
  cartridge edition.

## Local Reference Points

- `games/d-pad-hero/main.s` has a song-selection implementation with
  `SongDescriptors`, `MainFunc_SongSelectionInit`,
  `MainFunc_SongSelection`, and `SetupCurrentSong`.
- `games/d-pad-hero/main.s` has a pause menu implementation with
  `MainFunc_PauseInit`, `MainFunc_Pause`, `MainFunc_Unpause`, and
  `PauseScreenTilemap`.
- `games/d-pad-hero/main.s` has pause-aware sound behavior through its embedded
  sound status byte, `PauseMusic`, `UnpauseMusic`, and `UpdateSound`.
- `games/d-pad-hero/main.s` has the required safe `TurnOffLCD` implementation:
  it clears `LCDCF_ON` in `hShadowLCDC` and lets the VBlank handler copy that
  shadow to `rLCDC`.
- `music/severance/main.s` has a window-layer pattern using `hWindowX` and
  `hWindowY` shadows that are copied to `rWX` and `rWY` during VBlank, plus the
  simple hide-window behavior of moving `WY` to 144.

## External Reference Points

- Pan Docs documents MBC5's larger ROM address space and straightforward bank
  registers: <https://gbdev.io/pandocs/MBC5.html>
- Pan Docs documents MBC1's smaller ROM address space and banking caveats:
  <https://gbdev.io/pandocs/MBC1.html>
- GBDK's ROM banking guide recommends MBC5 for most projects and notes MBC1's
  unavailable-bank limitations:
  <https://gbdk.org/docs/api/docs_rombanking_mbcs.html>
- Current ready-made flash-cart options show practical MBC5 ROM-only boards:
  <https://shop.insidegadgets.com/product/gameboy-512kb-32kb-rom-only-flash-cart/>
  and
  <https://shop.insidegadgets.com/product/gameboy-2mb-rom-only-flash-cart/>

## Remaining Clarifications

No blocking questions remain for version 1.
