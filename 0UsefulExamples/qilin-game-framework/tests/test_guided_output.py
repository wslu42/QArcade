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
            baseline_native_path = temp / "baseline_128x128.png"
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
            baseline_command = [
                sys.executable,
                str(ROOT / "tools" / "render_preview.py"),
                str(ROOT / "framework" / "qilin_game_framework.p8"),
                "-o",
                str(baseline_native_path),
                "--scale",
                "1",
                "--font-header",
                str(font),
                "--cache-file",
                str(temp / "baseline-cache.json"),
                "--no-font-download",
            ]
            subprocess.run(
                baseline_command, check=True, text=True, capture_output=True
            )

            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
            guides = metadata["layout_guides"]
            first = guides["blocks"][0]
            native_x = int(first["x"])
            native_y = int(first["y"])

            with Image.open(scaled_path) as scaled:
                self.assertEqual(
                    scaled.getpixel((native_x * 8, native_y * 8))[:3],
                    GUIDE_RGB,
                )
            with Image.open(native_path) as native, Image.open(
                baseline_native_path
            ) as baseline_native:
                self.assertEqual(native.tobytes(), baseline_native.tobytes())

            self.assertEqual(guides["output_line_width"], 1)
            self.assertEqual(guides["output_scale"], 8)
            self.assertEqual(guides["effective_native_line_width"], 0.125)
            self.assertEqual(guides["label_scale"], 4)
            self.assertEqual(
                guides["label_names"]["controller"], "controller"
            )
            self.assertEqual(guides["label_names"]["mission"], "mission")
            self.assertEqual(
                guides["label_names"]["operation_feedback"], "feedback"
            )
            self.assertIn(
                "operation_feedback",
                {block["name"] for block in guides["blocks"]},
            )
            blocks = {block["name"]: block for block in guides["blocks"]}
            self.assertEqual(
                blocks["controller"],
                {"name": "controller", "x": 0, "y": 0, "w": 36, "h": 54},
            )
            self.assertEqual(
                blocks["key_map"],
                {"name": "key_map", "x": 36, "y": 0, "w": 92, "h": 23},
            )
            self.assertEqual(
                blocks["operation_feedback"],
                {"name": "operation_feedback", "x": 36, "y": 23, "w": 92, "h": 6},
            )
            self.assertEqual(
                blocks["mission"],
                {"name": "mission", "x": 36, "y": 29, "w": 92, "h": 25},
            )
            self.assertEqual(
                blocks["response"],
                {"name": "response", "x": 0, "y": 54, "w": 128, "h": 74},
            )
            self.assertNotIn("core", blocks)
            self.assertEqual(guides["mission_left_line_width"], 2)
            self.assertFalse(guides["native_preview_contains_guides"])


if __name__ == "__main__":
    unittest.main()
