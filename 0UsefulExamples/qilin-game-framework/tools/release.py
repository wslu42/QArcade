#!/usr/bin/env python3
"""Create an explicit Qilin framework release archive.

Release packaging is intentionally separate from preview generation.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import tempfile
import zipfile
from pathlib import Path


DEFAULT_INCLUDED_DIRS = ("framework", "reference", "docs", "tools", "tests")
DEFAULT_INCLUDED_FILES = ("README.md", "requirements.txt", ".gitignore")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def collect_files(root: Path, include_previews: bool) -> list[Path]:
    files: list[Path] = []
    for name in DEFAULT_INCLUDED_FILES:
        path = root / name
        if path.is_file():
            files.append(path)
    for name in DEFAULT_INCLUDED_DIRS:
        directory = root / name
        if directory.is_dir():
            files.extend(path for path in directory.rglob("*") if path.is_file())
    if include_previews:
        previews = root / "previews"
        if previews.is_dir():
            files.extend(path for path in previews.rglob("*") if path.is_file())

    def allowed(path: Path) -> bool:
        relative = path.relative_to(root)
        parts = set(relative.parts)
        return (
            ".qilin-cache" not in parts
            and "__pycache__" not in parts
            and path.suffix not in {".pyc", ".pyo"}
        )

    return sorted({path for path in files if allowed(path)})


def main() -> int:
    parser = argparse.ArgumentParser(description="Package Qilin framework release.")
    parser.add_argument("--project-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--include-previews", action="store_true")
    args = parser.parse_args()

    root = args.project_root.resolve()
    output = args.output.resolve()
    if not (root / "framework" / "qilin_game_framework_4Qv.p8").exists():
        parser.error("framework/qilin_game_framework_4Qv.p8 was not found.")
    if not (root / "framework" / "qilin_game_framework_4Qh.p8").exists():
        parser.error("framework/qilin_game_framework_4Qh.p8 was not found.")

    files = collect_files(root, args.include_previews)
    manifest = {
        "source_of_truth": "framework/qilin_game_framework_4Qv.p8",
        "controller_variants": [
            "framework/qilin_game_framework_4Qv.p8",
            "framework/qilin_game_framework_4Qh.p8",
        ],
        "original_reference": "reference/qilin.p8",
        "files": {
            str(path.relative_to(root)): sha256(path)
            for path in files
        },
    }

    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        suffix=".zip",
        dir=output.parent,
        delete=False,
    ) as handle:
        temporary = Path(handle.name)

    try:
        with zipfile.ZipFile(temporary, "w", zipfile.ZIP_DEFLATED) as archive:
            for path in files:
                archive.write(path, arcname=path.relative_to(root.parent))
            archive.writestr(
                f"{root.name}/RELEASE_MANIFEST.json",
                json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
            )
        os.replace(temporary, output)
    finally:
        temporary.unlink(missing_ok=True)

    print(f"created {output} with {len(files)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
