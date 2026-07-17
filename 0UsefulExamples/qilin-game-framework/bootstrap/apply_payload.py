#!/usr/bin/env python3
from __future__ import annotations

import base64
import hashlib
import zipfile
from pathlib import Path

EXPECTED_SHA256 = "50cf79f698e6ca505f3e07f80694e70bdc9aaf63a871fe7cc7e9aa53c433493a"
EXPECTED_CHUNKS = 9

script = Path(__file__).resolve()
bootstrap = script.parent
repo_root = script.parents[3]
chunks = sorted(bootstrap.glob("chunk_*.txt"))

if len(chunks) != EXPECTED_CHUNKS:
    raise SystemExit(
        f"Expected {EXPECTED_CHUNKS} payload chunks; found {len(chunks)}."
    )

encoded = "".join(path.read_text(encoding="utf-8") for path in chunks)
try:
    archive_bytes = base64.b64decode(encoded, validate=True)
except Exception as exc:
    raise SystemExit("Qilin payload base64 decoding failed.") from exc

digest = hashlib.sha256(archive_bytes).hexdigest()
if digest != EXPECTED_SHA256:
    raise SystemExit(
        f"Qilin payload checksum mismatch: expected {EXPECTED_SHA256}, got {digest}"
    )

archive = bootstrap / "controller_promotion_payload.zip"
archive.write_bytes(archive_bytes)
with zipfile.ZipFile(archive) as payload:
    payload.extractall(repo_root)

archive.unlink()
for path in chunks:
    path.unlink()
trigger = bootstrap / "trigger.txt"
if trigger.exists():
    trigger.unlink()
script.unlink()

if bootstrap.exists() and not any(bootstrap.iterdir()):
    bootstrap.rmdir()
