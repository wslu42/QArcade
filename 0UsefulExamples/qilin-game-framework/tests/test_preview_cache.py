from __future__ import annotations

import json
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
                str(ROOT / "framework" / "qilin_game_framework_4Qv.p8"),
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

    def test_default_render_adds_x_cx_h_examples(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            temp = Path(raw)
            font = temp / "pico_font.h"
            metadata = temp / "preview.json"
            make_font_header(font)
            command = [
                sys.executable,
                str(ROOT / "tools" / "render_preview.py"),
                str(ROOT / "framework" / "qilin_game_framework_4Qv.p8"),
                "-o",
                str(temp / "preview.png"),
                "--metadata-output",
                str(metadata),
                "--scale",
                "1",
                "--font-header",
                str(font),
                "--cache-file",
                str(temp / "cache.json"),
                "--no-font-download",
                "--quiet",
            ]
            subprocess.run(command, check=True)
            gates = json.loads(metadata.read_text(encoding="utf-8"))["state"]["gates"]
            self.assertEqual(
                gates,
                [
                    {"depth": 1, "gate_type": "x", "visual_q": 1, "target_visual_q": None},
                    {"depth": 2, "gate_type": "cx", "visual_q": 1, "target_visual_q": 4},
                    {"depth": 3, "gate_type": "h", "visual_q": 2, "target_visual_q": None},
                ],
            )

            command.extend(["--gate", "q2:d4:h"])
            subprocess.run(command, check=True)
            gates = json.loads(metadata.read_text(encoding="utf-8"))["state"]["gates"]
            self.assertEqual(
                gates,
                [{"depth": 4, "gate_type": "h", "visual_q": 2, "target_visual_q": None}],
            )

            command = [arg for arg in command[:-2] if arg != "--force"]
            command.append("--blank-controller")
            subprocess.run(command, check=True)
            gates = json.loads(metadata.read_text(encoding="utf-8"))["state"]["gates"]
            self.assertEqual(gates, [])


if __name__ == "__main__":
    unittest.main()
