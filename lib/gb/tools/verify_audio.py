#!/usr/bin/env python3
"""Compare aggregate APU behavior between two standalone Game Boy ROMs."""

from __future__ import annotations

import argparse
import math
import re
import sys
import warnings
from pathlib import Path

import numpy as np


APU_REGS = tuple(range(0xFF10, 0xFF27))
NR52 = 0xFF26
CHANNEL_NAMES = ("ch1", "ch2", "ch3", "ch4")
CHANNEL_REGS = (
    (0xFF10, 0xFF11, 0xFF12, 0xFF13, 0xFF14),
    (0xFF16, 0xFF17, 0xFF18, 0xFF19),
    (0xFF1A, 0xFF1B, 0xFF1C, 0xFF1D, 0xFF1E),
    (0xFF20, 0xFF21, 0xFF22, 0xFF23),
)

TRACK_SIZEOF = 0x1A
TRACK_SPEED = 0x00


class VerifyFailure(Exception):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("current_rom", type=Path)
    parser.add_argument("reference_rom", type=Path)
    parser.add_argument("--current-sym", type=Path)
    parser.add_argument("--reference-sym", type=Path)
    parser.add_argument("--frames", type=int, default=3600)
    parser.add_argument("--warmup-frames", type=int, default=180)
    parser.add_argument("--change-tolerance", type=float, default=0.05)
    parser.add_argument("--count-tolerance", type=int, default=8)
    parser.add_argument("--count-ratio-tolerance", type=float, default=0.20)
    parser.add_argument("--rms-ratio-min", type=float, default=0.50)
    parser.add_argument("--skip-track-speed-check", action="store_true")
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
        if match:
            symbols[match.group(3)] = int(match.group(2), 16)
    return symbols


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
        except (TypeError, ValueError) as exc:
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


def tick_frames(pyboy, frames: int) -> None:
    for _ in range(frames):
        tick_one(pyboy)


def read_mem(pyboy, addr: int) -> int:
    if hasattr(pyboy, "memory"):
        return int(pyboy.memory[addr])
    if hasattr(pyboy, "get_memory_value"):
        return int(pyboy.get_memory_value(addr))
    raise VerifyFailure("PyBoy exposes neither memory[] nor get_memory_value()")


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
    require(frames > 0, "--frames must be positive")
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


def collect_standalone_apu_stats(
    rom_path: Path,
    warmup_frames: int,
    frames: int,
) -> dict[str, object]:
    pyboy = make_pyboy(rom_path)
    try:
        tick_frames(pyboy, warmup_frames)
        return collect_running_apu_stats(pyboy, frames)
    finally:
        stop_pyboy(pyboy)


def compare_channel_stats(
    current: dict[str, object],
    reference: dict[str, object],
    args: argparse.Namespace,
) -> None:
    failures: list[str] = []
    current_changes = current["change_pct"]
    reference_changes = reference["change_pct"]
    current_states = current["channel_state_counts"]
    reference_states = reference["channel_state_counts"]
    current_frequencies = current["frequency_counts"]
    reference_frequencies = reference["frequency_counts"]

    assert isinstance(current_changes, list)
    assert isinstance(reference_changes, list)
    assert isinstance(current_states, list)
    assert isinstance(reference_states, list)
    assert isinstance(current_frequencies, list)
    assert isinstance(reference_frequencies, list)

    for channel, name in enumerate(CHANNEL_NAMES):
        change_delta = abs(current_changes[channel] - reference_changes[channel])
        if change_delta > args.change_tolerance:
            failures.append(
                f"{name} register-change delta {change_delta:.1%} exceeds "
                f"{args.change_tolerance:.1%} "
                f"(current {current_changes[channel]:.1%}, "
                f"reference {reference_changes[channel]:.1%})"
            )

        count_delta = abs(current_states[channel] - reference_states[channel])
        count_limit = max(
            args.count_tolerance,
            math.ceil(max(current_states[channel], reference_states[channel]) * args.count_ratio_tolerance),
        )
        if count_delta > count_limit:
            failures.append(
                f"{name} state-count delta {count_delta} exceeds {count_limit} "
                f"(current {current_states[channel]}, reference {reference_states[channel]})"
            )

        frequency_delta = abs(current_frequencies[channel] - reference_frequencies[channel])
        frequency_limit = max(
            args.count_tolerance,
            math.ceil(
                max(current_frequencies[channel], reference_frequencies[channel])
                * args.count_ratio_tolerance
            ),
        )
        if frequency_delta > frequency_limit:
            failures.append(
                f"{name} frequency-count delta {frequency_delta} exceeds {frequency_limit} "
                f"(current {current_frequencies[channel]}, "
                f"reference {reference_frequencies[channel]})"
            )

    current_rms = current["rms"]
    reference_rms = reference["rms"]
    if current_rms is not None and reference_rms is not None:
        assert isinstance(current_rms, float)
        assert isinstance(reference_rms, float)
        if current_rms <= 0.0 or reference_rms <= 0.0:
            failures.append(
                f"audio RMS must be nonzero "
                f"(current {current_rms:.2f}, reference {reference_rms:.2f})"
            )
        else:
            rms_ratio = min(current_rms, reference_rms) / max(current_rms, reference_rms)
            if rms_ratio < args.rms_ratio_min:
                failures.append(
                    f"audio RMS ratio {rms_ratio:.2f} below {args.rms_ratio_min:.2f} "
                    f"(current {current_rms:.2f}, reference {reference_rms:.2f})"
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


def standalone_wtracks(sym_path: Path) -> int | None:
    if not sym_path.exists():
        return None
    return parse_sym(sym_path).get("wTracks")


def standalone_track_speeds(rom_path: Path, wtracks: int, warmup_frames: int) -> list[int]:
    pyboy = make_pyboy(rom_path)
    try:
        tick_frames(pyboy, warmup_frames)
        return [read_mem(pyboy, wtracks + track * TRACK_SIZEOF + TRACK_SPEED) for track in range(4)]
    finally:
        stop_pyboy(pyboy)


def compare_standalone_track_speeds(
    current_rom: Path,
    reference_rom: Path,
    args: argparse.Namespace,
) -> None:
    if args.skip_track_speed_check:
        ok("diff tracks", "skipped by request")
        return

    current_sym = args.current_sym or current_rom.with_suffix(".sym")
    reference_sym = args.reference_sym or reference_rom.with_suffix(".sym")
    current_wtracks = standalone_wtracks(current_sym)
    reference_wtracks = standalone_wtracks(reference_sym)

    if current_wtracks is None or reference_wtracks is None:
        ok("diff tracks", "skipped; wTracks symbols unavailable")
        return

    current_speeds = standalone_track_speeds(current_rom, current_wtracks, args.warmup_frames)
    reference_speeds = standalone_track_speeds(reference_rom, reference_wtracks, args.warmup_frames)
    require(
        current_speeds == reference_speeds,
        f"track speed mismatch: current {current_speeds}, reference {reference_speeds}",
    )
    ok("diff tracks", f"speeds={current_speeds}")


def verify_audio(args: argparse.Namespace) -> None:
    require(args.current_rom.exists(), f"current ROM not found: {args.current_rom}")
    require(args.reference_rom.exists(), f"reference ROM not found: {args.reference_rom}")

    compare_standalone_track_speeds(args.current_rom, args.reference_rom, args)
    current = collect_standalone_apu_stats(args.current_rom, args.warmup_frames, args.frames)
    reference = collect_standalone_apu_stats(args.reference_rom, args.warmup_frames, args.frames)
    compare_channel_stats(current, reference, args)
    ok("diff current", format_stats(current))
    ok("diff reference", format_stats(reference))


def main() -> int:
    try:
        verify_audio(parse_args())
        return 0
    except VerifyFailure as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
