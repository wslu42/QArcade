# Qilin Layout Contract

## Scope

This document records the accepted compact gameplay layout. The authoritative
cartridge is:

```text
framework/qilin_game_framework.p8
```

`reference/qilin.p8` is historical reference material only. Native PICO-8
output remains authoritative if a static preview differs.

## Coordinate and sizing rules

- Screen: `128 x 128` integer pixels.
- Top-level blocks use screen coordinates.
- Child coordinates are relative to their parent.
- Layout `w` and `h` are true dimensions: `right=x+w-1` and `bottom=y+h-1`.
- Source `cell_w=8` and `cell_h=8` are inclusive PICO-8 offsets and normalize
  to visible `9 x 9` cells.
- The preview normalizer may expand a parent that is too small for its
  children. It never shrinks an explicitly larger parent.

## Top-level blocks

| Block | Origin | Size | Bounds |
|---|---:|---:|---:|
| Controller | `(0,0)` | `36 x 54` | `x=0..35, y=0..53` |
| Key Map | `(36,0)` | `92 x 23` | `x=36..127, y=0..22` |
| Operation Feedback | `(36,23)` | `92 x 6` | `x=36..127, y=23..28` |
| Mission | `(36,29)` | `92 x 25` | `x=36..127, y=29..53` |
| Response | `(0,54)` | `128 x 74` | `x=0..127, y=54..127` |

These five rectangles are the major guided-preview outlines.

## Controller

### Grid

```lua
grid={
  x=1,
  y=3,
  cell_w=8,
  cell_h=8,
  col_pitch=10,
  row_pitch=9
}
```

Normalized cells are `9 x 9`. Because `row_pitch` is also 9, each qubit
column contains four vertically stacked cells with no gap. Columns retain a
one-pixel horizontal gap because `col_pitch=10`.

Effective columns:

```text
Q1 x=1..9
Q2 x=11..19
Q3 x=21..29
```

Effective rows:

```text
4 y=3..11
3 y=12..20
2 y=21..29
1 y=30..38
```

The old qubit-wire/time-flow arrow graphics were removed. Sequence is shown
by the compact bottom-to-top depth ordering and the adjacent numeric labels.

### Depth labels and flow markers

```text
Depth Index:          local (31,3), text offset y=2
Depth Flow Indicator: local (31,4), gap offset y=-2
```

Depth labels are the single digits `4, 3, 2, 1`; the former `D` prefix was
removed. The preview reserves 5 pixels for each label: a 4-pixel P8SCII digit
plus one pixel of breathing room.

### Qubit labels and selector

```text
Qubit Index:    local (2,40)
Qubit Selector: local (4,46)
```

The selector is the child that currently determines the controller's minimum
normalized height: `46 + 6 = 52`. The accepted parent height is 54.

### Grid drawing and highlights

The cartridge's grid `rectfill(...)` value is the background color and
`border_color` is the normal one-pixel border. The fallback renderer reads
those existing PICO-8 values rather than requiring preview-only fields.

Fresh X, H, and CX assignments all use the same one-pixel color-13 border.
The former extra outer border for fresh X/H gates was removed.

## Key Map

```text
origin=(36,0)
size=92 x 23
```

The Key Map is a top-level block, not a child of Controller. It holds the
button-to-gate, clear, and run instructions.

## Operation Feedback

```text
origin=(36,23)
size=92 x 6
```

This line reports successful gate placement or a blocked action. It is
separate from mission feedback.

## Mission

```text
origin=(36,29)
size=92 x 25
```

Child geometry:

| Child | Local origin | Size |
|---|---:|---:|
| Title | `(0,0)` | `82 x 6` |
| Instruction | `(0,10)` | `82 x 6` |
| Feedback | `(0,19)` | `82 x 6` |

## Response

```text
origin=(0,54)
size=128 x 74
```

Child geometry:

| Child | Local origin | Important values |
|---|---:|---|
| Legend | `(2,20)` | target text `x=10`, measured text `x=60` |
| Canvas | `(4,30)` | `base_y=16`, `state_pitch=16`, bar width `9` |
| State Index | `(3,51)` | `state_pitch=16` |

State labels remain:

```text
000 001 010 011 100 101 110 111
```

## Naming discipline

Use these names in future layout requests:

- Controller
- Controller Grid
- Depth Index
- Depth Flow Indicator
- Qubit Index
- Qubit Selector
- Key Map
- Operation Feedback
- Mission
- Response

Regenerate a guided preview after any geometry change and confirm final
behavior in native PICO-8.
