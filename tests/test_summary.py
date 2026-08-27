import unittest
from unittest.mock import patch

from src.omarchy_stats.summary import SummarySampler


class SummarySamplerTests(unittest.TestCase):
    def test_delta_math_and_shape(self):
        sampler = SummarySampler.__new__(SummarySampler)
        sampler.interface = ""
        sampler._cpu = (1000, 400)
        sampler._network = 5000
        sampler._time = 10.0
        with (
            patch("src.omarchy_stats.summary.time.monotonic", return_value=12.0),
            patch("src.omarchy_stats.summary._cpu_counter", return_value=(1200, 450)),
            patch("src.omarchy_stats.summary._network_bytes", return_value=9000),
            patch("src.omarchy_stats.summary._memory_percent", return_value=37.25),
        ):
            result = sampler.capture()
        self.assertEqual(result["schema"], 1)
        self.assertEqual(result["cpuPercent"], 75.0)
        self.assertEqual(result["memoryPercent"], 37.2)
        self.assertEqual(result["downloadBytesPerSecond"], 2000.0)

    def test_counter_reset_never_reports_negative_rate(self):
        sampler = SummarySampler.__new__(SummarySampler)
        sampler.interface = "eth0"
        sampler._cpu = None
        sampler._network = 9000
        sampler._time = 1.0
        with (
            patch("src.omarchy_stats.summary.time.monotonic", return_value=2.0),
            patch("src.omarchy_stats.summary._cpu_counter", return_value=None),
            patch("src.omarchy_stats.summary._network_bytes", return_value=10),
            patch("src.omarchy_stats.summary._memory_percent", return_value=None),
        ):
            result = sampler.capture()
        self.assertEqual(result["downloadBytesPerSecond"], 0.0)
        self.assertIsNone(result["cpuPercent"])
