import unittest
from unittest.mock import patch

from src.omarchy_stats import memory


class MemoryTests(unittest.TestCase):
    def test_snapshot_uses_available_memory(self):
        sample = "MemTotal: 1000 kB\nMemFree: 100 kB\nMemAvailable: 400 kB\nCached: 200 kB\nSReclaimable: 50 kB\nShmem: 20 kB\nBuffers: 10 kB\nSwapTotal: 500 kB\nSwapFree: 450 kB\n"
        with patch("src.omarchy_stats.memory.read_text", return_value=sample):
            result = memory.snapshot()
        self.assertEqual(result["totalBytes"], 1000 * 1024)
        self.assertEqual(result["usedBytes"], 600 * 1024)
        self.assertEqual(result["swapUsedBytes"], 50 * 1024)
        self.assertEqual(result["usagePercent"], 60.0)
