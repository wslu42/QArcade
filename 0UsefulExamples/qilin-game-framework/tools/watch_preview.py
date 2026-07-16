#!/usr/bin/env python3
"""Convenience entry point for persistent Qilin preview mode."""

from __future__ import annotations

import sys

from render_preview import main


if __name__ == "__main__":
    raise SystemExit(main([*sys.argv[1:], "--watch"]))
