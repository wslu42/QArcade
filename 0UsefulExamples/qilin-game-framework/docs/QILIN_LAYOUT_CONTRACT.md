# Qilin Layout Contract

## Scope

This document defines the normal gameplay layout of the current framework
source of truth:

```text
framework/qilin_game_framework.p8
```

The original upstream `reference/qilin.p8` is not the layout source of truth.

## PICO-8 truth

- Screen: `128 × 128` integer pixels.
- Rectangles use inclusive endpoints when drawn by PICO-8 primitives.
- Normalized layout dimensions use true width/height:

```text
right  = x + w - 1
bottom = y + h - 1
```

- Use the default PICO-8 palette unless the cartridge explicitly changes it.
- Use P8SCII metrics and glyph bindings for preview text.
- Native PICO-8 output is authoritative if a static preview differs.

## Coordinate rule

```text
screen position = Area Origin + Cluster Origin + Local Offset
```

## Area hierarchy

```text
Screen
├── Controller Area
│   ├── Controller Operation Feedback
│   ├── Controller Core Group
│   │   ├── Controller Grid
│   │   ├── Qubit Wires (derived from the grid)
│   │   ├── Depth Index
│   │   ├── Depth Flow Indicator
│   │   ├── Qubit Index
│   │   └── Qubit Selector
│   └── Key Map Group
├── Mission Area
│   ├── Mission Title
│   ├── Mission Instruction
│   └── Mission Feedback
└── Quantum Response Area
    ├── Response Legend
    ├── Response Canvas
    └── State Index
```

# 1. Controller Area

The Controller Area is a composite coordinate group. Its origin is:

```text
(0, 0)
```

## 1.1 Controller Core Group

The source expresses the origin as:

```lua
x=14-8
y=11-4
```

Effective origin:

```text
(6, 7)
```

Normalized bounds currently required by its children:

```text
x=6..48
y=7..63
w=43
h=57
```

## 1.2 Controller Grid

Local origin inside Controller Core Group:

```text
(0, 0)
```

The source stores `cell_w=8` and `cell_h=8` as inclusive far-edge offsets.
The normalized preview schema converts them to true dimensions:

```text
cell_w=9
cell_h=9
col_pitch=11
row_pitch=11
```

Screen cell ranges:

```text
q1: x=6..14
q2: x=17..25
q3: x=28..36

D4: y=7..15
D3: y=18..26
D2: y=29..37
D1: y=40..48
```

## 1.3 Qubit Wires

Qubit Wires are derived visual elements, not an independent cluster.

Current derived geometry:

```text
x=10,21,32
y=5..50
```

They must follow Controller Grid origin, cell dimensions, pitch, and depth.

## 1.4 Depth Index

Source-local values:

```lua
x=32
y=0
text_dy=2
```

Effective anchors:

```text
D4 (38,9)
D3 (38,20)
D2 (38,31)
D1 (38,42)
```

The preview normalizer aliases `text_dy` to canonical `text_y`.

## 1.5 Depth Flow Indicator

Source-local values:

```lua
x=34
y=0
gap_dy=-2
```

Effective anchors:

```text
(40,16)
(40,27)
(40,38)
```

The preview normalizer aliases `gap_dy` to canonical `gap_y`.

## 1.6 Qubit Index

Source-local values:

```lua
x=0+1
y=45
```

Effective anchors:

```text
q1 (7,52)
q2 (18,52)
q3 (29,52)
```

## 1.7 Qubit Selector

Source-local values:

```lua
x=2+1
y=51
```

Effective anchors:

```text
q1 (9,58)
q2 (20,58)
q3 (31,58)
```

Only the selected marker is drawn.

## 1.8 Key Map Group

The Key Map is one cluster with flat item offsets. It is not divided into row
clusters.

Source origin:

```lua
x=62-4
y=11-4
```

Effective origin and declared bounds:

```text
origin=(58,7)
x=58..123
y=7..28
w=66
h=22
```

Items remain relative to that origin:

```lua
{text="🅾️⬆️ x",        x=0,  y=0}
{text="🅾️⬇️ h",        x=33, y=0}
{text="🅾️⬅️/🅾️➡️ cnot", x=0,  y=8}
{text="⬇️ clr",         x=8,  y=16}
{text="❎ run",         x=41, y=16}
```

# 2. Mission Area

Source origin:

```lua
x=56
y=44-8
```

Effective origin:

```text
(56,36)
```

The source declares `h=22`, while its Feedback cluster ends at local `y=24`.
The normalized contract expands the Area to contain all children:

```text
x=56..127
y=36..60
w=72
h=25
```

Clusters:

```text
Mission Title:       local (0,0),  screen y=36..41
Mission Instruction: local (0,10), screen y=46..51
Mission Feedback:    local (0,19), screen y=55..60
```

# 3. Quantum Response Area

The Quantum Response Area remains one full rectangle:

```text
origin=(0,68)
size=128×60
bounds x=0..127, y=68..127
```

It includes its reserved top region, visible response content, and bottom
padding.

## 3.1 Response Legend

```text
local origin=(0,18)
screen y=86..91
```

## 3.2 Response Canvas

```text
local origin=(2,28)
screen bounds x=2..127, y=96..112
base y=112
state pitch=16
normalized target bar width=9
normalized measured bar width=5
```

## 3.3 State Index

The source declares `x=1` and subtracts one pixel at draw time. The normalized
contract represents the effective position directly:

```text
local origin=(0,49)
screen y=117..122
state pitch=16
```

# Naming discipline

Use these names in future layout requests. For example:

- “Move the Controller Core Group 2 px right.”
- “Move the Key Map Group up 1 px.”
- “Move the Mission Area, not the Quantum Response Area.”
- “Adjust the Depth Index without moving the Depth Flow Indicator.”

If a request is ambiguous, the agent should correct the terminology and offer
the likely official names before changing the cartridge.
