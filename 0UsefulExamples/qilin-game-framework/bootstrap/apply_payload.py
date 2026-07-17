#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import shutil
import zipfile
from pathlib import Path

EXPECTED_SHA256 = "5422ba09d3e7654444a14a861f8e85d8f42313c961fe2bb8c29fffbff237dacf"

script = Path(__file__).resolve()
bootstrap = script.parent
repo_root = script.parents[3]
archive = bootstrap / "payload_v1.zip"

if not archive.is_file():
    raise SystemExit("Staged Qilin payload archive was not found.")

digest = hashlib.sha256(archive.read_bytes()).hexdigest()
if digest != EXPECTED_SHA256:
    raise SystemExit(
        f"Qilin payload checksum mismatch: expected {EXPECTED_SHA256}, got {digest}"
    )

with zipfile.ZipFile(archive) as payload:
    payload.extractall(repo_root)

archive.unlink()
script.unlink()

payload_dir = bootstrap / "payload_v1"
if payload_dir.exists():
    shutil.rmtree(payload_dir)
