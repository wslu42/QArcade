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

The original `reference/qilin.p8` is not the current framework layout source of
truth.

---

## PICO-8 truth

- Screen size: **128 × 128 px**.
- Layout coordinates are integer pixel coordinates.
- Area bounds use true dimensions:

```text
right  = x + w - 1
bottom = y + h - 1
```

- Preview renderings should follow **PICO-8 / P8SCII text behavior** as closely
  as possible.
- If a static PNG and native PICO-8 output disagree, **native PICO-8 behavior is
  authoritative**.

---

## Coordinate rule

```text
screen position = area origin + cluster origin + local offset
```

---

## Official layout names

```text
Screen
├── Controller Area
│   ├── Controller Core Group
│   │   ├── Controller Grid
│   │   ├── Qubit Wires (derived)
│   │   ├── Depth Index
│   │   ├── Depth Flow Indicator
│   │   ├── Qubit Index
│   │   └── Qubit Selector
│   ├── Key Map Group
│   └── Controller Operation Feedback
├── Mission Area
│   ├── Mission Title
│   ├── Mission Instruction
│   └── Mission Feedback
└── Quantum Response Area
    ├── Response Legend
    ├── Response Canvas
    └── State Index
```

---

## Area summary table

| Area / Group | Short name | Origin `(x,y)` | Size `(w×h)` | Primary purpose |
|---|---|---:|---:|---|
| Controller Area | `controller` | `(0,0)` | `128×66` | Upper control workspace that contains the composer, key map, and immediate operation feedback. |
| Controller Core Group | `controller core` | `(6,7)` | `40×59` | Main composer block where the student places gates on qubits across circuit depth. |
| Key Map Group | `key map` | `(58,7)` | `66×22` | Persistent input legend that teaches button-to-action mapping. |
| Controller Operation Feedback | `feedback` | `(58,30)` | `66×6` | Short-lived immediate feedback for the last controller action, blocked action, or newly placed gate. |
| Mission Area | `mission` | `(46,36)` | `82×30` | Mission-facing text area for objective, hint/instruction, and result summary. |
| Quantum Response Area | `response` | `(0,66)` | `128×62` | Lower visualization area that shows the target distribution, measured distribution, and state labels. |

---

## Semantic purpose contract

### Controller Operation Feedback (`feedback`)

Use this for **immediate controller-level feedback**, such as:

- the most recently placed gate,
- a blocked/invalid input,
- a short action confirmation.

This is **not** the mission narrative area.
It should stay short, reactive, and closely tied to user input.

### Mission Area (`mission`)

Use this for **game / level communication**, such as:

- mission title or level name,
- what the player is trying to achieve,
- hint text,
- pass / retry / next messaging.

This is the semantic replacement for the older “game identity” concept.
It is the **instructional and outcome** text block.

### Quantum Response Area (`response`)

Use this for **state/output visualization** only, such as:

- legend (`target`, `measured`),
- bar / marker visualization across quantum states,
- state labels (`000` … `111`).

It is one **single rectangular area** and includes its reserved empty space.

---

# 1. Controller Area

## 1.1 Controller Area

```text
origin=(0,0)
size=128×66
bounds x=0..127, y=0..65
```

The Controller Area is the upper control workspace and contains three official
subgroups:

1. **Controller Core Group**
2. **Key Map Group**
3. **Controller Operation Feedback**

## 1.2 Controller Core Group

Source values:

```lua
x=14-8
y=11-4
w=40
h=59
```

Effective values:

```text
origin=(6,7)
size=40×59
bounds x=6..45, y=7..65
```

Purpose:
- The playable composer/composer-grid region.
- Students use it to place gates across qubits and depth.

## 1.3 Controller Grid

Local origin inside Controller Core Group:

```text
(0,2)
```

Stored source values:

```lua
cell_w=8
cell_h=8
col_pitch=11
row_pitch=11
```

PICO-8 drawing interpretation:
- `cell_w=8` and `cell_h=8` are used as inclusive far-edge offsets.
- So each visible box is **9×9 px**.

Effective cell columns:

```text
Q1 column x=6..14
Q2 column x=17..25
Q3 column x=28..36
```

Effective depth rows:

```text
D4 y=9..17
D3 y=20..28
D2 y=31..39
D1 y=42..50
```

## 1.4 Qubit Wires

Qubit Wires are **derived** from Controller Grid geometry.
They do **not** have their own independent layout variables.

Derived wire anchors:

```text
x=10, 21, 32
y=7..52
```

Purpose:
- visually connect the depth cells within each qubit column.

## 1.5 Depth Index

Source-local values:

```lua
x=32
y=2
text_dy=2
```

Effective anchors:

```text
D4 at (38,11)
D3 at (38,22)
D2 at (38,33)
D1 at (38,44)
```

Purpose:
- labels the vertical depth rows.

## 1.6 Depth Flow Indicator

Source-local values:

```lua
x=34
y=2
gap_dy=-2
```

Effective anchors:

```text
^ markers at:
(40,18)
(40,29)
(40,40)
```

Purpose:
- indicates vertical depth progression between depth rows.

## 1.7 Qubit Index

Source-local values:

```lua
x=0+1
y=47
```

Effective anchors:

```text
Q1 at (7,54)
Q2 at (18,54)
Q3 at (29,54)
```

Purpose:
- labels the qubit columns.

## 1.8 Qubit Selector

Source-local values:

```lua
x=2+1
y=53
```

Effective anchors:

```text
selector row origin=(9,60)
Q1 marker at x=9
Q2 marker at x=20
Q3 marker at x=31
```

Purpose:
- shows the currently selected qubit column.

## 1.9 Key Map Group

Source values:

```lua
x=62-4
y=11-4
w=66
h=22
```

Effective values:

```text
origin=(58,7)
size=66×22
bounds x=58..123, y=7..28
```

Purpose:
- visible controller legend.
- teaches the player what each button combination does.

Current item offsets:

```lua
{text="🅾️⬆️ x",        x=0,  y=0}
{text="🅾️⬇️ h",        x=33, y=0}
{text="🅾️⬅️/🅾️➡️ cnot", x=0,  y=8}
{text="⬇️ clr",         x=8,  y=16}
{text="❎ run",         x=41, y=16}
```

## 1.10 Controller Operation Feedback

Source values:

```lua
x=62-4
y=30
w=66
h=6
```

Effective values:

```text
origin=(58,30)
size=66×6
bounds x=58..123, y=30..35
```

Purpose:
- immediate, action-coupled feedback line,
- for example: latest placed gate, blocked action, or controller response.

---

# 2. Mission Area

Source values:

```lua
x=46
y=36
w=82
h=30
```

Effective values:

```text
origin=(46,36)
size=82×30
bounds x=46..127, y=36..65
```

Purpose:
- communicates the mission,
- explains what the student should achieve,
- reports pass / retry / next progress.

## 2.1 Mission Title

```text
local origin=(0,0)
size=82×6
screen bounds x=46..127, y=36..41
```

Purpose:
- level title / mission title.

## 2.2 Mission Instruction

```text
local origin=(0,10)
size=82×6
screen bounds x=46..127, y=46..51
```

Purpose:
- active instruction or hint.

## 2.3 Mission Feedback

```text
local origin=(0,19)
size=82×6
screen bounds x=46..127, y=55..60
```

Purpose:
- mission-level result summary such as score / retry / next.

---

# 3. Quantum Response Area

Source values:

```lua
x=0
y=66
w=128
h=62
```

Effective values:

```text
origin=(0,66)
size=128×62
bounds x=0..127, y=66..127
```

Purpose:
- the full lower response rectangle,
- contains both used and reserved response space,
- owns legend, canvas, and state labels.

## 3.1 Response Legend

```text
local origin=(0,20)
size=128×6
screen bounds x=0..127, y=86..91
```

Purpose:
- explains `target` and `measured` encodings.

Legend item anchors:

```text
target box x=3
target text x=10
measured box x=53
measured text x=60
```

## 3.2 Response Canvas

```text
local origin=(2,30)
size=126×17
screen bounds x=2..127, y=96..112
```

Additional drawing values:

```text
base_y=112
first_state_x=0
state_pitch=16
```

Purpose:
- draws the target and measured response for each computational basis state.

## 3.3 State Index

```text
local origin=(1,51)
size=127×6
screen bounds x=1..127, y=117..122
```

Additional values:

```text
state_pitch=16
```

Purpose:
- labels the response states:
  `000`, `001`, `010`, `011`, `100`, `101`, `110`, `111`.

---

## Naming discipline

Use these names when making future layout requests.

Examples:

- “Move the **Controller Core Group** 1 px down.”
- “Widen the **Mission Area** to the left.”
- “Keep the **Quantum Response Area** rectangular.”
- “Change the **Controller Operation Feedback** but do not move the **Mission Area**.”
- “Adjust the **Depth Flow Indicator** without moving the **Depth Index**.”

If a request is ambiguous, the agent should correct the terminology first and
then apply the change.
