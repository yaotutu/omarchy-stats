import os
import unittest
from unittest.mock import patch

from src.omarchy_stats.processes import _parse_stat, send_signal


class ProcessTests(unittest.TestCase):
    def test_parse_stat_handles_spaces_and_parentheses_in_name(self):
        fields = ["S", "4"] + ["0"] * 9 + ["12", "8"] + ["0"] * 4 + ["3"]
        parsed = _parse_stat("42 (worker (one)) " + " ".join(fields))
        self.assertEqual(parsed["pid"], 42)
        self.assertEqual(parsed["name"], "worker (one)")
        self.assertEqual(parsed["ticks"], 20)
        self.assertEqual(parsed["threads"], 3)

    def test_protected_and_unknown_signals_are_rejected(self):
        self.assertFalse(send_signal(1, "TERM")["ok"])
        self.assertFalse(send_signal(os.getpid(), "TERM")["ok"])
        self.assertFalse(send_signal(999999, "USR1")["ok"])

    def test_other_user_process_is_rejected(self):
        with patch("src.omarchy_stats.processes._uid", return_value=os.getuid() + 1):
            self.assertIn("another user", send_signal(99999, "TERM")["error"])
