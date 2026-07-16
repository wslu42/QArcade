# Qilin Game Framework

A reusable PICO-8 quantum-game controller framework and fast P8SCII preview workflow.

## Source-of-truth contract

There are two different cartridges in this project and they must not be confused.

### Framework source of truth

```text
framework/qilin_game_framework.p8
```

This is the cartridge currently being designed and evolved as the game framework. All framework layout and behavior changes begin here.

The file below is a readable Lua mirror of the current v49 working state:

```text
framework/qilin_quantum_router_v49_user_adjusted_layout.lua
```

The mirror is useful for review, but the `.p8` cartridge remains authoritative.

### Original Qilin reference

```text
reference/qilin.p8
```

This is the original upstream Qilin cartridge. It is preserved for historical, gameplay, and asset reference only. It is not the current framework source of truth.

## Repository structure

```text
qilin-game-framework/
├── framework/
│   ├── qilin_game_framework.p8
│   └── qilin_quantum_router_v49_user_adjusted_layout.lua
├── reference/
│   ├── qilin.p8
│   └── README.md
├── docs/
├── tools/
│   ├── layout_parser.py
│   ├── render_core.py
│   ├── render_preview.py
│   ├── watch_preview.py
│   └── release.py
├── tests/
├── previews/
└── release/
```

## Fast preview loop

Install once:

```bash
python -m pip install -r requirements.txt
```

One-shot preview:

```bash
python tools/render_preview.py framework/qilin_game_framework.p8 \
  -o previews/current.png
```

Persistent watch mode:

```bash
python tools/watch_preview.py framework/qilin_game_framework.p8 \
  -o previews/current.png
```

Watch mode loads Python, Pillow, and the P8SCII font once. It then rerenders only when the cartridge content hash changes.

## Release loop

Previewing and release packaging are deliberately separate. A normal preview does not create a ZIP, audit, or versioned folder.

Create a release only when needed:

```bash
python tools/release.py \
  --project-root . \
  --output release/qilin-game-framework.zip
```

## Implemented performance priorities

1. Safe arithmetic expressions in Lua layout values, including `14-8`, `0+1`, multiplication, division, and parentheses.
2. Schema normalization for older/current layout field names and dimension conventions.
3. Persistent watch mode with the font and renderer held in memory.
4. Fast preview and release packaging are separate commands.
5. SHA-256 cache skips unchanged renders.
