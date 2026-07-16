from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def make_font_header(path: Path) -> None:
    values = ",".join("0xe0" for _ in range(1280))
    path.write_text(
        "static constexpr unsigned char font_map[] = {" + values + "};\n",
        encoding="utf-8",
    )


class PreviewCacheTest(unittest.TestCase):
    def test_second_identical_render_is_skipped(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            temp = Path(raw)
            font = temp / "pico_font.h"
            output = temp / "preview.png"
            cache = temp / "cache.json"
            make_font_header(font)
            command = [
                sys.executable,
                str(ROOT / "tools" / "render_preview.py"),
                str(ROOT / "framework" / "qilin_game_framework.p8"),
                "-o",
                str(output),
                "--scale",
                "1",
                "--font-header",
                str(font),
                "--cache-file",
                str(cache),
                "--no-font-download",
            ]
            first = subprocess.run(command, check=True, text=True, capture_output=True)
            second = subprocess.run(command, check=True, text=True, capture_output=True)
            self.assertTrue(output.exists())
            self.assertIn("rendered", first.stdout)
            self.assertIn("skipped", second.stdout)


if __name__ == "__main__":
    unittest.main()
