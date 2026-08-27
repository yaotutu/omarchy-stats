"""Composition layer that owns stateful samplers and emits one stable schema."""

from __future__ import annotations

import os
import socket
import time
from collections.abc import Callable
from typing import Any

from . import memory
from .common import read_text
from .cpu import CpuSampler
from .gpu import GpuSampler
from .network import NetworkSampler
from .processes import ProcessSampler
from .storage import StorageSampler


def _uptime() -> float | None:
    try:
        return float(read_text("/proc/uptime").split()[0])
    except (IndexError, ValueError):
        return None


def _unavailable_cpu() -> dict:
    return {
        "model": "Unavailable",
        "usagePercent": None,
        "averageFrequencyMHz": None,
        "temperatureC": None,
        "cores": [],
        "fans": [],
    }


def _unavailable_memory() -> dict:
    return {
        "totalBytes": None,
        "usedBytes": None,
        "availableBytes": None,
        "freeBytes": None,
        "cachedBytes": None,
        "bufferBytes": None,
        "sharedBytes": None,
        "swapTotalBytes": None,
        "swapUsedBytes": None,
        "usagePercent": None,
    }


def _safe(
    name: str, operation: Callable[[], Any], fallback: Any, errors: list[dict]
) -> Any:
    try:
        return operation()
    except Exception as error:  # noqa: BLE001 - isolate failures between providers.
        errors.append({"provider": name, "message": f"{type(error).__name__}: {error}"})
        return fallback


class SnapshotEngine:
    def __init__(self, process_limit: int = 160) -> None:
        self.cpu = CpuSampler()
        self.network = NetworkSampler()
        self.storage = StorageSampler()
        self.gpu = GpuSampler()
        self.processes = ProcessSampler(process_limit)

    def capture(self) -> dict:
        try:
            loads = list(os.getloadavg())
        except OSError:
            loads = []
        errors: list[dict] = []
        return {
            "schema": 1,
            "timestamp": time.time(),
            "host": socket.gethostname(),
            "uptimeSeconds": _uptime(),
            "loadAverage": loads,
            "cpu": _safe("cpu", self.cpu.snapshot, _unavailable_cpu(), errors),
            "memory": _safe("memory", memory.snapshot, _unavailable_memory(), errors),
            "storage": _safe("storage", self.storage.snapshot, [], errors),
            "network": _safe(
                "network",
                self.network.snapshot,
                {"activeInterface": "", "interfaces": []},
                errors,
            ),
            "gpus": _safe("gpu", self.gpu.snapshot, [], errors),
            "processes": _safe(
                "processes",
                self.processes.snapshot,
                {"count": 0, "threads": 0, "items": []},
                errors,
            ),
            "errors": errors,
        }
