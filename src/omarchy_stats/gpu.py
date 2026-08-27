"""Best-effort GPU metrics from DRM sysfs and optional nvidia-smi."""

from __future__ import annotations

import csv
import io
import re
import subprocess
from functools import lru_cache
from pathlib import Path

from .common import read_float, read_int, read_text

_VENDOR_NAMES = {"0x1002": "AMD", "0x10de": "NVIDIA", "0x8086": "Intel"}


def _scaled(path: Path, divisor: float) -> float | None:
    raw = read_float(path)
    return raw / divisor if raw is not None else None


def _hwmon_value(device: Path, pattern: str, divisor: float) -> float | None:
    for path in sorted((device / "hwmon").glob(f"hwmon*/{pattern}")):
        value = _scaled(path, divisor)
        if value is not None:
            return value
    return None


@lru_cache(maxsize=32)
def _label(device: Path, vendor: str) -> str:
    uevent = read_text(device / "uevent")
    slot = ""
    for line in uevent.splitlines():
        if line.startswith("PCI_SLOT_NAME="):
            slot = line.split("=", 1)[1]
    if slot:
        try:
            result = subprocess.run(
                ["lspci", "-s", slot],
                capture_output=True,
                text=True,
                timeout=1.0,
                check=False,
            ).stdout.strip()
            if ": " in result:
                return result.split(": ", 1)[1]
        except (OSError, subprocess.SubprocessError):
            pass
    device_id = read_text(device / "device").strip()
    return f"{vendor} GPU {device_id}".strip()


def _drm_gpus() -> list[dict]:
    rows: list[dict] = []
    seen: set[str] = set()
    for card in sorted(Path("/sys/class/drm").glob("card*")):
        if not re.fullmatch(r"card\d+", card.name):
            continue
        device = card / "device"
        try:
            identity = str(device.resolve())
        except OSError:
            continue
        if identity in seen:
            continue
        seen.add(identity)
        vendor_id = read_text(device / "vendor").strip().lower()
        vendor = _VENDOR_NAMES.get(vendor_id, vendor_id or "Unknown")
        busy = read_float(device / "gpu_busy_percent")
        mem_used = read_int(device / "mem_info_vram_used")
        mem_total = read_int(device / "mem_info_vram_total")
        frequency = None
        for path, divisor in (
            (device / "pp_dpm_sclk", 1.0),
            (card / "gt_cur_freq_mhz", 1.0),
            (device / "gt_cur_freq_mhz", 1.0),
        ):
            raw = read_text(path).strip()
            if path.name == "pp_dpm_sclk" and raw:
                for line in raw.splitlines():
                    if "*" in line:
                        token = line.split()[-2] if len(line.split()) >= 2 else ""
                        try:
                            frequency = float(re.sub(r"(?:MHz|Mhz)$", "", token))
                        except ValueError:
                            pass
            else:
                value = read_float(path)
                if value is not None:
                    frequency = value / divisor
            if frequency is not None:
                break
        power = _hwmon_value(device, "power1_average", 1_000_000.0)
        if power is None:
            power = _hwmon_value(device, "power1_input", 1_000_000.0)
        rows.append(
            {
                "name": _label(device, vendor),
                "vendor": vendor,
                "usagePercent": round(busy, 1) if busy is not None else None,
                "memoryUsedBytes": mem_used,
                "memoryTotalBytes": mem_total,
                "temperatureC": _hwmon_value(device, "temp1_input", 1000.0),
                "powerWatts": power,
                "frequencyMHz": round(frequency, 0) if frequency is not None else None,
            }
        )
    return rows


def _nvidia_smi() -> list[dict]:
    query = "name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,clocks.current.graphics"
    try:
        process = subprocess.run(
            ["nvidia-smi", f"--query-gpu={query}", "--format=csv,noheader,nounits"],
            capture_output=True,
            text=True,
            timeout=2.0,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return []
    if process.returncode != 0:
        return []
    rows = []
    for fields in csv.reader(io.StringIO(process.stdout)):
        if len(fields) != 7:
            continue

        def number(index: int, scale: float = 1.0, row=fields) -> float | None:
            try:
                return float(row[index].strip()) * scale
            except ValueError:
                return None

        rows.append(
            {
                "name": fields[0].strip(),
                "vendor": "NVIDIA",
                "usagePercent": number(1),
                "memoryUsedBytes": number(2, 1024 * 1024),
                "memoryTotalBytes": number(3, 1024 * 1024),
                "temperatureC": number(4),
                "powerWatts": number(5),
                "frequencyMHz": number(6),
            }
        )
    return rows


class GpuSampler:
    """Best-effort GPU sampler with cached static PCI labels."""

    def snapshot(self) -> list[dict]:
        drm = _drm_gpus()
        nvidia = _nvidia_smi()
        if not nvidia:
            return drm
        return [row for row in drm if row.get("vendor") != "NVIDIA"] + nvidia


def snapshot() -> list[dict]:
    """Compatibility helper for one-shot callers."""
    return GpuSampler().snapshot()
