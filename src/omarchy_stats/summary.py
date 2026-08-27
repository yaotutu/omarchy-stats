"""Low-overhead bar sampler limited to three procfs files."""

from __future__ import annotations

import time

from .common import clamp, read_text


def _cpu_counter() -> tuple[int, int] | None:
    first = read_text("/proc/stat").splitlines()
    if not first:
        return None
    fields = first[0].split()
    if not fields or fields[0] != "cpu":
        return None
    try:
        values = [int(value) for value in fields[1:]]
    except ValueError:
        return None
    idle = (values[3] if len(values) > 3 else 0) + (values[4] if len(values) > 4 else 0)
    return sum(values), idle


def _memory_percent() -> float | None:
    values: dict[str, int] = {}
    for line in read_text("/proc/meminfo").splitlines():
        if ":" not in line:
            continue
        key, rest = line.split(":", 1)
        try:
            values[key] = int(rest.split()[0])
        except (IndexError, ValueError):
            continue
    total = values.get("MemTotal", 0)
    available = values.get("MemAvailable", values.get("MemFree", 0))
    return clamp((total - available) * 100.0 / total) if total else None


def _network_bytes(interface: str = "") -> int | None:
    total = 0
    matched = False
    for line in read_text("/proc/net/dev").splitlines()[2:]:
        if ":" not in line:
            continue
        name, payload = line.split(":", 1)
        name = name.strip()
        if name == "lo" or (interface and name != interface):
            continue
        try:
            total += int(payload.split()[0])
            matched = True
        except (IndexError, ValueError):
            continue
    return total if matched else None


class SummarySampler:
    def __init__(self, interface: str = "") -> None:
        self.interface = interface
        self._cpu = _cpu_counter()
        self._network = _network_bytes(interface)
        self._time = time.monotonic()

    def capture(self) -> dict:
        now = time.monotonic()
        cpu = _cpu_counter()
        network = _network_bytes(self.interface)
        usage = None
        if cpu and self._cpu:
            total_delta = cpu[0] - self._cpu[0]
            idle_delta = cpu[1] - self._cpu[1]
            usage = (
                clamp((total_delta - idle_delta) * 100.0 / total_delta)
                if total_delta > 0
                else 0.0
            )
        rate = None
        elapsed = now - self._time
        if network is not None and self._network is not None and elapsed > 0:
            rate = max(0.0, (network - self._network) / elapsed)
        self._cpu, self._network, self._time = cpu, network, now
        memory = _memory_percent()
        return {
            "schema": 1,
            "cpuPercent": round(usage, 1) if usage is not None else None,
            "memoryPercent": round(memory, 1) if memory is not None else None,
            "downloadBytesPerSecond": round(rate, 1) if rate is not None else None,
        }
