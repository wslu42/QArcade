# QILIN_LAYOUT_CONTRACT

## Scope

This document defines the current layout contract for the gameplay framework.

**Framework source of truth**

```text
framework/qilin_game_framework.p8
```

**Readable Lua mirror**

```text
framework/qilin_quantum_router_v49_user_adjusted_layout.lua
```

The original `reference/qilin.p8` is reference material only.

---

## Schema audit and naming decision

The previous schema had a full-screen-width parent named `controller` at
`(0,0,128,66)`, but that parent did not draw or own a visible outline. The
actual composer geometry lived one level below it. That outer parent was only a
coordinate wrapper and is therefore removed from the active contract.

The actual composer is now named **Controller** directly:

```text
controller = former nested composer content
```

The Key Map and Operation Feedback are independent top-level layout blocks.
There is no active nested composer name and no full-width controller wrapper.

Current top-level layout blocks:

```text
controller
key_map
operation_feedback
mission
response
```

---

## PICO-8 truth

- Screen size: **128 × 128 px**.
- Layout coordinates are integer pixel coordinates.
- Area bounds use true dimensions:

```text
right  = x + w - 1
bottom = y + h - 1
```

- Preview renderings should follow PICO-8 / P8SCII text behavior as closely as
  possible.
- Native PICO-8 behavior is authoritative when a static preview disagrees.

---

## Coordinate rule

All current top-level blocks use screen-space coordinates directly:

```text
screen position = block origin + local element offset
```

---

## Official layout hierarchy

```text
Screen
├── Controller
│   ├── Controller Grid
│   ├── Qubit Wires (derived)
│   ├── Depth Index
│   ├── Depth Flow Indicator
│   ├── Qubit Index
│   └── Qubit Selector
├── Key Map
├── Operation Feedback
├── Mission
│   ├── Mission Title
│   ├── Mission Instruction
│   └── Mission Feedback
└── Response
    ├── Response Legend
    ├── Response Canvas
    └── State Index
```

---

## Top-level layout contract

| Block | Display label | Origin `(x,y)` | Size `(w×h)` | Purpose |
|---|---|---:|---:|---|
| Controller | `controller` | `(6,7)` | `40×59` | Composer where the player places gates across qubits and circuit depth. |
| Key Map | `key map` | `(58,7)` | `66×22` | Persistent input legend for button-to-action mappings. |
| Operation Feedback | `feedback` | `(58,30)` | `66×6` | Immediate confirmation or blocked-action feedback tied to controller input. |
| Mission | `mission` | `(46,36)` | `82×30` | Level title, current instruction/hint, and mission-level result summary. |
| Response | `response` | `(0,66)` | `128×62` | Target/measured visualization and computational-basis state labels. |

These are the five guide rectangles that the preview renderer must display.

---

# 1. Controller

```text
origin=(6,7)
size=40×59
bounds x=6..45, y=7..65
```

Purpose:
- the playable composer,
- gate placement across three qubits and four depth rows,
- qubit selection and depth labels.

## 1.1 Controller Grid

Local origin:

```text
(0,2)
```

Stored values:

```lua
cell_w=8
cell_h=8
col_pitch=11
row_pitch=11
```

The cartridge uses `cell_w` and `cell_h` as inclusive far-edge offsets, so the
visible cells are 9×9 px.

Effective cell columns:

```text
Q1 x=6..14
Q2 x=17..25
Q3 x=28..36
```

Effective depth rows:

```text
D4 y=9..17
D3 y=20..28
D2 y=31..39
D1 y=42..50
```

## 1.2 Qubit Wires

Qubit wires are derived from grid geometry and have no independent layout
block.

```text
wire x anchors = 10, 21, 32
wire y span    = 7..52
```

## 1.3 Depth Index

```lua
x=32
y=2
text_dy=2
```

Effective text anchors:

```text
D4 (38,11)
D3 (38,22)
D2 (38,33)
D1 (38,44)
```

## 1.4 Depth Flow Indicator

```lua
x=34
y=2
gap_dy=-2
```

Effective marker anchors:

```text
(40,18)
(40,29)
(40,40)
```

## 1.5 Qubit Index

```lua
x=1
y=47
```

Effective anchors:

```text
Q1 (7,54)
Q2 (18,54)
Q3 (29,54)
```

## 1.6 Qubit Selector

```lua
x=3
y=53
```

Effective anchors:

```text
Q1 x=9
Q2 x=20
Q3 x=31
y=60
```

---

# 2. Key Map

```text
origin=(58,7)
size=66×22
bounds x=58..123, y=7..28
```

Purpose:
- teaches the controller mappings,
- remains visible while the player edits the circuit.

Current item offsets:

```lua
{text="🅾️⬆️ x",        x=0,  y=0}
{text="🅾️⬇️ h",        x=33, y=0}
{text="🅾️⬅️/🅾️➡️ cnot", x=0,  y=8}
{text="⬇️ clr",         x=8,  y=16}
{text="❎ run",         x=41, y=16}
```

---

# 3. Operation Feedback

```text
origin=(58,30)
size=66×6
bounds x=58..123, y=30..35
```

Purpose:
- latest placed gate,
- blocked or invalid action,
- short controller-input confirmation.

This is not mission narrative or score feedback.

---

# 4. Mission

```text
origin=(46,36)
size=82×30
bounds x=46..127, y=36..65
```

Purpose:
- level title,
- current objective or hint,
- pass/retry/next result summary.

## 4.1 Mission Title

```text
local origin=(0,0)
size=82×6
screen bounds x=46..127, y=36..41
```

## 4.2 Mission Instruction

```text
local origin=(0,10)
size=82×6
screen bounds x=46..127, y=46..51
```

## 4.3 Mission Feedback

```text
local origin=(0,19)
size=82×6
screen bounds x=46..127, y=55..60
```

---

# 5. Response

```text
origin=(0,66)
size=128×62
bounds x=0..127, y=66..127
```

Purpose:
- target distribution,
- measured distribution,
- basis-state labels,
- reserved lower-response space.

The Response remains one rectangular top-level block.

## 5.1 Response Legend

```text
local origin=(0,20)
size=128×6
screen bounds x=0..127, y=86..91
```

Legend anchors:

```text
target box x=3
target text x=10
measured box x=53
measured text x=60
```

## 5.2 Response Canvas

```text
local origin=(2,30)
size=126×17
screen bounds x=2..127, y=96..112
base_y=112
first_state_x=0
state_pitch=16
```

## 5.3 State Index

```text
local origin=(1,51)
normalized screen origin x=0
size=127×6
screen bounds x=0..126, y=117..122
state_pitch=16
```

Labels:

```text
000 001 010 011 100 101 110 111
```

---

## Naming discipline

Use only these active block names in future layout requests:

- Controller
- Key Map
- Operation Feedback
- Mission
- Response

Examples:

- “Move the Controller 1 px down.”
- “Reduce the gap between Controller and Key Map.”
- “Widen Mission to the left.”
- “Keep Response rectangular.”
- “Change Operation Feedback without moving Mission.”
