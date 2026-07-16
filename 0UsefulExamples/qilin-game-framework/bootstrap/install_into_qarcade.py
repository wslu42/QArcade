#!/usr/bin/env python3
"""Install this prepared framework bundle into a local QArcade clone."""

from __future__ import annotations

import argparse
import shutil
import urllib.request
from pathlib import Path

UPSTREAM_QILIN = "https://raw.githubusercontent.com/wslu42/qilin/main/qilin.p8"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("qarcade_root", type=Path)
    parser.add_argument(
        "--workflow",
        type=Path,
        default=Path(__file__).resolve().parents[2] / ".github" / "workflows" / "qilin-game-framework.yml",
    )
    args = parser.parse_args()

    qarcade = args.qarcade_root.resolve()
    if not (qarcade / "README.md").exists():
        parser.error(f"Not a QArcade clone: {qarcade}")

    source = Path(__file__).resolve().parents[1]
    destination = qarcade / "0UsefulExamples" / "qilin-game-framework"
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(source, destination, dirs_exist_ok=True)

    workflow_destination = qarcade / ".github" / "workflows" / "qilin-game-framework.yml"
    workflow_destination.parent.mkdir(parents=True, exist_ok=True)
    if args.workflow.exists():
        shutil.copy2(args.workflow, workflow_destination)

    reference = destination / "reference" / "qilin.p8"
    reference.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(UPSTREAM_QILIN, timeout=30) as response:
        reference.write_bytes(response.read())

    print(f"installed framework to {destination}")
    print(f"synced original reference to {reference}")
    print("review with git diff, then commit and push")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
