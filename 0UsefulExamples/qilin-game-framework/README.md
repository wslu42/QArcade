# Qilin Game Framework

A reusable PICO-8 quantum-game controller framework and fast P8SCII preview workflow.

## Source-of-truth contract

This project contains one default framework cartridge, supported layout
variants, and historical compatibility/reference cartridges. They must not be
confused.

### Framework source of truth

```text
framework/qilin_game_framework_4Qv.p8
```

This is the cartridge currently being designed and evolved as the game framework. All framework layout and behavior changes begin here.

The repository-wide input standard is release-confirmed tap/hold. Tap X adds
X; hold X plus the Controller's qubit axis selects a cyclic CNOT target and
release commits it; tap O adds H. Vertical layouts use Left/Right for the qubit
axis, Up for Run, and Down for Clear. Horizontal layouts rotate those
directions. Future derived games inherit this contract unless a task explicitly
requires a different control system.

Input is modal when dialogue or an overlay is active. Exactly one owner handles
buttons per frame, using `completion > modal (including dialogue) > controller`.
Closing a modal requires a release handoff before Controller input resumes, so
one press cannot both close dialogue and move or edit the circuit.

### Original Qilin reference

```text
reference/qilin.p8
```

This is the original upstream Qilin cartridge. It is preserved for historical, gameplay, and asset reference only. It is not the current framework source of truth.

## Repository structure

```text
qilin-game-framework/
├── framework/
│   ├── qilin_game_framework_4Qv.p8
│   ├── qilin_game_framework_3Qv.p8
│   ├── qilin_game_framework_4Qh.p8
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
├── RENDER_PNG.bat
├── WATCH_PREVIEW.bat
├── preview_viewer.html
└── release/
```

## One-click Windows preview

On Windows, no agent is needed to render a PNG.

### Render once

Double-click:

```text
RENDER_PNG.bat
```

It will:

1. create a local `.venv` on first use;
2. install Pillow on first use;
3. render `previews/current.png`;
4. also save `previews/current_128x128.png` and metadata;
5. open the rendered PNG.

The first run is slower because it creates the environment and caches the P8SCII font. Later runs avoid that setup.

### Live preview while editing

Double-click:

```text
WATCH_PREVIEW.bat
```

This opens `preview_viewer.html` and keeps the renderer in memory. Each time
`framework/qilin_game_framework_4Qv.p8` is saved, the PNG is regenerated. The
browser viewer checks for the new PNG automatically, so no manual reopen is
needed.

Close the command window or press `Ctrl+C` to stop watching.

## Accepted Response-first layout

The current controller iteration is documented in
`docs/QILIN_LAYOUT_CONTRACT.md`. This phase established:

- a full-width `128 x 78` Response canvas occupying the upper screen;
- a `37 x 50` vertical 4Q Controller at `(91,78)` in the lower-right;
- a 91-pixel lower-left column containing Mission, Operation Feedback, and Key Map;
- four 7-pixel-wide qubit columns with five vertically stacked cells;
- one-pixel gutters with alternating column colors instead of cell borders;
- numeric depth labels `5, 4, 3, 2, 1` without flow markers;
- compact code-drawn H and shared X/CNOT-target glyphs;
- a layout-sized 3-by-2 pixel qubit selector instead of a font caret;
- independent `key_map.color` and `control_examples.color` settings;
- one developer-owned `91 x 26` Mission canvas at `(0,78)` with no required child schema;
- modal input ownership and release handoff for dialogue and overlays;
- color-1 gates, yellow selection, and red blocked feedback;
- layout-driven PNG geometry and cartridge-derived grid colors;
- forced first render on watcher startup to prevent stale cached previews.
- grid-anchored Qubit/Depth labels, protected by layout parser tests so
  changing qubit count or circuit depth cannot leave detached labels.
- an explicit `bottom_right` Controller content anchor, so smaller qubit/depth
  variants grow inward from the same lower-right alignment.

## Command-line preview loop

Install once:

```bash
python -m pip install -r requirements.txt
```

One-shot preview:

```bash
python tools/render_preview.py framework/qilin_game_framework_4Qv.p8 \
  -o previews/current.png
```

With no `--gate` options, the renderer fills the compact controller with an
X, CNOT, and H example so the PNG demonstrates all supported gate symbols.
Pass `--blank-controller` for an empty grid. Supplying one or more `--gate`
options replaces the default examples.

Persistent watch mode:

```bash
python tools/render_preview.py framework/qilin_game_framework_4Qv.p8 \
  -o previews/current.png \
  --watch
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
