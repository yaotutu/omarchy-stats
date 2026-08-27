"""CPU load, topology, frequency and hwmon sensor collection."""

from __future__ import annotations

import glob
from dataclasses import dataclass
from pathlib import Path

from .common import clamp, read_float, read_int, read_text


def _ticks(fields: list[str]) -> tuple[int, int]:
    values = [int(value) for value in fields if value.isdigit()]
    total = sum(values)
    idle = (values[3] if len(values) > 3 else 0) + (values[4] if len(values) > 4 else 0)
    return total, idle


def _model_name() -> str:
    for line in read_text("/proc/cpuinfo").splitlines():
        if line.startswith(("model name", "Hardware", "Processor")) and ":" in line:
            return line.split(":", 1)[1].strip()
    return "Unknown CPU"


def _temperature_sources() -> tuple[list[Path], list[Path]]:
    temps: list[Path] = []
    fans: list[Path] = []
    for directory in sorted(Path("/sys/class/hwmon").glob("hwmon*")):
        name = read_text(directory / "name").strip().lower()
        if name in {
            "coretemp",
            "k10temp",
            "zenpower",
            "cpu_thermal",
            "cpu-thermal",
            "thinkpad",
            "dell_smm",
        }:
            temps.extend(sorted(directory.glob("temp*_input")))
        fans.extend(sorted(directory.glob("fan*_input")))
    if not temps:
        temps = [
            Path(path)
            for path in sorted(glob.glob("/sys/class/thermal/thermal_zone*/temp"))
        ]
    return temps, fans


@dataclass
class CpuSample:
    usage: float
    cores: list[float]


class CpuSampler:
    def __init__(self) -> None:
        self._previous: dict[str, tuple[int, int]] = {}
        self.model = _model_name()
        self.temp_paths, self.fan_paths = _temperature_sources()

    def _load(self) -> CpuSample:
        current: dict[str, tuple[int, int]] = {}
        percentages: dict[str, float] = {}
        for line in read_text("/proc/stat").splitlines():
            fields = line.split()
            if not fields or (fields[0] != "cpu" and not fields[0].startswith("cpu")):
                continue
            label = fields[0]
            if label != "cpu" and not label[3:].isdigit():
                continue
            current[label] = _ticks(fields[1:])
            old = self._previous.get(label)
            if old:
                total_delta = current[label][0] - old[0]
                idle_delta = current[label][1] - old[1]
                percentages[label] = (
                    clamp(100.0 * (total_delta - idle_delta) / total_delta)
                    if total_delta > 0
                    else 0.0
                )
            else:
                percentages[label] = 0.0
        self._previous = current
        core_labels = sorted(
            (key for key in percentages if key != "cpu"), key=lambda key: int(key[3:])
        )
        return CpuSample(
            percentages.get("cpu", 0.0), [percentages[key] for key in core_labels]
        )

    @staticmethod
    def _frequencies(count: int) -> list[float | None]:
        result: list[float | None] = []
        cpuinfo_freq: list[float] = []
        for line in read_text("/proc/cpuinfo").splitlines():
            if line.startswith("cpu MHz") and ":" in line:
                try:
                    cpuinfo_freq.append(float(line.split(":", 1)[1].strip()))
                except ValueError:
                    pass
        for index in range(count):
            khz = read_int(
                f"/sys/devices/system/cpu/cpu{index}/cpufreq/scaling_cur_freq"
            )
            result.append(
                khz / 1000.0
                if khz is not None
                else (cpuinfo_freq[index] if index < len(cpuinfo_freq) else None)
            )
        return result

    def _temperatures(self) -> list[float]:
        values: list[float] = []
        for path in self.temp_paths:
            raw = read_float(path)
            if raw is None:
                continue
            celsius = raw / 1000.0 if abs(raw) > 500 else raw
            if -20 <= celsius <= 150:
                values.append(round(celsius, 1))
        return values

    def snapshot(self) -> dict:
        load = self._load()
        freqs = self._frequencies(len(load.cores))
        temps = self._temperatures()
        per_core = []
        for index, usage in enumerate(load.cores):
            per_core.append(
                {
                    "index": index,
                    "usagePercent": round(usage, 1),
                    "frequencyMHz": round(freqs[index], 0)
                    if index < len(freqs) and freqs[index] is not None
                    else None,
                    "temperatureC": temps[index] if index < len(temps) else None,
                }
            )
        available_freqs = [value for value in freqs if value is not None]
        fans = []
        for index, path in enumerate(self.fan_paths):
            rpm = read_int(path)
            if rpm is not None and rpm >= 0:
                fans.append({"name": f"Fan {index + 1}", "rpm": rpm})
        return {
            "model": self.model,
            "usagePercent": round(load.usage, 1),
            "averageFrequencyMHz": round(sum(available_freqs) / len(available_freqs), 0)
            if available_freqs
            else None,
            "temperatureC": max(temps) if temps else None,
            "cores": per_core,
            "fans": fans,
        }
