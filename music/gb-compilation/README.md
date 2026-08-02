# Notube4me Music Compilation

This project builds the Game Boy music compilation ROM from the tracked
source-of-truth song projects in `music/`.

## Requirements

- RGBDS: `rgbasm`, `rgblink`, and `rgbfix`
- `xm2gb`
- Ruby
- Python 3 for `make verify`; verifier dependencies are installed into
  `build/venv`

## Common Commands

Run these from `music/gb-compilation/`:

```sh
make
make size-report
make duration-report
make verify
make verify-diff
make clean
```

`make` writes the ROM to `build/Notube4meMusic.gb`.

`make verify` runs the headless playback checks. It also builds fixture ROMs
under `build/` for paging and short-duration auto-advance coverage.

`make verify-diff` is slower. It builds temporary standalone ROMs from tracked
source files and compares their audio behavior against the matching compilation
songs.

## Controls

The root menu chooses `ALBUM`, `SHUFFLE`, or `SINGLES`. `SINGLES` opens the
paged manual song list. Cursor movement in the root menu, song list, and pause
menu plays the D-Pad Hero menu-change sound effect. A and START confirmation,
and B cancel/back actions, do not play a sound effect.

## Adding A Song

1. Make sure the standalone source project is tracked by git and builds on its
   own.
2. Make sure the source `main.s` contains the correct `SNOWBRO NNN` header
   string.
3. Add the slug to `SONGS` in `songs.mk`, in `SNOWBRO NNN` chronological order.
   This order is used by both `ALBUM` and the `SINGLES` menu.
4. Add the song fields in `songs.mk`:
   - `<slug>_SOURCE`
   - `<slug>_XM`
   - `<slug>_INSTRUMENTS`
   - `<slug>_SONG_ASM`
   - `<slug>_MAIN_ASM`
   - `<slug>_PREFIX`
   - `<slug>_BANK`
   - `<slug>_TITLE`
5. Add `<slug>_SOURCE_ASSEMBLER := wla-gb` only for explicitly supported
   WLA-GB projects. RGBASM is the default.
6. Use the generic visualizer by default. Add visualizer hook fields only when
   the song has a custom visualizer ready.
7. Run `make duration-report` and copy the suggested
   `<slug>_DURATION_SECONDS` value into `songs.mk`, unless a documented
   listening pass shows the song needs a small musical-transition exception.
8. Run `make size-report`, `make verify`, and `make verify-diff`.
9. Listen to the ROM in an emulator or on hardware before treating the song as
   convention-ready.

## Refreshing Durations

When a source XM, instrument map, or song assembly file changes, run:

```sh
make duration-report
```

The report analyzes the generated song data that the compilation assembles. It
simulates order flow, row timing, and speed commands, including songs that
change speed during playback.

By default, the Makefile applies `DURATION_MARGIN_SECONDS ?= -1`, so suggested
durations advance about one second before the detected loop point. Override it
only when intentionally recalibrating:

```sh
make duration-report DURATION_MARGIN_SECONDS=0
```

After updating any `*_DURATION_SECONDS` values, run:

```sh
make verify
```

Manual listening is useful for checking whether the transition feels right, but
stopwatch timing should not be the source of truth. If a song is designed as a
seamless loop and the default margin cuts the phrase short, keep a documented
per-song override in `songs.mk`.
