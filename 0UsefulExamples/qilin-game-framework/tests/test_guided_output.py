from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GUIDE_RGB = (131, 118, 156)


def make_font_header(path: Path) -> None:
    values = ",".join("0x00" for _ in range(1280))
    path.write_text(
        "static constexpr unsigned char font_map[] = {" + values + "};\n",
        encoding="utf-8",
    )


class GuidedOutputTest(unittest.TestCase):
    def test_guides_exist_only_on_scaled_output(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            temp = Path(raw)
            font = temp / "pico_font.h"
            scaled_path = temp / "current.png"
            native_path = temp / "current_128x128.png"
            metadata_path = temp / "current.json"
            cache_path = temp / "cache.json"
            make_font_header(font)

            command = [
                sys.executable,
                str(ROOT / "tools" / "render_preview_guided.py"),
                str(ROOT / "framework" / "qilin_game_framework.p8"),
                "-o",
                str(scaled_path),
                "--native-output",
                str(native_path),
                "--metadata-output",
                str(metadata_path),
                "--scale",
                "8",
                "--font-header",
                str(font),
                "--cache-file",
                str(cache_path),
                "--no-font-download",
            ]
            subprocess.run(command, check=True, text=True, capture_output=True)

            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
            guides = metadata["layout_guides"]
            first = guides["blocks"][0]
            native_x = int(first["x"])
            native_y = int(first["y"])

            with Image.open(scaled_path) as scaled:
                self.assertEqual(
                    scaled.getpixel((native_x * 8, native_y * 8)),
                    GUIDE_RGB,
                )
            with Image.open(native_path) as native:
                self.assertNotEqual(
                    native.getpixel((native_x, native_y)),
                    GUIDE_RGB,
                )

            self.assertEqual(guides["output_line_width"], 1)
            self.assertEqual(guides["output_scale"], 8)
            self.assertEqual(guides["effective_native_line_width"], 0.125)
            self.assertFalse(guides["native_preview_contains_guides"])


if __name__ == "__main__":
    unittest.main()
