"""Process table sampling and guarded process-control operations."""

from __future__ import annotations

import os
import pwd
import signal
import time
from dataclasses import dataclass
from pathlib import Path

from .common import hz, read_text

_ALLOWED_SIGNALS = {
    "TERM": signal.SIGTERM,
    "STOP": signal.SIGSTOP,
    "CONT": signal.SIGCONT,
    "KILL": signal.SIGKILL,
}


@dataclass
class _ProcReading:
    ticks: int
    timestamp: float


def _parse_stat(raw: str) -> dict | None:
    left = raw.find("(")
    right = raw.rfind(")")
    if left < 1 or right <= left:
        return None
    try:
        pid = int(raw[:left].strip())
        fields = raw[right + 2 :].split()
        return {
            "pid": pid,
            "name": raw[left + 1 : right],
            "state": fields[0],
            "parentPid": int(fields[1]),
            "ticks": int(fields[11]) + int(fields[12]),
            "threads": int(fields[17]),
        }
    except (IndexError, ValueError):
        return None


def _memory_total() -> int:
    for line in read_text("/proc/meminfo").splitlines():
        if line.startswith("MemTotal:"):
            try:
                return int(line.split()[1]) * 1024
            except (IndexError, ValueError):
                return 0
    return 0


def _uid(pid: int) -> int | None:
    for line in read_text(f"/proc/{pid}/status").splitlines():
        if line.startswith("Uid:"):
            try:
                return int(line.split()[1])
            except (IndexError, ValueError):
                return None
    return None


def _rss(pid: int) -> int:
    fields = read_text(f"/proc/{pid}/statm").split()
    try:
        return int(fields[1]) * os.sysconf("SC_PAGE_SIZE")
    except (IndexError, OSError, ValueError):
        return 0


def _username(uid: int | None) -> str:
    if uid is None:
        return "?"
    try:
        return pwd.getpwuid(uid).pw_name
    except KeyError:
        return str(uid)


class ProcessSampler:
    def __init__(self, limit: int = 160) -> None:
        self.limit = limit
        self._previous: dict[int, _ProcReading] = {}

    def snapshot(self) -> dict:
        now = time.monotonic()
        clock_ticks = hz()
        total_memory = _memory_total()
        current: dict[int, _ProcReading] = {}
        rows: list[dict] = []
        process_count = 0
        thread_count = 0
        for entry in Path("/proc").iterdir():
            if not entry.name.isdigit():
                continue
            parsed = _parse_stat(read_text(entry / "stat"))
            if not parsed:
                continue
            pid = parsed["pid"]
            process_count += 1
            thread_count += parsed["threads"]
            reading = _ProcReading(parsed["ticks"], now)
            current[pid] = reading
            old = self._previous.get(pid)
            cpu = 0.0
            if old:
                elapsed = now - old.timestamp
                if elapsed > 0:
                    cpu = max(
                        0.0,
                        (reading.ticks - old.ticks) * 100.0 / (clock_ticks * elapsed),
                    )
            rss = _rss(pid)
            uid = _uid(pid)
            command = (
                read_text(entry / "cmdline", max_bytes=4096, truncate=True)
                .replace("\0", " ")
                .strip()
            )
            rows.append(
                {
                    "pid": pid,
                    "parentPid": parsed["parentPid"],
                    "name": parsed["name"],
                    "user": _username(uid),
                    "uid": uid,
                    "state": parsed["state"],
                    "threads": parsed["threads"],
                    "cpuPercent": round(cpu, 1),
                    "memoryPercent": round(rss * 100.0 / total_memory, 2)
                    if total_memory
                    else 0.0,
                    "residentBytes": rss,
                    "command": command,
                }
            )
        self._previous = current
        rows.sort(
            key=lambda item: (-item["cpuPercent"], -item["residentBytes"], item["pid"])
        )
        return {
            "count": process_count,
            "threads": thread_count,
            "items": rows[: self.limit],
        }


def send_signal(pid: int, signal_name: str) -> dict:
    name = signal_name.upper()
    if name not in _ALLOWED_SIGNALS:
        return {"ok": False, "error": f"Unsupported signal: {signal_name}"}
    if pid <= 1 or pid in {os.getpid(), os.getppid()}:
        return {"ok": False, "error": "Refusing to control a protected process"}
    status_uid = _uid(pid)
    if status_uid is None:
        return {"ok": False, "error": "Process no longer exists"}
    if status_uid != os.getuid():
        return {"ok": False, "error": "Process belongs to another user"}
    try:
        os.kill(pid, _ALLOWED_SIGNALS[name])
    except ProcessLookupError:
        return {"ok": False, "error": "Process no longer exists"}
    except PermissionError:
        return {"ok": False, "error": "Permission denied"}
    except OSError as error:
        return {"ok": False, "error": str(error)}
    return {"ok": True, "pid": pid, "signal": name}
