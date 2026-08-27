import unittest
from unittest.mock import patch

from src.omarchy_stats.snapshot import SnapshotEngine


class SnapshotIsolationTests(unittest.TestCase):
    def test_one_provider_failure_does_not_break_snapshot(self):
        engine = SnapshotEngine.__new__(SnapshotEngine)
        engine.cpu = type(
            "Broken",
            (),
            {"snapshot": lambda self: (_ for _ in ()).throw(RuntimeError("sensor"))},
        )()
        engine.network = type(
            "Network",
            (),
            {"snapshot": lambda self: {"activeInterface": "eth0", "interfaces": []}},
        )()
        engine.storage = type("Storage", (), {"snapshot": lambda self: []})()
        engine.gpu = type("Gpu", (), {"snapshot": lambda self: []})()
        engine.processes = type(
            "Processes",
            (),
            {"snapshot": lambda self: {"count": 0, "threads": 0, "items": []}},
        )()

        with patch(
            "src.omarchy_stats.snapshot.memory.snapshot",
            return_value={"usagePercent": 25.0},
        ):
            result = engine.capture()

        self.assertIsNone(result["cpu"]["usagePercent"])
        self.assertEqual(result["memory"]["usagePercent"], 25.0)
        self.assertEqual(result["errors"][0]["provider"], "cpu")
