import tempfile
import unittest
from pathlib import Path

from src.omarchy_stats.common import read_text


class BoundedReadTests(unittest.TestCase):
    def test_read_text_accepts_content_within_limit(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "small"
            path.write_bytes(b"12345678")
            self.assertEqual(read_text(path, max_bytes=8), "12345678")

    def test_read_text_rejects_oversized_content_by_default(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "large"
            path.write_bytes(b"123456789")
            self.assertEqual(read_text(path, "unavailable", max_bytes=8), "unavailable")

    def test_read_text_can_return_a_bounded_prefix(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "large"
            path.write_bytes(b"123456789")
            self.assertEqual(
                read_text(path, max_bytes=8, truncate=True),
                "12345678",
            )
