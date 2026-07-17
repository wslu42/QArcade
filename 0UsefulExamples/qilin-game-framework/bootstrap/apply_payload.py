#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

script = Path(__file__).resolve()
bootstrap = script.parent
framework_root = script.parents[1]

paths = [
    framework_root / "framework" / "qilin_game_framework.p8",
    framework_root / "framework" / "qilin_quantum_router_v49_user_adjusted_layout.lua",
]

old = "-- centralized nested layout contract"
new = "-- centralized layout contract"
for path in paths:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise SystemExit(f"Expected legacy wording was not found in {path}")
    path.write_text(text.replace(old, new), encoding="utf-8")

script.unlink()
if bootstrap.exists() and not any(bootstrap.iterdir()):
    bootstrap.rmdir()
