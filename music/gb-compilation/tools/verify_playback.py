#!/usr/bin/env python3
"""Headless playback regression checks for the GB compilation ROM."""

from __future__ import annotations

import argparse
import math
import re
import sys
import warnings
from pathlib import Path

import numpy as np


MBC5_CART_TYPE = 0x19
LCDC = 0xFF40
NR51 = 0xFF25
NR52 = 0xFF26
WY = 0xFF4A
WX = 0xFF4B
BG_MAP = 0x9800
WINDOW_MAP = 0x9C00
APU_REGS = tuple(range(0xFF10, 0xFF27))
CHANNEL_NAMES = ("ch1", "ch2", "ch3", "ch4")
CHANNEL_REGS = (
    (0xFF10, 0xFF11, 0xFF12, 0xFF13, 0xFF14),
    (0xFF16, 0xFF17, 0xFF18, 0xFF19),
    (0xFF1A, 0xFF1B, 0xFF1C, 0xFF1D, 0xFF1E),
    (0xFF20, 0xFF21, 0xFF22, 0xFF23),
)

MAIN_STATE_ROOT_MENU = 0
MAIN_STATE_PLAY = 2
MAIN_STATE_SINGLES_MENU_INIT = 3
MAIN_STATE_PAUSE = 4
MAIN_STATE_SINGLES_MENU = 5
MAIN_STATE_MENU = MAIN_STATE_SINGLES_MENU
PLAYBACK_MODE_ALBUM = 0
PLAYBACK_MODE_SHUFFLE = 1
PLAYBACK_MODE_SINGLES = 2
ROOT_OPTION_ALBUM = 0
ROOT_OPTION_SHUFFLE = 1
ROOT_OPTION_SINGLES = 2
ROOT_OPTION_LABELS = ("ALBUM", "SHUFFLE", "SINGLES")
ROOT_TITLE_ROW = 4
ROOT_HEADING_ROW = 6
ROOT_OPTION_ROWS = (9, 11, 13)
ROOT_CURSOR_COL = 2
ROOT_OPTION_TEXT_COL = 4
PAUSE_OPTION_RESUME = 0
PAUSE_OPTION_RESTART = 1
PAUSE_OPTION_PREV = 2
PAUSE_OPTION_NEXT = 3
PAUSE_OPTION_QUIT = 4
PAUSE_OPTION_ROWS = (1, 2, 3, 4, 5)
PAUSE_HEADING_COL = 2
PAUSE_CURSOR_COL = 4
PAUSE_OPTION_TEXT_COL = 6
SONG_CATALOG_ENTRY_SIZE = 14
LCDC_ON = 0x80
LCDC_WINON = 0x20
WINDOW_X_LEFT = 7
WINDOW_Y_HIDDEN = 144
WINDOW_Y_PAUSE = 88
MENU_FIRST_SONG_ROW = 4
MENU_CURSOR_COL = 1
MENU_TITLE_COL = 3
MENU_PAGE_INDICATOR_ROW = 17
MENU_PAGE_INDICATOR_COL = 4
ALBUM_SONG_INDICATOR_ROW = 17
ALBUM_SONG_INDICATOR_COL = 4
MENU_SFX_OUTPUT_MASK = 0x11
CHANNEL_BUTTON_ICON_TOP_ROW = 6
CHANNEL_BUTTON_ICON_BOTTOM_ROW = 7
CHANNEL_BUTTON_ICON_COL = 4
CHANNEL_BUTTON_ICON_WIDTH = 11
CHANNEL_INDICATOR_TOP_ROW = 8
CHANNEL_INDICATOR_BOTTOM_ROW = 9
CHANNEL_INDICATOR_COL = 4
CHANNEL_INDICATOR_WIDTH = 11
CHANNEL_INDICATOR_PAIR_COLS = (0, 3, 6, 9)
CHANNEL_INDICATOR_TOP_BASE = 0x2B
CHANNEL_INDICATOR_BOTTOM_BASE = 0x2C
CHANNEL_INDICATOR_VOLUME_OFFSETS = tuple(range(0, 32, 4))
CHANNEL_BUTTON_TOP_BASE = CHANNEL_INDICATOR_TOP_BASE + 32
CHANNEL_BUTTON_BOTTOM_BASE = CHANNEL_BUTTON_TOP_BASE + 1
CHANNEL_MUTE_TOP_BASE = CHANNEL_BUTTON_TOP_BASE + 16
CHANNEL_MUTE_BOTTOM_BASE = CHANNEL_MUTE_TOP_BASE + 1
MASTER_VOL_ROW = 15
MASTER_VOL_COL = 2
MASTER_VOL_VALUE_COL = MASTER_VOL_COL + len("MASTER VOL: ")
AUDIO_SETTLE_FRAMES = 30
SILENCE_NONZERO_RATIO_LIMIT = 0.005

TRACK_SIZEOF = 0x1A
TRACK_SPEED = 0x00
TRACK_TICK = 0x01
TRACK_PATTERN_ROW = 0x03
TRACK_PATTERN_PTR_LO = 0x05
TRACK_PATTERN_PTR_HI = 0x06
TRACK_ORDER_POS = 0x07

TEXT_TILES = {" ": 0x00, ":": 0x25, "*": 0x26, "!": 0x27, "-": 0x28, "%": 0x29, "'": 0x2A}
TEXT_TILES.update({str(index): 0x01 + index for index in range(10)})
TEXT_TILES.update({chr(ord("A") + index): 0x0B + index for index in range(26)})


class VerifyFailure(Exception):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path)
    parser.add_argument("--sym", type=Path)
    parser.add_argument("--boot-frames", type=int, default=180)
    parser.add_argument("--advance-frames", type=int, default=600)
    parser.add_argument("--audio-frames", type=int, default=120)
    parser.add_argument("--min-cursor-states", type=int, default=16)
    parser.add_argument("--expect-songs-per-page", type=int)
    parser.add_argument("--require-page-turn", action="store_true")
    parser.add_argument("--require-auto-advance", action="store_true")
    parser.add_argument("--diff", type=Path, help="Optional standalone ROM to compare aggregate APU behavior against")
    parser.add_argument("--diff-only", action="store_true", help="Skip lifecycle checks and run only --diff")
    parser.add_argument(
        "--standalone-diff",
        action="store_true",
        help="Treat rom and --diff as standalone ROMs and compare aggregate APU behavior directly",
    )
    parser.add_argument(
        "--standalone-sym",
        type=Path,
        help="Symbol file for rom in --standalone-diff mode",
    )
    parser.add_argument(
        "--standalone-reference-sym",
        type=Path,
        help="Symbol file for --diff ROM in --standalone-diff mode",
    )
    parser.add_argument("--diff-song-index", type=int, default=0)
    parser.add_argument("--diff-frames", type=int, default=600)
    parser.add_argument("--diff-warmup-frames", type=int, default=180)
    parser.add_argument("--diff-change-tolerance", type=float, default=0.05)
    parser.add_argument("--diff-count-tolerance", type=int, default=8)
    parser.add_argument("--diff-count-ratio-tolerance", type=float, default=0.20)
    parser.add_argument("--diff-rms-ratio-min", type=float, default=0.50)
    return parser.parse_args()


def ok(label: str, detail: str) -> None:
    print(f"ok {label}: {detail}")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise VerifyFailure(message)


def parse_sym(path: Path) -> dict[str, int]:
    pattern = re.compile(r"^([0-9A-Fa-f]{2}):([0-9A-Fa-f]{4})\s+(.+)$")
    symbols: dict[str, int] = {}
    for line in path.read_text().splitlines():
        match = pattern.match(line)
        if not match:
            continue
        symbols[match.group(3)] = int(match.group(2), 16)
    return symbols


def require_symbol(symbols: dict[str, int], name: str) -> int:
    try:
        return symbols[name]
    except KeyError as exc:
        raise VerifyFailure(f"missing symbol in .sym file: {name}") from exc


def check_header(rom_path: Path) -> None:
    data = rom_path.read_bytes()
    require(len(data) > 0x149, f"ROM is too small: {rom_path}")
    cart_type = data[0x147]
    rom_size = data[0x148]
    ram_size = data[0x149]
    require(cart_type == MBC5_CART_TYPE, f"expected MBC5 cart type $19, got ${cart_type:02x}")
    ok("header", f"cart=${cart_type:02x} rom_size=${rom_size:02x} ram_size=${ram_size:02x}")


def make_pyboy(rom_path: Path):
    warnings.filterwarnings("ignore", message="Using SDL2 binaries.*")
    from pyboy import PyBoy

    attempts = (
        {"window": "null", "sound_emulated": True, "sound_volume": 100, "log_level": "ERROR"},
        {"window": "null", "sound": True},
        {"window": "headless", "sound": True},
        {"window": "dummy", "sound": True},
        {"window_type": "headless", "sound": True},
        {"window_type": "dummy", "sound": True},
        {"window": "null"},
        {"window_type": "headless"},
    )
    errors = []
    for kwargs in attempts:
        try:
            return PyBoy(str(rom_path), **kwargs)
        except TypeError as exc:
            errors.append(f"{kwargs}: {exc}")
        except ValueError as exc:
            errors.append(f"{kwargs}: {exc}")
    raise VerifyFailure("could not start PyBoy headlessly:\n" + "\n".join(errors))


def stop_pyboy(pyboy) -> None:
    try:
        pyboy.stop(save=False)
    except TypeError:
        pyboy.stop()


def tick_one(pyboy) -> None:
    attempts = (
        lambda: pyboy.tick(1, False, True),
        lambda: pyboy.tick(1, False),
        lambda: pyboy.tick(),
    )
    last_error: Exception | None = None
    for attempt in attempts:
        try:
            running = attempt()
            require(running is not False, "PyBoy stopped before verification completed")
            return
        except TypeError as exc:
            last_error = exc
    raise VerifyFailure(f"could not tick PyBoy: {last_error}")


def read_mem(pyboy, addr: int) -> int:
    if hasattr(pyboy, "memory"):
        return int(pyboy.memory[addr])
    if hasattr(pyboy, "get_memory_value"):
        return int(pyboy.get_memory_value(addr))
    raise VerifyFailure("PyBoy exposes neither memory[] nor get_memory_value()")


def write_mem(pyboy, addr: int, value: int) -> None:
    value &= 0xFF
    if hasattr(pyboy, "memory"):
        pyboy.memory[addr] = value
        return
    if hasattr(pyboy, "set_memory_value"):
        pyboy.set_memory_value(addr, value)
        return
    raise VerifyFailure("PyBoy exposes neither memory[] nor set_memory_value()")


def text_tiles(text: str) -> list[int]:
    try:
        return [TEXT_TILES[char] for char in text]
    except KeyError as exc:
        raise VerifyFailure(f"verifier cannot encode UI character: {exc.args[0]!r}") from exc


def tilemap_addr(row: int, col: int, base: int = BG_MAP) -> int:
    return base + row * 32 + col


def require_vram_tiles(pyboy, row: int, col: int, expected: list[int], label: str, base: int = BG_MAP) -> None:
    actual = [read_mem(pyboy, tilemap_addr(row, col + index, base)) for index in range(len(expected))]
    require(actual == expected, f"{label} tile sequence mismatch: expected {expected}, got {actual}")


def require_vram_text(pyboy, row: int, col: int, text: str, label: str, base: int = BG_MAP) -> None:
    expected = text_tiles(text)
    require_vram_tiles(pyboy, row, col, expected, label, base)


def require_vram_tile(pyboy, row: int, col: int, tile: int, label: str, base: int = BG_MAP) -> None:
    actual = read_mem(pyboy, tilemap_addr(row, col, base))
    require(actual == tile, f"{label} tile mismatch: expected ${tile:02x}, got ${actual:02x}")


def read_vram_tiles(pyboy, row: int, col: int, count: int, base: int = BG_MAP) -> list[int]:
    return [read_mem(pyboy, tilemap_addr(row, col + index, base)) for index in range(count)]


def require_channel_indicator_pair(tiles: list[int], base_tile: int, label: str) -> bool:
    require(len(tiles) == 2, f"{label} expected a two-tile channel indicator")
    if tiles == [TEXT_TILES[" "], TEXT_TILES[" "]]:
        return False
    mute_base = CHANNEL_MUTE_TOP_BASE if base_tile == CHANNEL_INDICATOR_TOP_BASE else CHANNEL_MUTE_BOTTOM_BASE
    if tiles == [mute_base, mute_base + 2]:
        return False
    first, second = tiles
    offset = first - base_tile
    require(
        offset in CHANNEL_INDICATOR_VOLUME_OFFSETS,
        f"{label} first tile ${first:02x} is outside the ball-tile sequence",
    )
    require(second == first + 2, f"{label} second tile ${second:02x} does not match first ${first:02x}")
    return True


def channel_indicator_channel_tiles(pyboy, channel: int) -> tuple[list[int], list[int]]:
    start_col = CHANNEL_INDICATOR_COL + CHANNEL_INDICATOR_PAIR_COLS[channel]
    top = read_vram_tiles(pyboy, CHANNEL_INDICATOR_TOP_ROW, start_col, 2)
    bottom = read_vram_tiles(pyboy, CHANNEL_INDICATOR_BOTTOM_ROW, start_col, 2)
    return top, bottom


def require_channel_indicators(pyboy, label: str, require_active: bool = True) -> None:
    top = read_vram_tiles(pyboy, CHANNEL_INDICATOR_TOP_ROW, CHANNEL_INDICATOR_COL, CHANNEL_INDICATOR_WIDTH)
    bottom = read_vram_tiles(pyboy, CHANNEL_INDICATOR_BOTTOM_ROW, CHANNEL_INDICATOR_COL, CHANNEL_INDICATOR_WIDTH)
    active_channels = 0

    for separator_col in (2, 5, 8):
        require(top[separator_col] == TEXT_TILES[" "], f"{label} top separator {separator_col} is not blank")
        require(bottom[separator_col] == TEXT_TILES[" "], f"{label} bottom separator {separator_col} is not blank")

    for channel, pair_col in enumerate(CHANNEL_INDICATOR_PAIR_COLS):
        top_active = require_channel_indicator_pair(
            top[pair_col : pair_col + 2],
            CHANNEL_INDICATOR_TOP_BASE,
            f"{label} channel {channel + 1} top",
        )
        bottom_active = require_channel_indicator_pair(
            bottom[pair_col : pair_col + 2],
            CHANNEL_INDICATOR_BOTTOM_BASE,
            f"{label} channel {channel + 1} bottom",
        )
        require(top_active == bottom_active, f"{label} channel {channel + 1} top/bottom mismatch")
        if top_active:
            active_channels += 1

    require(not require_active or active_channels > 0, f"{label} had no active channel indicators")
    ok(f"{label} indicators", f"active_channels={active_channels}")


def require_channel_button_icons(pyboy, label: str) -> None:
    top = read_vram_tiles(
        pyboy,
        CHANNEL_BUTTON_ICON_TOP_ROW,
        CHANNEL_BUTTON_ICON_COL,
        CHANNEL_BUTTON_ICON_WIDTH,
    )
    bottom = read_vram_tiles(
        pyboy,
        CHANNEL_BUTTON_ICON_BOTTOM_ROW,
        CHANNEL_BUTTON_ICON_COL,
        CHANNEL_BUTTON_ICON_WIDTH,
    )
    expected_top = [
        CHANNEL_BUTTON_TOP_BASE,
        CHANNEL_BUTTON_TOP_BASE + 2,
        TEXT_TILES[" "],
        CHANNEL_BUTTON_TOP_BASE + 4,
        CHANNEL_BUTTON_TOP_BASE + 6,
        TEXT_TILES[" "],
        CHANNEL_BUTTON_TOP_BASE + 8,
        CHANNEL_BUTTON_TOP_BASE + 10,
        TEXT_TILES[" "],
        CHANNEL_BUTTON_TOP_BASE + 12,
        CHANNEL_BUTTON_TOP_BASE + 14,
    ]
    expected_bottom = [
        CHANNEL_BUTTON_BOTTOM_BASE,
        CHANNEL_BUTTON_BOTTOM_BASE + 2,
        TEXT_TILES[" "],
        CHANNEL_BUTTON_BOTTOM_BASE + 4,
        CHANNEL_BUTTON_BOTTOM_BASE + 6,
        TEXT_TILES[" "],
        CHANNEL_BUTTON_BOTTOM_BASE + 8,
        CHANNEL_BUTTON_BOTTOM_BASE + 10,
        TEXT_TILES[" "],
        CHANNEL_BUTTON_BOTTOM_BASE + 12,
        CHANNEL_BUTTON_BOTTOM_BASE + 14,
    ]
    require(top == expected_top, f"{label} button icon top row mismatch: {top}")
    require(bottom == expected_bottom, f"{label} button icon bottom row mismatch: {bottom}")


def require_channel_indicator_muted(pyboy, channel: int, label: str) -> None:
    top, bottom = channel_indicator_channel_tiles(pyboy, channel)
    muted_top = [CHANNEL_MUTE_TOP_BASE, CHANNEL_MUTE_TOP_BASE + 2]
    muted_bottom = [CHANNEL_MUTE_BOTTOM_BASE, CHANNEL_MUTE_BOTTOM_BASE + 2]
    require(top == muted_top, f"{label} top indicator did not show mute icon: {top}")
    require(bottom == muted_bottom, f"{label} bottom indicator did not show mute icon: {bottom}")


def require_channel_indicator_not_muted(pyboy, channel: int, label: str) -> None:
    top, bottom = channel_indicator_channel_tiles(pyboy, channel)
    muted_top = [CHANNEL_MUTE_TOP_BASE, CHANNEL_MUTE_TOP_BASE + 2]
    muted_bottom = [CHANNEL_MUTE_BOTTOM_BASE, CHANNEL_MUTE_BOTTOM_BASE + 2]
    require(top != muted_top, f"{label} top indicator still showed mute icon: {top}")
    require(bottom != muted_bottom, f"{label} bottom indicator still showed mute icon: {bottom}")


def master_volume_nibble(pyboy, addrs: dict[str, int]) -> int:
    return (read_mem(pyboy, addrs["hMasterVol"]) >> 4) & 0x0F


def require_master_volume_display(pyboy, addrs: dict[str, int], label: str) -> int:
    require_vram_text(pyboy, MASTER_VOL_ROW, MASTER_VOL_COL, "MASTER VOL: ", f"{label} master-volume label")
    nibble = master_volume_nibble(pyboy, addrs)
    require_vram_tile(
        pyboy,
        MASTER_VOL_ROW,
        MASTER_VOL_VALUE_COL,
        TEXT_TILES[f"{nibble:X}"],
        f"{label} master-volume value",
    )
    return nibble


def require_album_song_indicator(pyboy, addrs: dict[str, int], song_index: int, label: str) -> None:
    if read_mem(pyboy, addrs["hPlaybackMode"]) != PLAYBACK_MODE_ALBUM:
        return
    song_count = catalog_song_count(addrs)
    require(song_count <= 99, f"{label} album counter cannot display {song_count} songs")
    text = f"SONG {song_index + 1} OF {song_count}"
    require_vram_text(
        pyboy,
        ALBUM_SONG_INDICATOR_ROW,
        ALBUM_SONG_INDICATOR_COL,
        text,
        f"{label} album song indicator",
    )


def read_audio_frame(pyboy) -> np.ndarray | None:
    sound = getattr(pyboy, "sound", None)
    if sound is None:
        return None

    for attr in ("ndarray", "raw_ndarray", "buffer", "raw_buffer"):
        try:
            value = getattr(sound, attr)
        except Exception:
            continue
        if callable(value):
            try:
                value = value()
            except TypeError:
                continue
        if value is None:
            continue
        if isinstance(value, (bytes, bytearray, memoryview)):
            array = np.frombuffer(value, dtype=np.int16)
        else:
            try:
                array = np.asarray(value)
            except Exception:
                continue
        if array.size:
            return array.copy()
    return None


def tick_frames(pyboy, frames: int, collect_audio: bool = False) -> list[np.ndarray]:
    chunks: list[np.ndarray] = []
    for _ in range(frames):
        tick_one(pyboy)
        if collect_audio:
            chunk = read_audio_frame(pyboy)
            if chunk is not None:
                chunks.append(chunk)
    return chunks


def audio_samples(chunks: list[np.ndarray]) -> np.ndarray | None:
    if not chunks:
        return None
    flattened = [np.ravel(chunk) for chunk in chunks if chunk.size]
    if not flattened:
        return None
    data = np.concatenate(flattened)
    if data.dtype.kind == "u":
        midpoint = (np.iinfo(data.dtype).max + 1) / 2.0
        return data.astype(np.float64) - midpoint
    return data.astype(np.float64)


def audio_rms(chunks: list[np.ndarray]) -> float | None:
    samples = audio_samples(chunks)
    if samples is None:
        return None
    return math.sqrt(float(np.mean(samples * samples)))


def audio_activity(chunks: list[np.ndarray]) -> tuple[float, float] | None:
    samples = audio_samples(chunks)
    if samples is None:
        return None
    rms = math.sqrt(float(np.mean(samples * samples)))
    nonzero_ratio = float(np.count_nonzero(samples)) / samples.size
    return rms, nonzero_ratio


def measure_audio_activity(pyboy, frames: int) -> tuple[float, float]:
    activity = audio_activity(tick_frames(pyboy, frames, collect_audio=True))
    if activity is None:
        raise VerifyFailure("PyBoy did not expose audio samples; cannot verify silence")
    return activity


def measure_audio(pyboy, frames: int) -> float:
    rms, _nonzero_ratio = measure_audio_activity(pyboy, frames)
    return rms


def require_silent_audio(pyboy, frames: int, silence_limit: float, label: str) -> tuple[float, float]:
    rms, nonzero_ratio = measure_audio_activity(pyboy, frames)
    require(
        rms <= silence_limit or nonzero_ratio <= SILENCE_NONZERO_RATIO_LIMIT,
        f"{label} RMS {rms:.2f} exceeded limit {silence_limit:.2f} "
        f"with nonzero ratio {nonzero_ratio:.4f}",
    )
    return rms, nonzero_ratio


def track_cursor(pyboy, wtracks: int, track: int) -> tuple[int, int, int, int, int]:
    base = wtracks + track * TRACK_SIZEOF
    pattern_ptr = read_mem(pyboy, base + TRACK_PATTERN_PTR_LO) | (read_mem(pyboy, base + TRACK_PATTERN_PTR_HI) << 8)
    return (
        read_mem(pyboy, base + TRACK_ORDER_POS),
        read_mem(pyboy, base + TRACK_PATTERN_ROW),
        pattern_ptr,
        read_mem(pyboy, base + TRACK_TICK),
        read_mem(pyboy, base + TRACK_SPEED),
    )


def music_cursors(pyboy, wtracks: int) -> tuple[tuple[int, int, int, int, int], ...]:
    return tuple(track_cursor(pyboy, wtracks, track) for track in range(4))


def music_speeds(pyboy, wtracks: int) -> list[int]:
    return [read_mem(pyboy, wtracks + track * TRACK_SIZEOF + TRACK_SPEED) for track in range(4)]


def wait_for_song_ready(
    pyboy,
    hplayback: int,
    hactive_bank: int,
    hshadow_audterm: int,
    wtracks: int,
    expected_bank: int,
    max_frames: int,
) -> tuple[int, list[int]]:
    for frame in range(max_frames + 1):
        speeds = music_speeds(pyboy, wtracks)
        if (
            read_mem(pyboy, hplayback) == 1
            and read_mem(pyboy, hactive_bank) == expected_bank
            and read_mem(pyboy, hshadow_audterm) == 0xFF
            and read_mem(pyboy, NR51) == 0xFF
            and read_mem(pyboy, NR52) & 0x80
            and all(speed != 0xFF for speed in speeds)
        ):
            return frame, speeds
        tick_one(pyboy)

    raise VerifyFailure(
        f"song was not ready within {max_frames} frames; "
        f"playback_active={read_mem(pyboy, hplayback)} "
        f"active_bank={read_mem(pyboy, hactive_bank)} expected_bank={expected_bank} "
        f"shadow_nr51=${read_mem(pyboy, hshadow_audterm):02x} "
        f"nr51=${read_mem(pyboy, NR51):02x} "
        f"nr52=${read_mem(pyboy, NR52):02x} "
        f"speeds={music_speeds(pyboy, wtracks)}; "
        f"increase --boot-frames if startup was intentionally delayed"
    )


def collect_cursor_states(pyboy, wtracks: int, frames: int) -> set[tuple[tuple[int, int, int, int, int], ...]]:
    states = set()
    for frame in range(frames):
        tick_one(pyboy)
        if frame % 5 == 0:
            states.add(music_cursors(pyboy, wtracks))
    return states


def press_button(pyboy, button: str) -> None:
    if hasattr(pyboy, "button_press"):
        pyboy.button_press(button)
        return
    send_window_event(pyboy, button, pressed=True)


def release_button(pyboy, button: str) -> None:
    if hasattr(pyboy, "button_release"):
        pyboy.button_release(button)
        return
    send_window_event(pyboy, button, pressed=False)


def send_window_event(pyboy, button: str, pressed: bool) -> None:
    from pyboy.utils import WindowEvent

    prefix = "PRESS" if pressed else "RELEASE"
    names = [f"{prefix}_BUTTON_{button.upper()}"]
    if button in ("up", "down", "left", "right"):
        names.append(f"{prefix}_ARROW_{button.upper()}")
    for name in names:
        if hasattr(WindowEvent, name):
            pyboy.send_input(getattr(WindowEvent, name))
            return
    raise VerifyFailure(f"PyBoy cannot send button event for {button}")


def tap_button(pyboy, button: str) -> None:
    press_button(pyboy, button)
    tick_frames(pyboy, 4)
    release_button(pyboy, button)
    tick_frames(pyboy, 12)


def tap_menu_button(pyboy, addrs: dict[str, int], button: str, label: str) -> None:
    press_button(pyboy, button)
    tick_frames(pyboy, 4)
    require_menu_change_sfx(pyboy, addrs, label)
    release_button(pyboy, button)
    tick_frames(pyboy, 12)
    drain_menu_change_sfx(pyboy, addrs, label)


def tap_pause_menu_button(pyboy, addrs: dict[str, int], button: str, label: str) -> None:
    press_button(pyboy, button)
    tick_one(pyboy)
    require_menu_change_sfx(pyboy, addrs, label)
    require_menu_sfx_output_queued(pyboy, addrs, label)
    require(read_mem(pyboy, NR51) == 0x00, f"{label} routed paused music before SFX render")
    release_button(pyboy, button)
    wait_for_menu_sfx_output(pyboy, addrs, label)
    tick_frames(pyboy, 16)
    require(read_mem(pyboy, addrs["hMenuSfxFrames"]) == 0, f"{label} menu SFX timer did not expire")
    require(read_mem(pyboy, NR51) == 0x00, f"{label} did not silence paused output after SFX")


def tap_page_button_with_deferred_sfx(pyboy, addrs: dict[str, int], button: str, label: str) -> None:
    press_button(pyboy, button)
    tick_one(pyboy)
    require(
        read_mem(pyboy, addrs["hMainState"]) == MAIN_STATE_SINGLES_MENU_INIT,
        f"{label} did not enter menu redraw state",
    )
    require(read_mem(pyboy, addrs["hPendingMenuChangeSfx"]) != 0, f"{label} did not defer menu SFX")
    require(read_mem(pyboy, addrs["hMenuSfxFrames"]) == 0, f"{label} started SFX before redraw")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_MENU)
    require(read_mem(pyboy, addrs["hPendingMenuChangeSfx"]) == 0, f"{label} left deferred SFX queued")
    require_menu_change_sfx(pyboy, addrs, label)
    require_menu_sfx_output_queued(pyboy, addrs, f"{label} after redraw")
    require(read_mem(pyboy, NR51) == 0x00, f"{label} routed menu-change SFX before render")
    release_button(pyboy, button)
    wait_for_menu_sfx_output(pyboy, addrs, label)
    tick_frames(pyboy, 12)
    drain_menu_change_sfx(pyboy, addrs, label)


def drain_menu_change_sfx(pyboy, addrs: dict[str, int], label: str) -> None:
    if read_mem(pyboy, addrs["hPlaybackActive"]) == 0:
        for _ in range(30):
            if read_mem(pyboy, addrs["hMenuSfxFrames"]) == 0:
                break
            tick_one(pyboy)
        require(read_mem(pyboy, addrs["hMenuSfxFrames"]) == 0, f"{label} menu SFX timer did not expire")
        require(read_mem(pyboy, addrs["hMasterVol"]) == 0, f"{label} left menu audio active")


def verify_channel_toggles(pyboy, addrs: dict[str, int]) -> None:
    mapping = (
        ("up", 0),
        ("down", 1),
        ("left", 2),
        ("right", 3),
    )
    for button, channel in mapping:
        tap_button(pyboy, button)
        require_channel_indicator_muted(pyboy, channel, f"{button} muted channel {channel + 1}")
        tap_button(pyboy, button)
        require_channel_indicator_not_muted(pyboy, channel, f"{button} restored channel {channel + 1}")
        require_channel_indicators(pyboy, f"{button} restored", require_active=False)
    ok("toggles", "up/down/left/right showed mute icons and restored them")


def set_master_volume_for_test(pyboy, addrs: dict[str, int], value: int, label: str) -> None:
    value &= 0xF0
    write_mem(pyboy, addrs["hMasterVol"], value)
    tick_frames(pyboy, 2)
    require(read_mem(pyboy, addrs["hMasterVol"]) == value, f"{label} did not set hMasterVol")
    require_master_volume_display(pyboy, addrs, label)


def verify_master_volume_controls(pyboy, addrs: dict[str, int]) -> None:
    original_active = read_mem(pyboy, addrs["hPlaybackActive"])
    original_volume = read_mem(pyboy, addrs["hMasterVol"])
    write_mem(pyboy, addrs["hPlaybackActive"], 0)
    try:
        set_master_volume_for_test(pyboy, addrs, 0x80, "master setup")
        tap_button(pyboy, "a")
        require(read_mem(pyboy, addrs["hMasterVol"]) == 0x90, "A did not increase hMasterVol")
        require_master_volume_display(pyboy, addrs, "master A")

        tap_button(pyboy, "b")
        require(read_mem(pyboy, addrs["hMasterVol"]) == 0x80, "B did not decrease hMasterVol")
        require_master_volume_display(pyboy, addrs, "master B")

        set_master_volume_for_test(pyboy, addrs, 0xF0, "master max setup")
        tap_button(pyboy, "a")
        require(read_mem(pyboy, addrs["hMasterVol"]) == 0xF0, "A did not saturate hMasterVol at $F0")
        require_master_volume_display(pyboy, addrs, "master max")

        set_master_volume_for_test(pyboy, addrs, 0x00, "master min setup")
        tap_button(pyboy, "b")
        require(read_mem(pyboy, addrs["hMasterVol"]) == 0x00, "B did not saturate hMasterVol at $00")
        require_master_volume_display(pyboy, addrs, "master min")
    finally:
        write_mem(pyboy, addrs["hMasterVol"], original_volume)
        write_mem(pyboy, addrs["hPlaybackActive"], original_active)
        tick_frames(pyboy, 2)
    ok("master volume", "A/B adjusted hMasterVol and updated the Play Mode readout")


def require_no_channel_mutes(pyboy, label: str) -> None:
    for channel in range(4):
        require_channel_indicator_not_muted(pyboy, channel, f"{label} channel {channel + 1}")


def require_lcd_on(pyboy, addrs: dict[str, int], label: str) -> None:
    shadow = read_mem(pyboy, addrs["hShadowLCDC"])
    actual = read_mem(pyboy, LCDC)
    require(shadow & LCDC_ON, f"{label} shadow LCDC is off: ${shadow:02x}")
    require(actual & LCDC_ON, f"{label} LCDC is off: ${actual:02x}")
    require(shadow & LCDC_WINON, f"{label} shadow LCDC window is disabled: ${shadow:02x}")
    require(actual & LCDC_WINON, f"{label} LCDC window is disabled: ${actual:02x}")


def require_window_position(pyboy, addrs: dict[str, int], x: int, y: int, label: str) -> None:
    require(read_mem(pyboy, addrs["hWindowX"]) == x, f"{label} hWindowX mismatch")
    require(read_mem(pyboy, addrs["hWindowY"]) == y, f"{label} hWindowY mismatch")
    require(read_mem(pyboy, WX) == x, f"{label} WX mismatch")
    require(read_mem(pyboy, WY) == y, f"{label} WY mismatch")


def require_window_hidden(pyboy, addrs: dict[str, int], label: str) -> None:
    require_window_position(pyboy, addrs, WINDOW_X_LEFT, WINDOW_Y_HIDDEN, label)


def require_menu_change_sfx(pyboy, addrs: dict[str, int], label: str) -> None:
    frames = read_mem(pyboy, addrs["hMenuSfxFrames"])
    require(frames > 0, f"{label} did not queue menu-change SFX")


def require_menu_sfx_output_queued(pyboy, addrs: dict[str, int], label: str) -> None:
    require(read_mem(pyboy, NR51) == 0x00, f"{label} routed menu-change SFX before render")


def wait_for_menu_sfx_output(pyboy, addrs: dict[str, int], label: str) -> None:
    for _ in range(4):
        tick_one(pyboy)
        if read_mem(pyboy, NR51) == MENU_SFX_OUTPUT_MASK:
            break
    require(read_mem(pyboy, NR51) == MENU_SFX_OUTPUT_MASK, f"{label} did not route menu-change SFX")


def runtime_addresses(symbols: dict[str, int]) -> dict[str, int]:
    return {
        "hShadowLCDC": require_symbol(symbols, "hShadowLCDC"),
        "hWindowX": require_symbol(symbols, "hWindowX"),
        "hWindowY": require_symbol(symbols, "hWindowY"),
        "hMainState": require_symbol(symbols, "hMainState"),
        "hCurrentRootMenuItem": require_symbol(symbols, "hCurrentRootMenuItem"),
        "hPlaybackMode": require_symbol(symbols, "hPlaybackMode"),
        "hCurrentSong": require_symbol(symbols, "hCurrentSong"),
        "hCurrentMenuPage": require_symbol(symbols, "hCurrentMenuPage"),
        "hMenuPageFirstSong": require_symbol(symbols, "hMenuPageFirstSong"),
        "hCurrentPauseMenuItem": require_symbol(symbols, "hCurrentPauseMenuItem"),
        "hActiveSongBank": require_symbol(symbols, "hActiveSongBank"),
        "hPlaybackActive": require_symbol(symbols, "hPlaybackActive"),
        "hSelectedSongDuration": require_symbol(symbols, "hSelectedSongDuration"),
        "hAutoAdvanceFrames": require_symbol(symbols, "hAutoAdvanceFrames"),
        "hShufflePosition": require_symbol(symbols, "hShufflePosition"),
        "hMasterVol": require_symbol(symbols, "hMasterVol"),
        "hPauseMasterVol": require_symbol(symbols, "hPauseMasterVol"),
        "hMenuSfxFrames": require_symbol(symbols, "hMenuSfxFrames"),
        "hPendingMenuChangeSfx": require_symbol(symbols, "hPendingMenuChangeSfx"),
        "hShadowAUDTERM": require_symbol(symbols, "hShadowAUDTERM"),
        "wTracks": require_symbol(symbols, "wTracks"),
        "wShuffleBag": require_symbol(symbols, "wShuffleBag"),
        "SongCatalog": require_symbol(symbols, "SongCatalog"),
        "SongCatalogEnd": require_symbol(symbols, "SongCatalogEnd"),
        "MenuConfig": require_symbol(symbols, "MenuConfig"),
        "SongTitlePointers": require_symbol(symbols, "SongTitlePointers"),
        "GenericVisualizerInit": require_symbol(symbols, "GenericVisualizerInit"),
        "GenericVisualizerUpdate": require_symbol(symbols, "GenericVisualizerUpdate"),
        "GenericVisualizerTeardown": require_symbol(symbols, "GenericVisualizerTeardown"),
    }


def read_word(pyboy, addr: int) -> int:
    return read_mem(pyboy, addr) | (read_mem(pyboy, addr + 1) << 8)


def catalog_banks(pyboy, addrs: dict[str, int]) -> list[int]:
    catalog = addrs["SongCatalog"]
    catalog_end = addrs["SongCatalogEnd"]
    size = catalog_end - catalog
    require(size > 0, "song catalog is empty")
    require(size % SONG_CATALOG_ENTRY_SIZE == 0, f"song catalog size is not a multiple of {SONG_CATALOG_ENTRY_SIZE}: {size}")
    banks = []
    for index in range(size // SONG_CATALOG_ENTRY_SIZE):
        entry = catalog + index * SONG_CATALOG_ENTRY_SIZE
        banks.append(read_mem(pyboy, entry))
        require(read_mem(pyboy, entry + 7) == 0, f"song {index} visualizer bank is not ROM0")
        require(
            read_word(pyboy, entry + 8) == addrs["GenericVisualizerInit"],
            f"song {index} visualizer init is not generic",
        )
        require(
            read_word(pyboy, entry + 10) == addrs["GenericVisualizerUpdate"],
            f"song {index} visualizer update is not generic",
        )
        require(
            read_word(pyboy, entry + 12) == addrs["GenericVisualizerTeardown"],
            f"song {index} visualizer teardown is not generic",
        )
    return banks


def catalog_durations(pyboy, addrs: dict[str, int]) -> list[int]:
    return [
        read_word(pyboy, addrs["SongCatalog"] + index * SONG_CATALOG_ENTRY_SIZE + 1)
        for index in range(catalog_song_count(addrs))
    ]


def catalog_song_count(addrs: dict[str, int]) -> int:
    return (addrs["SongCatalogEnd"] - addrs["SongCatalog"]) // SONG_CATALOG_ENTRY_SIZE


def menu_config(pyboy, addrs: dict[str, int]) -> tuple[int, int]:
    songs_per_page = read_mem(pyboy, addrs["MenuConfig"])
    page_count = read_mem(pyboy, addrs["MenuConfig"] + 1)
    require(songs_per_page > 0, "SONGS_PER_PAGE must be positive")
    require(page_count > 0, "SONG_PAGE_COUNT must be positive")
    return songs_per_page, page_count


def song_title_tiles(pyboy, addrs: dict[str, int], song_index: int) -> list[int]:
    title_ptr = read_word(pyboy, addrs["SongTitlePointers"] + song_index * 2)
    title_len = read_mem(pyboy, title_ptr)
    require(title_len > 0, f"song {song_index} has an empty title")
    return [read_mem(pyboy, title_ptr + 1 + index) for index in range(title_len)]


def require_menu_page(
    pyboy,
    addrs: dict[str, int],
    selected_index: int,
    song_count: int,
    expected_songs_per_page: int | None,
) -> None:
    songs_per_page, page_count = menu_config(pyboy, addrs)
    if expected_songs_per_page is not None:
        require(
            songs_per_page == expected_songs_per_page,
            f"expected SONGS_PER_PAGE={expected_songs_per_page}, got {songs_per_page}",
        )
    expected_page_count = (song_count + songs_per_page - 1) // songs_per_page
    require(page_count == expected_page_count, f"page count mismatch: expected {expected_page_count}, got {page_count}")

    expected_page = selected_index // songs_per_page
    expected_first = expected_page * songs_per_page
    require(read_mem(pyboy, addrs["hCurrentMenuPage"]) == expected_page, "current menu page mismatch")
    require(read_mem(pyboy, addrs["hMenuPageFirstSong"]) == expected_first, "menu page first song mismatch")

    visible_end = min(song_count, expected_first + songs_per_page)
    for song_index in range(expected_first, visible_end):
        visible_row = MENU_FIRST_SONG_ROW + song_index - expected_first
        require_vram_tiles(
            pyboy,
            visible_row,
            MENU_TITLE_COL,
            song_title_tiles(pyboy, addrs, song_index),
            f"song {song_index} visible menu title",
        )
        cursor_tile = TEXT_TILES["*"] if song_index == selected_index else TEXT_TILES[" "]
        require_vram_tile(pyboy, visible_row, MENU_CURSOR_COL, cursor_tile, f"song {song_index} cursor")

    if page_count > 1:
        require_vram_text(
            pyboy,
            MENU_PAGE_INDICATOR_ROW,
            MENU_PAGE_INDICATOR_COL,
            f"PAGE {expected_page + 1} OF {page_count}",
            f"page {expected_page + 1} indicator",
        )
    else:
        require_vram_tile(
            pyboy,
            MENU_PAGE_INDICATOR_ROW,
            MENU_PAGE_INDICATOR_COL,
            TEXT_TILES[" "],
            "single-page indicator",
        )


def wait_for_state(pyboy, addr: int, expected: int, max_frames: int = 60) -> int:
    for frame in range(max_frames + 1):
        if read_mem(pyboy, addr) == expected:
            return frame
        tick_one(pyboy)
    raise VerifyFailure(f"state did not become {expected} within {max_frames} frames; got {read_mem(pyboy, addr)}")


def require_root_menu(pyboy, addrs: dict[str, int], label: str) -> None:
    require(read_mem(pyboy, addrs["hMainState"]) == MAIN_STATE_ROOT_MENU, f"{label} is not in root menu")
    require_lcd_on(pyboy, addrs, label)
    require_window_hidden(pyboy, addrs, label)
    require_vram_text(pyboy, ROOT_TITLE_ROW, 2, "NOTUBE4ME MUSIC", f"{label} title")
    require_vram_text(pyboy, ROOT_HEADING_ROW, 2, "PLAY MODE", f"{label} heading")

    selected = read_mem(pyboy, addrs["hCurrentRootMenuItem"])
    require(0 <= selected < len(ROOT_OPTION_LABELS), f"{label} invalid root option {selected}")
    for index, (row, text) in enumerate(zip(ROOT_OPTION_ROWS, ROOT_OPTION_LABELS)):
        require_vram_text(pyboy, row, ROOT_OPTION_TEXT_COL, text, f"{label} option {text}")
        expected = TEXT_TILES["*"] if index == selected else TEXT_TILES[" "]
        require_vram_tile(pyboy, row, ROOT_CURSOR_COL, expected, f"{label} cursor {text}")


def verify_root_menu(pyboy, addrs: dict[str, int], banks: list[int]) -> None:
    require(len(banks) >= 2, f"expected at least two catalog songs, got {len(banks)}")
    require(read_mem(pyboy, addrs["hPlaybackActive"]) == 0, "root menu boot unexpectedly has active playback")
    require(read_mem(pyboy, addrs["hCurrentRootMenuItem"]) == ROOT_OPTION_ALBUM, "root menu did not select Album")
    require_root_menu(pyboy, addrs, "root menu")
    ok("root menu", f"songs={len(banks)} banks={banks}")


def select_root_option(pyboy, addrs: dict[str, int], target: int) -> None:
    attempts = 0
    while read_mem(pyboy, addrs["hCurrentRootMenuItem"]) != target:
        tap_menu_button(pyboy, addrs, "down", "root menu movement")
        attempts += 1
        require(attempts <= len(ROOT_OPTION_LABELS), f"could not select root option {target}")
    require_root_menu(pyboy, addrs, f"root {ROOT_OPTION_LABELS[target].lower()}")


def enter_singles_menu(pyboy, addrs: dict[str, int], banks: list[int], args: argparse.Namespace) -> None:
    select_root_option(pyboy, addrs, ROOT_OPTION_SINGLES)
    tap_button(pyboy, "a")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_SINGLES_MENU)
    require(read_mem(pyboy, addrs["hPlaybackMode"]) == PLAYBACK_MODE_SINGLES, "SINGLES did not set playback mode")
    require(read_mem(pyboy, addrs["hCurrentSong"]) == 0, "SINGLES did not reset selected song to 0")
    verify_menu(pyboy, addrs, banks, args)


def return_from_singles_to_root(pyboy, addrs: dict[str, int]) -> None:
    require(read_mem(pyboy, addrs["hMainState"]) == MAIN_STATE_SINGLES_MENU, "cannot return to root outside Singles")
    selected_song = read_mem(pyboy, addrs["hCurrentSong"])
    tap_button(pyboy, "b")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_ROOT_MENU)
    require(read_mem(pyboy, addrs["hPlaybackActive"]) == 0, "Singles B-back unexpectedly started playback")
    require(read_mem(pyboy, addrs["hCurrentRootMenuItem"]) == ROOT_OPTION_SINGLES, "Singles B-back did not highlight SINGLES")
    require(read_mem(pyboy, addrs["hCurrentSong"]) == selected_song, "Singles B-back did not preserve selected song")
    require_root_menu(pyboy, addrs, "singles back")
    ok("singles back", "B returned to root menu with SINGLES highlighted")


def verify_menu(pyboy, addrs: dict[str, int], banks: list[int], args: argparse.Namespace) -> None:
    song_count = len(banks)
    require(song_count >= 2, f"expected at least two catalog songs, got {song_count}")
    require(read_mem(pyboy, addrs["hMainState"]) == MAIN_STATE_SINGLES_MENU, "ROM is not in Singles menu")
    require(read_mem(pyboy, addrs["hPlaybackActive"]) == 0, "menu boot unexpectedly has active playback")
    require_lcd_on(pyboy, addrs, "menu")
    require_window_hidden(pyboy, addrs, "menu")
    require_vram_text(pyboy, 1, 2, "NOTUBE4ME MUSIC", "menu title")
    require_vram_text(pyboy, 3, 2, "CHOOSE SONG", "menu heading")
    require_menu_page(
        pyboy,
        addrs,
        read_mem(pyboy, addrs["hCurrentSong"]),
        song_count,
        args.expect_songs_per_page,
    )
    ok("menu", f"songs={len(banks)} selected={read_mem(pyboy, addrs['hCurrentSong'])}")


def verify_page_navigation(pyboy, addrs: dict[str, int], song_count: int, args: argparse.Namespace) -> None:
    songs_per_page, page_count = menu_config(pyboy, addrs)
    start_page = read_mem(pyboy, addrs["hCurrentMenuPage"])
    if args.require_page_turn:
        tap_page_button_with_deferred_sfx(pyboy, addrs, "down", "song-list DOWN")
    else:
        tap_menu_button(pyboy, addrs, "down", "song-list DOWN")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_MENU)
    require(read_mem(pyboy, addrs["hCurrentSong"]) == 1, "DOWN did not select song 1")
    require_menu_page(pyboy, addrs, 1, song_count, args.expect_songs_per_page)
    down_page = read_mem(pyboy, addrs["hCurrentMenuPage"])
    if args.require_page_turn:
        require(down_page != start_page, "DOWN did not move to a different page")

    if args.require_page_turn:
        tap_page_button_with_deferred_sfx(pyboy, addrs, "up", "song-list UP")
    else:
        tap_menu_button(pyboy, addrs, "up", "song-list UP")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_MENU)
    require(read_mem(pyboy, addrs["hCurrentSong"]) == 0, "UP did not select song 0")
    require_menu_page(pyboy, addrs, 0, song_count, args.expect_songs_per_page)
    up_page = read_mem(pyboy, addrs["hCurrentMenuPage"])
    if args.require_page_turn:
        require(up_page == start_page, "UP did not return to the original page")
        ok("paging", "DOWN moved to page 2 and UP returned to page 1")
    else:
        ok("navigation", f"DOWN/UP kept menu coherent on page {up_page + 1}")

    if page_count <= 1:
        return

    tap_page_button_with_deferred_sfx(pyboy, addrs, "right", "song-list RIGHT")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_MENU)
    next_page_song = min(songs_per_page, song_count - 1)
    require(read_mem(pyboy, addrs["hCurrentSong"]) == next_page_song, "RIGHT did not select the next page")
    require_menu_page(pyboy, addrs, next_page_song, song_count, args.expect_songs_per_page)

    tap_page_button_with_deferred_sfx(pyboy, addrs, "left", "song-list LEFT")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_MENU)
    require(read_mem(pyboy, addrs["hCurrentSong"]) == 0, "LEFT did not return to the previous page")
    require_menu_page(pyboy, addrs, 0, song_count, args.expect_songs_per_page)

    tap_page_button_with_deferred_sfx(pyboy, addrs, "left", "song-list LEFT wrap")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_MENU)
    last_page_song = (page_count - 1) * songs_per_page
    require(read_mem(pyboy, addrs["hCurrentSong"]) == last_page_song, "LEFT did not wrap to the last page")
    require_menu_page(pyboy, addrs, last_page_song, song_count, args.expect_songs_per_page)

    tap_page_button_with_deferred_sfx(pyboy, addrs, "right", "song-list RIGHT wrap")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_MENU)
    require(read_mem(pyboy, addrs["hCurrentSong"]) == 0, "RIGHT did not wrap to the first page")
    require_menu_page(pyboy, addrs, 0, song_count, args.expect_songs_per_page)
    ok("page buttons", "LEFT/RIGHT changed pages and wrapped")

    if page_count <= 2 or songs_per_page <= 1:
        return

    for _ in range(songs_per_page - 1):
        tap_menu_button(pyboy, addrs, "down", "song-list row movement")
        wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_MENU)
    row_song = songs_per_page - 1
    require(read_mem(pyboy, addrs["hCurrentSong"]) == row_song, "DOWN did not select last row on page 1")
    require_menu_page(pyboy, addrs, row_song, song_count, args.expect_songs_per_page)

    tap_page_button_with_deferred_sfx(pyboy, addrs, "right", "song-list row preserve")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_MENU)
    same_row_song = min((2 * songs_per_page) - 1, song_count - 1)
    require(read_mem(pyboy, addrs["hCurrentSong"]) == same_row_song, "RIGHT did not preserve row")
    require_menu_page(pyboy, addrs, same_row_song, song_count, args.expect_songs_per_page)

    tap_page_button_with_deferred_sfx(pyboy, addrs, "right", "song-list row clamp")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_MENU)
    clamped_song = song_count - 1
    require(read_mem(pyboy, addrs["hCurrentSong"]) == clamped_song, "RIGHT did not clamp on the last page")
    require_menu_page(pyboy, addrs, clamped_song, song_count, args.expect_songs_per_page)

    tap_page_button_with_deferred_sfx(pyboy, addrs, "right", "song-list row wrap")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_MENU)
    require(read_mem(pyboy, addrs["hCurrentSong"]) == 0, "RIGHT did not return to page 1 after clamp")
    require_menu_page(pyboy, addrs, 0, song_count, args.expect_songs_per_page)
    ok("page row", "RIGHT preserved row and clamped on the short last page")


def select_song(
    pyboy,
    addrs: dict[str, int],
    song_index: int,
    song_count: int,
    args: argparse.Namespace,
) -> None:
    require(song_index < song_count, f"song index {song_index} outside catalog of {song_count}")
    attempts = 0
    while read_mem(pyboy, addrs["hCurrentSong"]) != song_index:
        current = read_mem(pyboy, addrs["hCurrentSong"])
        candidate = (current + 1) % song_count
        first_song = read_mem(pyboy, addrs["hMenuPageFirstSong"])
        songs_per_page, _page_count = menu_config(pyboy, addrs)
        if 0 <= candidate - first_song < songs_per_page:
            tap_menu_button(pyboy, addrs, "down", "song selection movement")
        else:
            tap_page_button_with_deferred_sfx(pyboy, addrs, "down", "song selection movement")
        attempts += 1
        require(attempts <= song_count, f"could not select song {song_index}")
    require_menu_page(pyboy, addrs, song_index, song_count, args.expect_songs_per_page)
    ok("select", f"song_index={song_index}")


def start_selected_song(
    pyboy,
    addrs: dict[str, int],
    song_index: int,
    expected_bank: int,
    args: argparse.Namespace,
    label: str,
) -> list[int]:
    require(read_mem(pyboy, addrs["hMainState"]) == MAIN_STATE_SINGLES_MENU, "cannot start song outside Singles menu")
    require(read_mem(pyboy, addrs["hCurrentSong"]) == song_index, f"expected selected song {song_index}")
    tap_button(pyboy, "a")
    return wait_for_play_song(pyboy, addrs, song_index, expected_bank, args, label)


def wait_for_play_song(
    pyboy,
    addrs: dict[str, int],
    song_index: int,
    expected_bank: int,
    args: argparse.Namespace,
    label: str,
    max_frames: int | None = None,
) -> list[int]:
    if max_frames is None:
        max_frames = args.boot_frames + 60

    for _frame in range(max_frames + 1):
        if (
            read_mem(pyboy, addrs["hMainState"]) == MAIN_STATE_PLAY
            and read_mem(pyboy, addrs["hCurrentSong"]) == song_index
        ):
            break
        tick_one(pyboy)
    else:
        raise VerifyFailure(
            f"{label} did not enter play mode for song {song_index} within {max_frames} frames; "
            f"state={read_mem(pyboy, addrs['hMainState'])} "
            f"song={read_mem(pyboy, addrs['hCurrentSong'])}"
        )

    ready_frame, speeds = wait_for_song_ready(
        pyboy,
        addrs["hPlaybackActive"],
        addrs["hActiveSongBank"],
        addrs["hShadowAUDTERM"],
        addrs["wTracks"],
        expected_bank,
        args.boot_frames,
    )
    warm_frames = 0 if args.require_auto_advance else args.boot_frames
    if ready_frame < warm_frames:
        tick_frames(pyboy, warm_frames - ready_frame)
        speeds = music_speeds(pyboy, addrs["wTracks"])
    require(read_mem(pyboy, addrs["hMainState"]) == MAIN_STATE_PLAY, f"{label} did not enter play mode")
    require_lcd_on(pyboy, addrs, label)
    require_window_hidden(pyboy, addrs, label)
    require_vram_text(pyboy, 1, 2, "NOW PLAYING", f"{label} play heading")
    require_vram_tiles(pyboy, 4, 2, song_title_tiles(pyboy, addrs, song_index), f"{label} play title")
    require_channel_button_icons(pyboy, f"{label} channel buttons")
    require_channel_indicators(pyboy, f"{label} play", require_active=False)
    require_master_volume_display(pyboy, addrs, f"{label} play")
    require_album_song_indicator(pyboy, addrs, song_index, label)
    ok(
        f"{label} start",
        f"song_index={song_index} ready_frame={ready_frame} warmed_frames={warm_frames} "
        f"bank={expected_bank} speeds={speeds}",
    )
    return speeds


def verify_song_advances(pyboy, addrs: dict[str, int], args: argparse.Namespace, label: str) -> float:
    states = collect_cursor_states(pyboy, addrs["wTracks"], args.advance_frames)
    require(
        len(states) >= args.min_cursor_states,
        f"{label} cursor did not advance enough: {len(states)} distinct states",
    )
    ok(f"{label} advance", f"{len(states)} distinct cursor states over {args.advance_frames} frames")

    playing_rms = measure_audio(pyboy, args.audio_frames)
    require(playing_rms > 0.0, f"{label} playing audio RMS was zero")
    require_channel_indicators(pyboy, label, require_active=False)
    ok(f"{label} audio", f"playing rms={playing_rms:.2f}")
    return playing_rms


def enter_pause(
    pyboy,
    addrs: dict[str, int],
    playing_rms: float,
    args: argparse.Namespace,
    label: str,
    require_active_indicators: bool = True,
) -> float:
    paused_master_volume = read_mem(pyboy, addrs["hMasterVol"])
    tap_button(pyboy, "start")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_PAUSE)
    require(
        read_mem(pyboy, addrs["hPauseMasterVol"]) == paused_master_volume,
        f"{label} pause did not save hMasterVol",
    )
    require(read_mem(pyboy, addrs["hCurrentPauseMenuItem"]) == 0, "pause menu did not default to Resume")
    require_lcd_on(pyboy, addrs, f"{label} pause")
    require_window_position(pyboy, addrs, WINDOW_X_LEFT, WINDOW_Y_PAUSE, f"{label} pause")
    require_vram_text(pyboy, 1, 2, "NOW PLAYING", f"{label} pause keeps play background")
    require_channel_indicators(pyboy, f"{label} pause", require_active=require_active_indicators)
    require_vram_text(pyboy, 0, PAUSE_HEADING_COL, "PAUSED", f"{label} pause heading", WINDOW_MAP)
    require_vram_text(pyboy, 1, PAUSE_OPTION_TEXT_COL, "RESUME", f"{label} resume option", WINDOW_MAP)
    require_vram_text(pyboy, 2, PAUSE_OPTION_TEXT_COL, "RESTART", f"{label} restart option", WINDOW_MAP)
    require_vram_text(pyboy, 3, PAUSE_OPTION_TEXT_COL, "PREV SONG", f"{label} prev option", WINDOW_MAP)
    require_vram_text(pyboy, 4, PAUSE_OPTION_TEXT_COL, "NEXT SONG", f"{label} next option", WINDOW_MAP)
    require_vram_text(pyboy, 5, PAUSE_OPTION_TEXT_COL, "QUIT", f"{label} quit option", WINDOW_MAP)
    require_vram_tile(pyboy, 1, PAUSE_CURSOR_COL, TEXT_TILES["*"], f"{label} pause cursor", WINDOW_MAP)
    require(read_mem(pyboy, NR51) == 0x00, f"{label} pause did not disconnect NR51 output")
    require(read_mem(pyboy, addrs["hShadowAUDTERM"]) != 0x00, f"{label} pause corrupted NR51 shadow state")
    paused_cursor = music_cursors(pyboy, addrs["wTracks"])
    tick_frames(pyboy, AUDIO_SETTLE_FRAMES)
    silence_limit = max(0.1, playing_rms * 0.05)
    pause_rms, nonzero_ratio = require_silent_audio(pyboy, args.audio_frames, silence_limit, f"{label} pause")
    require(music_cursors(pyboy, addrs["wTracks"]) == paused_cursor, f"{label} cursor advanced while paused")
    ok(
        f"{label} pause",
        f"menu_item={read_mem(pyboy, addrs['hCurrentPauseMenuItem'])} "
        f"nr51=${read_mem(pyboy, NR51):02x} rms={pause_rms:.2f} nz={nonzero_ratio:.4f}",
    )
    return silence_limit


def select_pause_option(pyboy, addrs: dict[str, int], target: int, label: str) -> None:
    attempts = 0
    while read_mem(pyboy, addrs["hCurrentPauseMenuItem"]) != target:
        tap_pause_menu_button(pyboy, addrs, "down", f"{label} pause movement")
        attempts += 1
        require(attempts <= PAUSE_OPTION_QUIT, f"{label} could not select pause option {target}")
    require_vram_tile(
        pyboy,
        PAUSE_OPTION_ROWS[target],
        PAUSE_CURSOR_COL,
        TEXT_TILES["*"],
        f"{label} pause cursor",
        WINDOW_MAP,
    )


def resume_from_pause(pyboy, addrs: dict[str, int], silence_limit: float, args: argparse.Namespace, label: str) -> None:
    paused_master_volume = read_mem(pyboy, addrs["hPauseMasterVol"])
    tap_button(pyboy, "a")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_PLAY)
    require(read_mem(pyboy, NR51) == read_mem(pyboy, addrs["hShadowAUDTERM"]), f"{label} resume did not restore NR51")
    require(read_mem(pyboy, addrs["hMasterVol"]) == paused_master_volume, f"{label} resume did not restore hMasterVol")
    require_window_hidden(pyboy, addrs, f"{label} resume")
    require_vram_text(pyboy, 1, 2, "NOW PLAYING", f"{label} resumed play heading")
    resume_states = collect_cursor_states(pyboy, addrs["wTracks"], args.audio_frames)
    require(len(resume_states) > 1, f"{label} cursor did not advance after resume")
    resume_rms = measure_audio(pyboy, args.audio_frames)
    require(resume_rms > silence_limit, f"{label} resume RMS {resume_rms:.2f} did not exceed limit {silence_limit:.2f}")
    ok(f"{label} resume", f"nr51=${read_mem(pyboy, NR51):02x} rms={resume_rms:.2f}")


def cancel_pause_with_b(pyboy, addrs: dict[str, int], silence_limit: float, args: argparse.Namespace, label: str) -> None:
    select_pause_option(pyboy, addrs, PAUSE_OPTION_QUIT, f"{label} quit before B cancel")
    paused_master_volume = read_mem(pyboy, addrs["hPauseMasterVol"])
    tap_button(pyboy, "b")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_PLAY)
    require(read_mem(pyboy, NR51) == read_mem(pyboy, addrs["hShadowAUDTERM"]), f"{label} B cancel did not restore NR51")
    require(read_mem(pyboy, addrs["hMasterVol"]) == paused_master_volume, f"{label} B cancel did not restore hMasterVol")
    require_window_hidden(pyboy, addrs, f"{label} B cancel")
    require_vram_text(pyboy, 1, 2, "NOW PLAYING", f"{label} B cancel play heading")
    resume_states = collect_cursor_states(pyboy, addrs["wTracks"], args.audio_frames)
    require(len(resume_states) > 1, f"{label} cursor did not advance after B cancel")
    resume_rms = measure_audio(pyboy, args.audio_frames)
    require(resume_rms > silence_limit, f"{label} B cancel RMS {resume_rms:.2f} did not exceed limit {silence_limit:.2f}")
    ok(f"{label} B cancel", f"nr51=${read_mem(pyboy, NR51):02x} rms={resume_rms:.2f}")


def restart_from_pause(
    pyboy,
    addrs: dict[str, int],
    song_index: int,
    expected_bank: int,
    args: argparse.Namespace,
    label: str,
) -> None:
    select_pause_option(pyboy, addrs, PAUSE_OPTION_RESTART, f"{label} restart")
    tap_button(pyboy, "a")
    ready_frame, speeds = wait_for_song_ready(
        pyboy,
        addrs["hPlaybackActive"],
        addrs["hActiveSongBank"],
        addrs["hShadowAUDTERM"],
        addrs["wTracks"],
        expected_bank,
        args.boot_frames,
    )
    require(read_mem(pyboy, addrs["hMainState"]) == MAIN_STATE_PLAY, f"{label} restart did not return to play mode")
    require(read_mem(pyboy, addrs["hCurrentSong"]) == song_index, f"{label} restart changed selected song")
    ok(f"{label} restart", f"ready_frame={ready_frame} bank={expected_bank} speeds={speeds}")


def quit_from_pause(
    pyboy,
    addrs: dict[str, int],
    silence_limit: float,
    args: argparse.Namespace,
    label: str,
    expected_state: int = MAIN_STATE_SINGLES_MENU,
) -> None:
    selected_song = read_mem(pyboy, addrs["hCurrentSong"])
    select_pause_option(pyboy, addrs, PAUSE_OPTION_QUIT, f"{label} quit")
    tap_button(pyboy, "a")
    wait_for_state(pyboy, addrs["hMainState"], expected_state)
    require(read_mem(pyboy, addrs["hPlaybackActive"]) == 0, f"{label} quit did not clear playback-active state")
    require_lcd_on(pyboy, addrs, f"{label} quit menu")
    require_window_hidden(pyboy, addrs, f"{label} quit menu")
    if expected_state == MAIN_STATE_ROOT_MENU:
        require_root_menu(pyboy, addrs, f"{label} quit root")
    else:
        require(read_mem(pyboy, addrs["hCurrentSong"]) == selected_song, f"{label} quit reset selected song")
        require_vram_text(pyboy, 1, 2, "NOTUBE4ME MUSIC", f"{label} quit menu title")
        require_vram_text(pyboy, 3, 2, "CHOOSE SONG", f"{label} quit menu heading")
        require_menu_page(
            pyboy,
            addrs,
            read_mem(pyboy, addrs["hCurrentSong"]),
            catalog_song_count(addrs),
            args.expect_songs_per_page,
        )
    tick_frames(pyboy, 30)
    quit_rms, nonzero_ratio = require_silent_audio(pyboy, args.audio_frames, silence_limit, f"{label} quit")
    ok(
        f"{label} quit",
        f"playback_active={read_mem(pyboy, addrs['hPlaybackActive'])} rms={quit_rms:.2f} nz={nonzero_ratio:.4f}",
    )


def verify_song_session(
    pyboy,
    addrs: dict[str, int],
    song_index: int,
    expected_bank: int,
    args: argparse.Namespace,
) -> None:
    label = f"song{song_index}"
    start_selected_song(pyboy, addrs, song_index, expected_bank, args, label)
    verify_master_volume_controls(pyboy, addrs)
    playing_rms = verify_song_advances(pyboy, addrs, args, label)
    verify_channel_toggles(pyboy, addrs)

    set_master_volume_for_test(pyboy, addrs, 0x80, f"{label} pause master setup")
    silence_limit = enter_pause(pyboy, addrs, playing_rms, args, label)
    resume_from_pause(pyboy, addrs, silence_limit, args, label)
    set_master_volume_for_test(pyboy, addrs, 0xF0, f"{label} pause master restore")

    silence_limit = enter_pause(pyboy, addrs, playing_rms, args, label)
    cancel_pause_with_b(pyboy, addrs, silence_limit, args, label)

    silence_limit = enter_pause(pyboy, addrs, playing_rms, args, label)
    restart_from_pause(pyboy, addrs, song_index, expected_bank, args, label)
    verify_song_advances(pyboy, addrs, args, f"{label} restarted")

    silence_limit = enter_pause(pyboy, addrs, playing_rms, args, label)
    quit_from_pause(pyboy, addrs, silence_limit, args, label)


def verify_song_smoke(
    pyboy,
    addrs: dict[str, int],
    song_index: int,
    expected_bank: int,
    args: argparse.Namespace,
    song_count: int,
) -> None:
    label = f"song{song_index}"
    select_song(pyboy, addrs, song_index, song_count, args)
    start_selected_song(pyboy, addrs, song_index, expected_bank, args, label)
    playing_rms = verify_song_advances(pyboy, addrs, args, label)
    silence_limit = enter_pause(pyboy, addrs, playing_rms, args, label)
    quit_from_pause(pyboy, addrs, silence_limit, args, label)


def verify_reverse_switch_and_mute_reset(
    pyboy,
    addrs: dict[str, int],
    banks: list[int],
    args: argparse.Namespace,
) -> None:
    select_song(pyboy, addrs, 1, len(banks), args)
    start_selected_song(pyboy, addrs, 1, banks[1], args, "stale source song1")
    require_no_channel_mutes(pyboy, "stale source song1")

    playing_rms = measure_audio(pyboy, args.audio_frames)
    require(playing_rms > 0.0, "stale source song1 playing audio RMS was zero")

    tap_button(pyboy, "up")
    require_channel_indicator_muted(pyboy, 0, "stale source song1 muted channel 1")
    ok("stale setup", "song1 ch1 muted")

    silence_limit = enter_pause(pyboy, addrs, playing_rms, args, "stale source song1")
    quit_from_pause(pyboy, addrs, silence_limit, args, "stale source song1")

    select_song(pyboy, addrs, 0, len(banks), args)
    start_selected_song(pyboy, addrs, 0, banks[0], args, "reverse song0")
    require_no_channel_mutes(pyboy, "reverse song0")
    ok("reverse switch", f"song1->song0 bank={banks[0]} mute_bits=$00")
    verify_song_advances(pyboy, addrs, args, "reverse song0")


def read_shuffle_bag(pyboy, addrs: dict[str, int], song_count: int) -> list[int]:
    return [read_mem(pyboy, addrs["wShuffleBag"] + index) for index in range(song_count)]


def require_shuffle_bag(pyboy, addrs: dict[str, int], song_count: int, label: str) -> list[int]:
    bag = read_shuffle_bag(pyboy, addrs, song_count)
    require(sorted(bag) == list(range(song_count)), f"{label} shuffle bag is not a permutation: {bag}")
    return bag


def quick_playing_rms(pyboy) -> float:
    return max(measure_audio(pyboy, 10), 0.1)


def choose_pause_song_option(
    pyboy,
    addrs: dict[str, int],
    banks: list[int],
    args: argparse.Namespace,
    option: int,
    expected_song: int,
    label: str,
    max_frames: int,
) -> None:
    select_pause_option(pyboy, addrs, option, label)
    tap_button(pyboy, "a")
    wait_for_play_song(pyboy, addrs, expected_song, banks[expected_song], args, label, max_frames)


def verify_album_mode(
    pyboy,
    addrs: dict[str, int],
    banks: list[int],
    durations: list[int],
    args: argparse.Namespace,
) -> None:
    select_root_option(pyboy, addrs, ROOT_OPTION_ALBUM)
    tap_button(pyboy, "a")
    wait_for_play_song(pyboy, addrs, 0, banks[0], args, "album song0")
    require(read_mem(pyboy, addrs["hPlaybackMode"]) == PLAYBACK_MODE_ALBUM, "Album did not set playback mode")
    require(read_word(pyboy, addrs["hSelectedSongDuration"]) == durations[0], "Album did not load song duration")
    require(read_word(pyboy, addrs["hAutoAdvanceFrames"]) > 0, "Album countdown was not initialized")

    wait_for_play_song(
        pyboy,
        addrs,
        1,
        banks[1],
        args,
        "album auto song1",
        durations[0] + args.boot_frames + 120,
    )
    require(read_mem(pyboy, addrs["hPlaybackMode"]) == PLAYBACK_MODE_ALBUM, "Album mode did not persist")

    silence_limit = enter_pause(
        pyboy,
        addrs,
        quick_playing_rms(pyboy),
        args,
        "album song1",
        require_active_indicators=False,
    )
    choose_pause_song_option(
        pyboy,
        addrs,
        banks,
        args,
        PAUSE_OPTION_PREV,
        0,
        "album prev",
        args.boot_frames + 120,
    )

    silence_limit = enter_pause(
        pyboy,
        addrs,
        quick_playing_rms(pyboy),
        args,
        "album song0",
        require_active_indicators=False,
    )
    choose_pause_song_option(
        pyboy,
        addrs,
        banks,
        args,
        PAUSE_OPTION_NEXT,
        1,
        "album next",
        args.boot_frames + 120,
    )

    silence_limit = enter_pause(
        pyboy,
        addrs,
        quick_playing_rms(pyboy),
        args,
        "album quit",
        require_active_indicators=False,
    )
    quit_from_pause(pyboy, addrs, silence_limit, args, "album", MAIN_STATE_ROOT_MENU)
    require(read_mem(pyboy, addrs["hCurrentSong"]) == 1, "Album quit did not leave a nonzero song index for bleed test")
    enter_singles_menu(pyboy, addrs, banks, args)
    return_from_singles_to_root(pyboy, addrs)
    ok("album mode", "auto-advanced, pause prev/next worked, and Quit returned to root")


def verify_shuffle_mode(
    pyboy,
    addrs: dict[str, int],
    banks: list[int],
    durations: list[int],
    args: argparse.Namespace,
) -> None:
    song_count = len(banks)
    require(song_count >= 2, "Shuffle verification requires at least two songs")
    select_root_option(pyboy, addrs, ROOT_OPTION_SHUFFLE)
    tap_button(pyboy, "a")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_PLAY, args.boot_frames + 120)
    first_song = read_mem(pyboy, addrs["hCurrentSong"])
    wait_for_play_song(pyboy, addrs, first_song, banks[first_song], args, "shuffle first")
    require(read_mem(pyboy, addrs["hPlaybackMode"]) == PLAYBACK_MODE_SHUFFLE, "Shuffle did not set playback mode")
    require(read_mem(pyboy, addrs["hShufflePosition"]) == 0, "Shuffle did not start at bag position 0")
    bag = require_shuffle_bag(pyboy, addrs, song_count, "shuffle start")
    # PyBoy makes this bag deterministic, but derive expectations from the bag
    # so PRNG or frame-timing changes only change the trace, not the test shape.
    require(first_song == bag[0], f"Shuffle current song {first_song} did not match bag[0] {bag[0]}")

    second_song = bag[1]
    wait_for_play_song(
        pyboy,
        addrs,
        second_song,
        banks[second_song],
        args,
        "shuffle auto second",
        durations[first_song] + args.boot_frames + 120,
    )
    require(read_mem(pyboy, addrs["hShufflePosition"]) == 1, "Shuffle auto-advance did not move to bag position 1")

    silence_limit = enter_pause(
        pyboy,
        addrs,
        quick_playing_rms(pyboy),
        args,
        "shuffle second",
        require_active_indicators=False,
    )
    choose_pause_song_option(
        pyboy,
        addrs,
        banks,
        args,
        PAUSE_OPTION_PREV,
        first_song,
        "shuffle prev",
        args.boot_frames + 120,
    )
    require(read_mem(pyboy, addrs["hShufflePosition"]) == 0, "Shuffle PREV did not return to bag position 0")

    silence_limit = enter_pause(
        pyboy,
        addrs,
        quick_playing_rms(pyboy),
        args,
        "shuffle first",
        require_active_indicators=False,
    )
    last_song = bag[-1]
    choose_pause_song_option(
        pyboy,
        addrs,
        banks,
        args,
        PAUSE_OPTION_PREV,
        last_song,
        "shuffle prev wrap",
        args.boot_frames + 120,
    )
    require(
        read_mem(pyboy, addrs["hShufflePosition"]) == song_count - 1,
        "Shuffle PREV from bag start did not wrap to the current bag's last entry",
    )

    silence_limit = enter_pause(
        pyboy,
        addrs,
        quick_playing_rms(pyboy),
        args,
        "shuffle last",
        require_active_indicators=False,
    )
    select_pause_option(pyboy, addrs, PAUSE_OPTION_NEXT, "shuffle next refill")
    tap_button(pyboy, "a")
    wait_for_state(pyboy, addrs["hMainState"], MAIN_STATE_PLAY, args.boot_frames + 120)
    new_first_song = read_mem(pyboy, addrs["hCurrentSong"])
    new_bag = require_shuffle_bag(pyboy, addrs, song_count, "shuffle refill")
    require(read_mem(pyboy, addrs["hShufflePosition"]) == 0, "Shuffle refill did not reset bag position")
    require(new_first_song == new_bag[0], "Shuffle refill current song did not match new bag[0]")
    require(new_first_song != last_song, "Shuffle refill immediately repeated the last song")
    wait_for_play_song(pyboy, addrs, new_first_song, banks[new_first_song], args, "shuffle refill")

    silence_limit = enter_pause(
        pyboy,
        addrs,
        quick_playing_rms(pyboy),
        args,
        "shuffle quit",
        require_active_indicators=False,
    )
    quit_from_pause(pyboy, addrs, silence_limit, args, "shuffle", MAIN_STATE_ROOT_MENU)
    ok("shuffle mode", "bag auto-advance, prev wrap, refill, and Quit returned to root")


def verify_auto_modes(pyboy, addrs: dict[str, int], banks: list[int], args: argparse.Namespace) -> None:
    durations = catalog_durations(pyboy, addrs)
    require(all(duration == 60 for duration in durations), "auto fixture must use 1-second song durations")
    require_root_menu(pyboy, addrs, "auto root")
    verify_album_mode(pyboy, addrs, banks, durations, args)
    verify_shuffle_mode(pyboy, addrs, banks, durations, args)


def verify_playback(rom_path: Path, symbols: dict[str, int], args: argparse.Namespace) -> None:
    addrs = runtime_addresses(symbols)

    pyboy = make_pyboy(rom_path)
    try:
        tick_frames(pyboy, args.boot_frames)
        banks = catalog_banks(pyboy, addrs)
        verify_root_menu(pyboy, addrs, banks)
        if args.require_auto_advance:
            verify_auto_modes(pyboy, addrs, banks, args)
            return

        enter_singles_menu(pyboy, addrs, banks, args)
        verify_page_navigation(pyboy, addrs, len(banks), args)
        return_from_singles_to_root(pyboy, addrs)
        enter_singles_menu(pyboy, addrs, banks, args)

        verify_song_session(pyboy, addrs, 0, banks[0], args)
        select_song(pyboy, addrs, 1, len(banks), args)
        verify_song_session(pyboy, addrs, 1, banks[1], args)
        for song_index, bank in enumerate(banks[2:], start=2):
            verify_song_smoke(pyboy, addrs, song_index, bank, args, len(banks))
        verify_reverse_switch_and_mute_reset(pyboy, addrs, banks, args)
    finally:
        stop_pyboy(pyboy)


def read_apu_regs(pyboy) -> dict[int, int]:
    return {addr: read_mem(pyboy, addr) for addr in APU_REGS}


def channel_frequency(regs: dict[int, int], channel: int) -> int:
    if channel == 0:
        return regs[0xFF13] | ((regs[0xFF14] & 0x07) << 8)
    if channel == 1:
        return regs[0xFF18] | ((regs[0xFF19] & 0x07) << 8)
    if channel == 2:
        return regs[0xFF1D] | ((regs[0xFF1E] & 0x07) << 8)
    if channel == 3:
        return regs[0xFF22]
    raise ValueError(f"invalid channel: {channel}")


def collect_running_apu_stats(pyboy, frames: int) -> dict[str, object]:
    require(frames > 0, "--diff-frames must be positive")
    nr52_active_counts = [0, 0, 0, 0]
    change_counts = [0, 0, 0, 0]
    previous_states = [None, None, None, None]
    channel_states = [set(), set(), set(), set()]
    frequencies = [set(), set(), set(), set()]
    apu_states = set()
    audio_chunks: list[np.ndarray] = []

    for _ in range(frames):
        tick_one(pyboy)
        regs = read_apu_regs(pyboy)
        apu_states.add(tuple(regs[addr] for addr in APU_REGS))

        for channel in range(4):
            state = tuple(regs[addr] for addr in CHANNEL_REGS[channel])
            channel_states[channel].add(state)
            if previous_states[channel] is not None and state != previous_states[channel]:
                change_counts[channel] += 1
            previous_states[channel] = state
            frequencies[channel].add(channel_frequency(regs, channel))
            if regs[NR52] & (1 << channel):
                nr52_active_counts[channel] += 1

        chunk = read_audio_frame(pyboy)
        if chunk is not None:
            audio_chunks.append(chunk)

    return {
        "change_pct": [count / frames for count in change_counts],
        "channel_state_counts": [len(values) for values in channel_states],
        "frequency_counts": [len(values) for values in frequencies],
        "nr52_active_pct": [count / frames for count in nr52_active_counts],
        "apu_state_count": len(apu_states),
        "rms": audio_rms(audio_chunks),
    }


def collect_standalone_apu_stats(rom_path: Path, warmup_frames: int, frames: int) -> dict[str, object]:
    pyboy = make_pyboy(rom_path)
    try:
        tick_frames(pyboy, warmup_frames)
        return collect_running_apu_stats(pyboy, frames)
    finally:
        stop_pyboy(pyboy)


def collect_compilation_apu_stats(
    rom_path: Path,
    symbols: dict[str, int],
    song_index: int,
    warmup_frames: int,
    frames: int,
    args: argparse.Namespace,
) -> dict[str, object]:
    addrs = runtime_addresses(symbols)
    pyboy = make_pyboy(rom_path)
    try:
        tick_frames(pyboy, args.boot_frames)
        banks = catalog_banks(pyboy, addrs)
        require(0 <= song_index < len(banks), f"diff song index out of range: {song_index}")
        verify_root_menu(pyboy, addrs, banks)
        enter_singles_menu(pyboy, addrs, banks, args)
        select_song(pyboy, addrs, song_index, len(banks), args)
        start_selected_song(pyboy, addrs, song_index, banks[song_index], args, f"diff song{song_index}")
        tick_frames(pyboy, warmup_frames)
        return collect_running_apu_stats(pyboy, frames)
    finally:
        stop_pyboy(pyboy)


def compare_channel_stats(
    compiled: dict[str, object],
    reference: dict[str, object],
    args: argparse.Namespace,
) -> None:
    failures: list[str] = []
    compiled_changes = compiled["change_pct"]
    reference_changes = reference["change_pct"]
    compiled_states = compiled["channel_state_counts"]
    reference_states = reference["channel_state_counts"]
    compiled_frequencies = compiled["frequency_counts"]
    reference_frequencies = reference["frequency_counts"]

    assert isinstance(compiled_changes, list)
    assert isinstance(reference_changes, list)
    assert isinstance(compiled_states, list)
    assert isinstance(reference_states, list)
    assert isinstance(compiled_frequencies, list)
    assert isinstance(reference_frequencies, list)

    for channel, name in enumerate(CHANNEL_NAMES):
        change_delta = abs(compiled_changes[channel] - reference_changes[channel])
        if change_delta > args.diff_change_tolerance:
            failures.append(
                f"{name} register-change delta {change_delta:.1%} exceeds {args.diff_change_tolerance:.1%} "
                f"(compiled {compiled_changes[channel]:.1%}, reference {reference_changes[channel]:.1%})"
            )

        count_delta = abs(compiled_states[channel] - reference_states[channel])
        count_limit = max(
            args.diff_count_tolerance,
            math.ceil(max(compiled_states[channel], reference_states[channel]) * args.diff_count_ratio_tolerance),
        )
        if count_delta > count_limit:
            failures.append(
                f"{name} state-count delta {count_delta} exceeds {count_limit} "
                f"(compiled {compiled_states[channel]}, reference {reference_states[channel]})"
            )

        frequency_delta = abs(compiled_frequencies[channel] - reference_frequencies[channel])
        frequency_limit = max(
            args.diff_count_tolerance,
            math.ceil(
                max(compiled_frequencies[channel], reference_frequencies[channel])
                * args.diff_count_ratio_tolerance
            ),
        )
        if frequency_delta > frequency_limit:
            failures.append(
                f"{name} frequency-count delta {frequency_delta} exceeds {frequency_limit} "
                f"(compiled {compiled_frequencies[channel]}, reference {reference_frequencies[channel]})"
            )

    compiled_rms = compiled["rms"]
    reference_rms = reference["rms"]
    if compiled_rms is not None and reference_rms is not None:
        assert isinstance(compiled_rms, float)
        assert isinstance(reference_rms, float)
        if compiled_rms <= 0.0 or reference_rms <= 0.0:
            failures.append(f"audio RMS must be nonzero (compiled {compiled_rms:.2f}, reference {reference_rms:.2f})")
        else:
            rms_ratio = min(compiled_rms, reference_rms) / max(compiled_rms, reference_rms)
            if rms_ratio < args.diff_rms_ratio_min:
                failures.append(
                    f"audio RMS ratio {rms_ratio:.2f} below {args.diff_rms_ratio_min:.2f} "
                    f"(compiled {compiled_rms:.2f}, reference {reference_rms:.2f})"
                )

    if failures:
        raise VerifyFailure("aggregate APU comparison failed: " + "; ".join(failures))


def format_stats(stats: dict[str, object]) -> str:
    changes = stats["change_pct"]
    states = stats["channel_state_counts"]
    frequencies = stats["frequency_counts"]
    nr52_active = stats["nr52_active_pct"]
    assert isinstance(changes, list)
    assert isinstance(states, list)
    assert isinstance(frequencies, list)
    assert isinstance(nr52_active, list)
    channels = ", ".join(
        f"{name} changes={changes[index]:.1%} states={states[index]} "
        f"freq={frequencies[index]} nr52={nr52_active[index]:.1%}"
        for index, name in enumerate(CHANNEL_NAMES)
    )
    rms = stats["rms"]
    rms_text = "n/a" if rms is None else f"{rms:.2f}"
    return f"{channels}; apu_states={stats['apu_state_count']} rms={rms_text}"


def verify_diff(rom_path: Path, reference_path: Path, symbols: dict[str, int], args: argparse.Namespace) -> None:
    compiled = collect_compilation_apu_stats(
        rom_path,
        symbols,
        args.diff_song_index,
        args.diff_warmup_frames,
        args.diff_frames,
        args,
    )
    reference = collect_standalone_apu_stats(reference_path, args.diff_warmup_frames, args.diff_frames)
    compare_channel_stats(compiled, reference, args)
    ok("diff compiled", format_stats(compiled))
    ok("diff reference", format_stats(reference))


def verify_standalone_diff(rom_path: Path, reference_path: Path, args: argparse.Namespace) -> None:
    compare_standalone_track_speeds(rom_path, reference_path, args)
    current = collect_standalone_apu_stats(rom_path, args.diff_warmup_frames, args.diff_frames)
    reference = collect_standalone_apu_stats(reference_path, args.diff_warmup_frames, args.diff_frames)
    compare_channel_stats(current, reference, args)
    ok("diff current", format_stats(current))
    ok("diff reference", format_stats(reference))


def standalone_wtracks(sym_path: Path) -> int | None:
    if not sym_path.exists():
        return None
    symbols = parse_sym(sym_path)
    return symbols.get("wTracks")


def standalone_track_speeds(rom_path: Path, wtracks: int, warmup_frames: int) -> list[int]:
    pyboy = make_pyboy(rom_path)
    try:
        tick_frames(pyboy, warmup_frames)
        return music_speeds(pyboy, wtracks)
    finally:
        stop_pyboy(pyboy)


def compare_standalone_track_speeds(
    rom_path: Path,
    reference_path: Path,
    args: argparse.Namespace,
) -> None:
    current_sym = args.standalone_sym or rom_path.with_suffix(".sym")
    reference_sym = args.standalone_reference_sym or reference_path.with_suffix(".sym")
    current_wtracks = standalone_wtracks(current_sym)
    reference_wtracks = standalone_wtracks(reference_sym)

    if current_wtracks is None or reference_wtracks is None:
        ok("diff tracks", "skipped; wTracks symbols unavailable")
        return

    current_speeds = standalone_track_speeds(rom_path, current_wtracks, args.diff_warmup_frames)
    reference_speeds = standalone_track_speeds(
        reference_path,
        reference_wtracks,
        args.diff_warmup_frames,
    )
    require(
        current_speeds == reference_speeds,
        f"track speed mismatch: current {current_speeds}, reference {reference_speeds}",
    )
    ok("diff tracks", f"speeds={current_speeds}")


def main() -> int:
    args = parse_args()
    rom_path = args.rom
    sym_path = args.sym or rom_path.with_suffix(".sym")

    try:
        require(rom_path.exists(), f"ROM not found: {rom_path}")
        if args.standalone_diff:
            require(args.diff is not None, "--standalone-diff requires --diff")
            require(args.diff.exists(), f"standalone ROM not found: {args.diff}")
            verify_standalone_diff(rom_path, args.diff, args)
            return 0

        require(sym_path.exists(), f"symbol file not found: {sym_path}")
        check_header(rom_path)
        symbols = parse_sym(sym_path)
        if args.diff_only:
            require(args.diff is not None, "--diff-only requires --diff")
        else:
            verify_playback(rom_path, symbols, args)
        if args.diff is not None:
            require(args.diff.exists(), f"standalone ROM not found: {args.diff}")
            verify_diff(rom_path, args.diff, symbols, args)
    except VerifyFailure as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

    print("verification passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
