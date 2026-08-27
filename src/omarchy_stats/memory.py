"""Memory and swap parsing from /proc/meminfo."""

from __future__ import annotations

from .common import read_text


def snapshot() -> dict:
    values: dict[str, int] = {}
    for line in read_text("/proc/meminfo").splitlines():
        if ":" not in line:
            continue
        key, raw = line.split(":", 1)
        fields = raw.split()
        if not fields:
            continue
        try:
            amount = int(fields[0])
        except ValueError:
            continue
        values[key] = (
            amount * 1024 if len(fields) > 1 and fields[1].lower() == "kb" else amount
        )
    total = values.get("MemTotal", 0)
    available = values.get("MemAvailable", values.get("MemFree", 0))
    used = max(0, total - available)
    swap_total = values.get("SwapTotal", 0)
    swap_free = values.get("SwapFree", 0)
    return {
        "totalBytes": total,
        "usedBytes": used,
        "availableBytes": available,
        "freeBytes": values.get("MemFree", 0),
        "cachedBytes": values.get("Cached", 0) + values.get("SReclaimable", 0),
        "bufferBytes": values.get("Buffers", 0),
        "sharedBytes": values.get("Shmem", 0),
        "swapTotalBytes": swap_total,
        "swapUsedBytes": max(0, swap_total - swap_free),
        "usagePercent": round(used * 100.0 / total, 1) if total else 0.0,
    }
