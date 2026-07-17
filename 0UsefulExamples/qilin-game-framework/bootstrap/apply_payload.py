#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import shutil
import zipfile
from pathlib import Path

EXPECTED_SHA256 = "50cf79f698e6ca505f3e07f80694e70bdc9aaf63a871fe7cc7e9aa53c433493a"

script = Path(__file__).resolve()
bootstrap = script.parent
repo_root = script.parents[3]
archive = bootstrap / "controller_promotion_payload.zip"

if not archive.is_file():
    raise SystemExit("Staged Qilin controller-promotion payload was not found.")

digest = hashlib.sha256(archive.read_bytes()).hexdigest()
if digest != EXPECTED_SHA256:
    raise SystemExit(
        f"Qilin payload checksum mismatch: expected {EXPECTED_SHA256}, got {digest}"
    )

with zipfile.ZipFile(archive) as payload:
    payload.extractall(repo_root)

archive.unlink()
script.unlink()

if bootstrap.exists() and not any(bootstrap.iterdir()):
    bootstrap.rmdir()
