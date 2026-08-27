"""Mounted filesystem capacity and block-device throughput."""

from __future__ import annotations

import os
import time
from dataclasses import dataclass

from .common import read_text

_PSEUDO = {
    "autofs",
    "binfmt_misc",
    "bpf",
    "cgroup",
    "cgroup2",
    "configfs",
    "debugfs",
    "devpts",
    "devtmpfs",
    "efivarfs",
    "fusectl",
    "hugetlbfs",
    "mqueue",
    "overlay",
    "proc",
    "pstore",
    "securityfs",
    "sysfs",
    "tmpfs",
    "tracefs",
}


def _unescape(value: str) -> str:
    return value.replace("\\040", " ").replace("\\011", "\t").replace("\\134", "\\")


def _mounts() -> list[tuple[str, str, str]]:
    found: list[tuple[str, str, str]] = []
    for line in read_text("/proc/self/mounts").splitlines():
        fields = line.split()
        if len(fields) < 3:
            continue
        source, mount, fs_type = _unescape(fields[0]), _unescape(fields[1]), fields[2]
        if fs_type in _PSEUDO or not mount.startswith("/"):
            continue
        found.append((source, mount, fs_type))
    return found


def _block_name(source: str) -> str:
    if not source.startswith("/dev/"):
        return ""
    return os.path.basename(os.path.realpath(source))


def _disk_counters() -> dict[str, tuple[int, int]]:
    counters: dict[str, tuple[int, int]] = {}
    for line in read_text("/proc/diskstats").splitlines():
        fields = line.split()
        if len(fields) < 14:
            continue
        try:
            counters[fields[2]] = (int(fields[5]) * 512, int(fields[9]) * 512)
        except ValueError:
            continue
    return counters


@dataclass
class _IoState:
    timestamp: float
    counters: dict[str, tuple[int, int]]


class StorageSampler:
    def __init__(self) -> None:
        self._state: _IoState | None = None

    def snapshot(self) -> list[dict]:
        now = time.monotonic()
        counters = _disk_counters()
        previous = self._state
        self._state = _IoState(now, counters)
        elapsed = now - previous.timestamp if previous else 0.0
        groups: dict[tuple[str, int], dict] = {}
        for source, mount, fs_type in _mounts():
            try:
                stats = os.statvfs(mount)
            except OSError:
                continue
            total = stats.f_blocks * stats.f_frsize
            if total <= 0:
                continue
            free = stats.f_bavail * stats.f_frsize
            used = max(0, total - free)
            key = (source, total)
            existing = groups.get(key)
            if existing:
                existing["additionalMounts"].append(mount)
                continue
            block = _block_name(source)
            read_bps = write_bps = None
            if (
                elapsed > 0
                and block
                and previous
                and block in counters
                and block in previous.counters
            ):
                old_read, old_write = previous.counters[block]
                new_read, new_write = counters[block]
                read_bps = max(0.0, (new_read - old_read) / elapsed)
                write_bps = max(0.0, (new_write - old_write) / elapsed)
            groups[key] = {
                "source": source,
                "mountPoint": mount,
                "additionalMounts": [],
                "fileSystem": fs_type,
                "totalBytes": total,
                "usedBytes": used,
                "freeBytes": free,
                "usagePercent": round(used * 100.0 / total, 1),
                "readBytesPerSecond": round(read_bps, 1)
                if read_bps is not None
                else None,
                "writeBytesPerSecond": round(write_bps, 1)
                if write_bps is not None
                else None,
            }
        rows = list(groups.values())
        rows.sort(key=lambda item: (item["mountPoint"] != "/", item["mountPoint"]))
        return rows
