"""Network interface counters, state and IPv4 addressing."""

from __future__ import annotations

import fcntl
import socket
import struct
import time
from dataclasses import dataclass
from pathlib import Path

from .common import read_text


def _counters() -> dict[str, tuple[int, int]]:
    result: dict[str, tuple[int, int]] = {}
    for line in read_text("/proc/net/dev").splitlines()[2:]:
        if ":" not in line:
            continue
        name, payload = line.split(":", 1)
        fields = payload.split()
        if len(fields) < 9:
            continue
        try:
            result[name.strip()] = (int(fields[0]), int(fields[8]))
        except ValueError:
            continue
    return result


def _ipv4(name: str) -> str | None:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        packed = struct.pack("256s", name[:15].encode("utf-8"))
        return socket.inet_ntoa(fcntl.ioctl(sock.fileno(), 0x8915, packed)[20:24])
    except OSError:
        return None
    finally:
        sock.close()


def _default_interface() -> str:
    for line in read_text("/proc/net/route").splitlines()[1:]:
        fields = line.split()
        if len(fields) > 1 and fields[1] == "00000000":
            return fields[0]
    return ""


@dataclass
class _NetworkState:
    timestamp: float
    counters: dict[str, tuple[int, int]]


class NetworkSampler:
    def __init__(self) -> None:
        self._state: _NetworkState | None = None

    def snapshot(self) -> dict:
        now = time.monotonic()
        counters = _counters()
        previous = self._state
        self._state = _NetworkState(now, counters)
        elapsed = now - previous.timestamp if previous else 0.0
        default = _default_interface()
        rows: list[dict] = []
        for name in sorted(counters):
            if name == "lo":
                continue
            rx, tx = counters[name]
            old = previous.counters.get(name) if previous else None
            down = max(0.0, (rx - old[0]) / elapsed) if old and elapsed > 0 else 0.0
            up = max(0.0, (tx - old[1]) / elapsed) if old and elapsed > 0 else 0.0
            state = read_text(Path("/sys/class/net") / name / "operstate").strip()
            rows.append(
                {
                    "name": name,
                    "active": name == default,
                    "up": state == "up",
                    "wireless": (Path("/sys/class/net") / name / "wireless").exists(),
                    "address": _ipv4(name),
                    "downloadBytesPerSecond": round(down, 1),
                    "uploadBytesPerSecond": round(up, 1),
                    "receivedBytes": rx,
                    "sentBytes": tx,
                }
            )
        return {"activeInterface": default, "interfaces": rows}
