"""Small, failure-tolerant helpers shared by Linux data providers."""

from __future__ import annotations

import os
from collections.abc import Iterable
from pathlib import Path

MAX_TEXT_BYTES = 1024 * 1024


def read_text(
    path: str | Path,
    default: str = "",
    *,
    max_bytes: int = MAX_TEXT_BYTES,
    truncate: bool = False,
) -> str:
    """Read at most ``max_bytes`` from a procfs, sysfs, or small text file."""
    if max_bytes < 1:
        return default
    try:
        with Path(path).open("rb") as handle:
            data = handle.read(max_bytes + 1)
    except (OSError, ValueError):
        return default
    if len(data) > max_bytes:
        if not truncate:
            return default
        data = data[:max_bytes]
    return data.decode("utf-8", errors="replace")


def read_int(path: str | Path) -> int | None:
    value = read_text(path).strip()
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def read_float(path: str | Path) -> float | None:
    value = read_text(path).strip()
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def clamp(value: float, low: float = 0.0, high: float = 100.0) -> float:
    return max(low, min(high, value))


def first_present(paths: Iterable[str | Path]) -> str:
    for path in paths:
        value = read_text(path).strip()
        if value:
            return value
    return ""


def hz() -> int:
    try:
        return int(os.sysconf("SC_CLK_TCK"))
    except (OSError, ValueError):
        return 100
