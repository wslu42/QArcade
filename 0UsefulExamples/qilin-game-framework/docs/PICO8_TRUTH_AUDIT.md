# PICO-8 Truth Audit — Framework v49

## Source audited

```text
framework/qilin_game_framework.p8
```

This is the framework source of truth. `reference/qilin.p8` is only the
original upstream reference.

## Renderer behavior

The renderer follows:

```text
128×128 native canvas
integer pixel coordinates
nearest-neighbor scaling
PICO-8 default palette
P8SCII bitmap glyphs
4-pixel ordinary-character advance
8-pixel graphical-symbol advance
```

Controller glyph mappings:

```text
⬇️ P8SCII 131
⬅️ P8SCII 139
🅾️ P8SCII 142
➡️ P8SCII 145
⬆️ P8SCII 148
❎ P8SCII 151
```

## Current effective layout anchors

```text
Controller:         (6,7), 40×59
Key Map:            (58,7), 66×22
Operation Feedback: (58,30), 66×6
Mission:            (46,36), 82×30
Response:           (0,66), 128×62
```

The former full-width controller wrapper and nested composer name are no longer
part of the active schema. `controller` now means the actual composer block.

## Normalization checks

- Source `cell_w=8`, `cell_h=8` are recognized as inclusive offsets and
  normalized to true dimensions `9×9`.
- `text_dy` is normalized to `text_y`.
- `gap_dy` is normalized to `gap_y`.
- State Index effective x is normalized from source `1-1` to `0`.
- Missing wire and histogram dimensions are filled from framework defaults.
- Controller dimensions are expanded when required to contain its direct
  grid, depth, and qubit elements.
- Mission and Response child bounds are normalized within their top-level blocks.

## Authority boundary

This is a static preview renderer, not a complete emulator. Native PICO-8 is
still authoritative for dynamic animation, runtime palette/font changes,
sprites, maps, sound, and arbitrary code paths outside the implemented Qilin
screen.
