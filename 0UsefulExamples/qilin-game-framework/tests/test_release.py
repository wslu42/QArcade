from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ReleaseSeparationTest(unittest.TestCase):
    def test_release_is_explicit_and_excludes_runtime_cache(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            output = Path(raw) / "release.zip"
            subprocess.run(
                [
                    sys.executable,
                    str(ROOT / "tools" / "release.py"),
                    "--project-root",
                    str(ROOT),
                    "--output",
                    str(output),
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            with zipfile.ZipFile(output) as archive:
                names = archive.namelist()
            self.assertTrue(any(name.endswith("framework/qilin_game_framework.p8") for name in names))
            self.assertFalse(any(".qilin-cache" in name for name in names))
            self.assertFalse(any(name.endswith("previews/current.png") for name in names))


if __name__ == "__main__":
    unittest.main()
