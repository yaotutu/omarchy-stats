"""Command-line JSON-lines collector used by the QML interface."""

from __future__ import annotations

import argparse
import json
import sys
import time

from .processes import send_signal


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="collector.py",
        description="Omarchy Stats Linux data collector",
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--summary",
        action="store_true",
        help="stream CPU, memory, and download procfs metrics",
    )
    mode.add_argument(
        "--once",
        action="store_true",
        help="print one detailed snapshot and exit",
    )
    mode.add_argument(
        "--signal",
        nargs=2,
        metavar=("PID", "NAME"),
        help="send TERM, STOP, CONT, or KILL",
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=1.0,
        help="seconds between JSON-lines snapshots",
    )
    parser.add_argument(
        "--process-limit",
        type=int,
        default=160,
        help="maximum processes included",
    )
    parser.add_argument(
        "--interface",
        default="",
        help="specific interface for summary download rate",
    )
    return parser


def emit(payload: dict) -> None:
    sys.stdout.write(
        json.dumps(payload, separators=(",", ":"), ensure_ascii=False) + "\n"
    )
    sys.stdout.flush()


def stream(sampler, interval: float) -> int:
    try:
        while True:
            started = time.monotonic()
            emit(sampler.capture())
            time.sleep(max(0.0, interval - (time.monotonic() - started)))
    except (BrokenPipeError, KeyboardInterrupt):
        return 0


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.signal:
        try:
            pid = int(args.signal[0])
        except ValueError:
            emit({"ok": False, "error": "PID must be an integer"})
            return 2
        result = send_signal(pid, args.signal[1])
        emit(result)
        return 0 if result.get("ok") else 1

    if args.interval < 0.25 or args.interval > 60:
        parser.error("--interval must be between 0.25 and 60 seconds")
    if args.process_limit < 10 or args.process_limit > 1000:
        parser.error("--process-limit must be between 10 and 1000")

    if args.summary:
        from .summary import SummarySampler

        return stream(SummarySampler(args.interface), args.interval)

    from .snapshot import SnapshotEngine

    engine = SnapshotEngine(args.process_limit)
    if args.once:
        time.sleep(0.12)
        emit(engine.capture())
        return 0
    return stream(engine, args.interval)


if __name__ == "__main__":
    raise SystemExit(main())
