import os
import unittest
from unittest.mock import patch

from src.omarchy_stats.processes import ProcessSampler, _parse_stat, send_signal


class ProcessTests(unittest.TestCase):
    def test_parse_stat_handles_spaces_and_parentheses_in_name(self):
        fields = ["S", "4"] + ["0"] * 9 + ["12", "8"] + ["0"] * 4 + ["3"]
        parsed = _parse_stat("42 (worker (one)) " + " ".join(fields))
        self.assertEqual(parsed["pid"], 42)
        self.assertEqual(parsed["name"], "worker (one)")
        self.assertEqual(parsed["ticks"], 20)
        self.assertEqual(parsed["threads"], 3)

    def test_process_command_read_is_bounded(self):
        sampler = ProcessSampler(limit=10)
        fields = ["S", "1"] + ["0"] * 9 + ["12", "8"] + ["0"] * 4 + ["3"]
        stat = "42 (worker) " + " ".join(fields)

        def fake_read(path, default="", *, max_bytes=None, truncate=False):
            name = str(path)
            if name == "/proc/meminfo":
                return "MemTotal: 1000 kB\n"
            if name.endswith("/stat"):
                return stat
            if name.endswith("/statm"):
                return "10 5"
            if name.endswith("/status"):
                return f"Uid: {os.getuid()} {os.getuid()} {os.getuid()} {os.getuid()}\n"
            if name.endswith("/cmdline"):
                self.assertEqual(max_bytes, 4096)
                self.assertTrue(truncate)
                return "worker"
            return default

        entry = type(
            "Entry",
            (),
            {
                "name": "42",
                "__truediv__": lambda self, value: f"/proc/42/{value}",
            },
        )()
        with (
            patch("src.omarchy_stats.processes.Path.iterdir", return_value=[entry]),
            patch("src.omarchy_stats.processes.read_text", side_effect=fake_read),
            patch("src.omarchy_stats.processes.hz", return_value=100),
        ):
            result = sampler.snapshot()
        self.assertEqual(result["items"][0]["command"], "worker")

    def test_protected_and_unknown_signals_are_rejected(self):
        self.assertFalse(send_signal(1, "TERM")["ok"])
        self.assertFalse(send_signal(os.getpid(), "TERM")["ok"])
        self.assertFalse(send_signal(999999, "USR1")["ok"])

    def test_other_user_process_is_rejected(self):
        with patch("src.omarchy_stats.processes._uid", return_value=os.getuid() + 1):
            self.assertIn("another user", send_signal(99999, "TERM")["error"])
