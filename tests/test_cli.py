import io
import json
import subprocess
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

from src.omarchy_stats import cli

ROOT = Path(__file__).resolve().parents[1]
COLLECTOR = ROOT / "src" / "collector.py"


class CliTests(unittest.TestCase):
    def run_collector(self, *args, timeout=15):
        return subprocess.run(
            [sys.executable, str(COLLECTOR), *args],
            text=True,
            capture_output=True,
            timeout=timeout,
            check=False,
        )

    def test_help_exits_cleanly(self):
        result = self.run_collector("--help", timeout=3)
        self.assertEqual(result.returncode, 0)
        self.assertIn("Omarchy Stats Linux data collector", result.stdout)

    def test_unknown_argument_fails_fast(self):
        result = self.run_collector("--not-a-real-option", timeout=3)
        self.assertEqual(result.returncode, 2)
        self.assertIn("unrecognized arguments", result.stderr)

    def test_invalid_interval_is_rejected(self):
        result = self.run_collector("--once", "--interval", "0.1", timeout=3)
        self.assertEqual(result.returncode, 2)
        self.assertIn("between 0.25 and 60", result.stderr)

    def test_once_has_stable_top_level_schema(self):
        result = self.run_collector("--once")
        self.assertEqual(result.returncode, 0, result.stderr)
        value = json.loads(result.stdout.strip())
        self.assertEqual(value["schema"], 1)
        for key in ("cpu", "memory", "storage", "network", "gpus", "processes"):
            self.assertIn(key, value)
        self.assertIn("interfaces", value["network"])
        self.assertIn("items", value["processes"])

    def test_large_payload_is_replaced_with_bounded_error(self):
        output = io.StringIO()
        with (
            patch.object(cli, "MAX_JSON_BYTES", 256),
            redirect_stdout(output),
        ):
            cli.emit({"value": "x" * 512})
        value = json.loads(output.getvalue())
        self.assertEqual(value["errors"][0]["provider"], "collector")
        self.assertLessEqual(len(output.getvalue().encode("utf-8")), 256)

    def test_normal_payload_stays_within_output_limit(self):
        encoded = cli._encode_bounded({"schema": 1, "value": "ok"})
        self.assertIsNotNone(encoded)
        self.assertLessEqual(len(encoded.encode("utf-8")), cli.MAX_JSON_BYTES)

    def test_summary_emits_only_lightweight_fields(self):
        process = subprocess.Popen(
            [sys.executable, str(COLLECTOR), "--summary", "--interval", "0.25"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        try:
            value = json.loads(process.stdout.readline())
            self.assertEqual(
                set(value),
                {"schema", "cpuPercent", "memoryPercent", "downloadBytesPerSecond"},
            )
        finally:
            process.terminate()
            process.wait(timeout=3)
            process.stdout.close()
            process.stderr.close()
