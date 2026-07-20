# Qilin Layout Contract

## Scope

This document records the accepted compact gameplay layout. The authoritative
cartridge is:

```text
framework/qilin_game_framework_4Qv.p8
```

`reference/qilin.p8` is historical reference material only. Native PICO-8
output remains authoritative if a static preview differs.

## Coordinate and sizing rules

- Screen: `128 x 128` integer pixels.
- Top-level blocks use screen coordinates.
- Child coordinates are relative to their parent.
- Layout `w` and `h` are true dimensions: `right=x+w-1` and `bottom=y+h-1`.
- Source `cell_w=6` and `cell_h=6` are inclusive PICO-8 offsets and normalize
  to visible `7 x 7` cells.
- The preview normalizer may expand a parent that is too small for its
  children. It never shrinks an explicitly larger parent.

## Single-player top-level blocks

| Block | Origin | Size | Bounds |
|---|---:|---:|---:|
| Response | `(0,0)` | `128 x 78` | `x=0..127, y=0..77` |
| Mission | `(0,78)` | `86 x 26` | `x=0..85, y=78..103` |
| Operation Feedback | `(0,104)` | `86 x 6` | `x=0..85, y=104..109` |
| Key Map | `(0,110)` | `86 x 18` | `x=0..85, y=110..127` |
| Controller | `(86,78)` | `42 x 50` | `x=86..127, y=78..127` |

These five rectangles are the major guided-preview outlines. This is the
Response-first configuration: the game-specific output owns the full upper
screen, while framework controls share the lower band.

## Controller

### Grid-anchored label invariant

Qubit Index, Qubit Selector, and Depth Index are structural extensions of the
Controller Grid. They must remain adjacent to the occupied grid, even when a
variant changes `num_qubits`, `circuit_depth`, cell dimensions, or pitch. Their
coordinates must therefore be recalculated from the grid bounds; copying label
coordinates from a differently sized grid is invalid.

Every maintained single-player Controller declares `anchor="bottom_right"`. This applies to
the complete Controller content group, not the grid alone: vertical layouts
reserve the right edge for Depth Index and the bottom edge for Qubit Index plus
Qubit Selector. Fewer qubit columns move the grid and its Q labels to the right;
fewer depth rows move the grid and its depth labels down.

For a normalized vertical Controller (`cell_w` and `cell_h` are true visible
dimensions):

```text
grid_bottom = grid.y + (circuit_depth - 1) * row_pitch + cell_h - 1
qubit_index.y = grid_bottom + 2
qubit_selector.y = qubit_index.y + 6
depth_index.y + text_y = grid.y + 1
depth_index.x + 4 = controller.w - 1
qubit_index.x = grid.x
qubit_selector.x = grid.x + 2
```

This leaves exactly one empty pixel between the last grid row and the Qubit
Index. Each depth digit remains vertically centered on its grid row. A shorter
depth stack is bottom-anchored by moving `grid.y` and `depth_index.y` together,
not by leaving the labels detached at the Controller bottom.

For the horizontal Controller:

```text
grid_bottom = grid.y + (num_qubits - 1) * row_pitch + cell_h - 1
depth_index.y = grid_bottom + 2
depth_index.x = grid.x + 2
qubit_index.x + 8 = grid.x - 1
qubit_index.y = grid.y + 1
qubit_selector.x = qubit_index.x + 2
qubit_selector.y = qubit_index.y + 5
grid_right = controller.w - 2
```

These equations preserve the accepted one-pixel Qubit Index and Depth Index
gaps. `tests/test_layout_parser.py` checks these invariants across
every maintained framework and derived cartridge.

### Grid

```lua
grid={
  x=5,
  y=1,
  cell_w=6,
  cell_h=6,
  col_pitch=8,
  row_pitch=8
}
```

Normalized cells are `7 x 7`. An 8-pixel pitch leaves a one-pixel gutter in
both directions. Alternating column fills replace permanent cell borders.

Effective columns:

```text
q3 x=91..97
q2 x=99..105
q1 x=107..113
q0 x=115..121
```

Effective rows:

```text
5 y=79..85
4 y=87..93
3 y=95..101
2 y=103..109
1 y=111..117
```

The old qubit-wire/time-flow arrow graphics were removed. Sequence is shown
by the compact bottom-to-top depth ordering and the adjacent numeric labels.

### Depth labels

```text
Depth Index: local (37,2), text offset y=0
```

Depth labels are the single digits `5, 4, 3, 2, 1`. No Depth Flow Indicator
is drawn; bottom-to-top ordering and the numeric labels communicate sequence.

### Qubit labels and selector

```text
Qubit Index:    local (5,41)
Qubit Selector: local (7,47), size 3 x 2, style pixel_caret
```

The selector is drawn with three pixels and ends at local y=48. Its explicit
height replaces the former six-pixel font assumption. The Controller ends at
screen y=127, using the full lower-right corner without crossing the screen.

### Grid drawing and highlights

Adjacent columns alternate colors 13 and 6; their qubit labels use the same
color. Gates and committed CNOT connectors use color 1. Selection uses yellow
10 and blocked labels use red 8. X shares the circled-plus target glyph, while
H uses a compact code-drawn mark.

## Key Map

```text
origin=(0,110)
size=86 x 18
```

The Key Map is a top-level block, not a child of Controller. It holds the
button-to-gate, clear, and run instructions. It must follow the active input
code and reuse the Controller's gate notation:

| Input | Key Map glyph/action |
|---|---|
| Tap X | circled plus (X) |
| Hold X + Left/Right | filled control dot connected to circled-plus target (CNOT) |
| Tap O | compact H |
| Up | run circuit |
| Down | clear selected qubit |

Gate glyph and action-label coordinates live in `key_map.control_examples`,
so native cartridge drawing and the fallback renderer consume the same layout
contract. The Key Map uses two aligned rows: X, H, Run on the first; CNOT and
Clear on the second. Button glyphs remain separate entries in `key_map.items`.
This separation is required because buttons use the Key Map text color while
gate symbols and the `run` / `clr` labels share `control_examples.color`.
The button color is configured by `key_map.color`; it is independent from
`control_examples.color`.

All three framework variants share the same Key Map function slots inside the
86-pixel block. Only the directional button text rotates with orientation:

```text
button items:  (2,2), (30,2), (59,2), (2,10), (59,10)
X example:     (10,1)
H example:     (39,1)
CX endpoints:  (39,9) -> (47,9)
Run label:     (69,2)
Clear label:   (69,10)
```

Vertical variants show Left/Right for qubit/CNOT selection and Up/Down for
Run/Clear. The horizontal variant shows Up/Down for qubit/CNOT selection and
Right/Left for Run/Clear. Slot geometry remains identical.

The compact 4Q vertical controller uses a custom `pixel_caret` qubit selector.
Its `w=3` and `h=2` are explicit layout dimensions; parent-bound normalization
uses that declared height instead of assuming the six-pixel font height of a
printed `^`. Older text-caret layouts default to `w=4`, `h=6`, and
`style="text_caret"`.

## Operation Feedback

```text
origin=(0,104)
size=86 x 6
```

This line reports successful gate placement or a blocked action. It is
separate from developer-owned Mission content.

## Mission

```text
origin=(0,78)
size=86 x 26
```

Mission is one developer-owned canvas. The layout contract intentionally has
no required `title`, `instruction`, or `feedback` children. Games replace
`draw_mission()` with dialogue, scrolling text, icons, progress, or any other
content that fits the rectangle. The framework's default `draw_mission()` is
only a three-line example and clips all drawing to Mission bounds.

This structure is compatible with a region-parameterized dialogue text box.
The historical Oli414 DTB must still replace its fixed screen coordinates and
29-character wrap width with Mission-relative values, and dialogue input must
be modal so its confirm button does not also place a gate.

## Response

```text
origin=(0,0)
size=128 x 78
```

The Response uses a `4 x 4` room grid. Each room is `29 x 16` pixels with a
column pitch of 31 and row pitch of 18. Its local origin is `(3,3)`, balancing
the remaining horizontal space and the odd-pixel vertical remainder. The
sixteen state labels are:

```text
0000 0001 0010 0011
0100 0101 0110 0111
1000 1001 1010 1011
1100 1101 1110 1111
```

### Dense 16-lane Response pattern

`0UsefulExamples/photon_runner/photon_runner_4Qv.p8` is the tested reference
for displaying all sixteen states as simultaneous horizontal lanes. A
`128 x 78` Response with a 4-pixel lane pitch is usable, but is near the
vertical density limit: labels, actors, collectibles, hazards, and collision
geometry must all be designed for the same pitch.

Use a compact Qilin-style four-bit glyph when full `0000` text would consume
too much lane width. The tested glyph contract is:

- bits run left-to-right as `q3 q2 q1 q0`;
- `1` is a bright three-pixel-high vertical bar;
- `0` is a dim single pixel on the lower baseline;
- one empty pixel separates adjacent bits, so four bits occupy 7 pixels;
- color and shape both encode the value; do not rely on color alone.

Keep complete binary text in Mission, hints, or temporary feedback for
teaching and confirmation. The compact glyph is the persistent spatial index,
not a replacement for every textual state reference.

### Compact five-depth Controller pattern

All maintained single-player Qilin variants use the authoritative Response-first shell:
a `128 x 78` upper Response, an 86-pixel lower-left region, and a `42 x 50`
lower-right Controller. The default 4Qv and 3Qv
framework cartridges use five circuit depths. Derived cartridges may use a
shorter bottom-anchored stack, and the horizontal 4Qh variant uses four depths.
3Q variants preserve the same outer allocation while drawing only their
applicable qubit columns.

The compact vertical pattern is bottom-right anchored. The five-depth 3Q
framework cartridge keeps `grid.y=1`, `depth_index.y=2`, and Qubit Index
`y=41`, matching 4Qv vertically. Its three-column grid begins at `x=13`, with
Depth Index at `x=37`; 4Qv begins at `x=5`. The one-column difference is one
8-pixel pitch, so both variants share the same right and bottom content edges.

Its grid uses inclusive `cell_w=6` and `cell_h=6` offsets, producing visible
`7 x 7` cells on an 8-pixel column and row pitch. One-pixel gutters replace
permanent cell borders. Adjacent qubit columns alternate colors 13 and 6;
each `q3 q2 q1 q0` label uses the same color as the column directly above it.
The selected qubit label and selector use yellow 10, blocked labels use red 8,
and gate symbols use color 1.

Small code-drawn glyphs replace the built-in font inside the grid. H uses a
3-by-3 mark. X reuses the same 5-by-5 circled-plus glyph as a CNOT target:
an isolated circled plus means X, while a circled plus connected to a filled
control dot means CNOT. This shared quantum notation removes the dedicated X
glyph and keeps the endpoint language consistent.

Depth Index shows `5, 4, 3, 2, 1` in color 6. The former Depth Flow Indicator
is omitted; bottom-to-top row order and the numeric index already communicate
sequence. This permits five depths within the 50-pixel lower-right Controller
while keeping the qubit labels and selector below the grid.

The vertical variants use an explicit 3-by-2 pixel caret. Compactness comes
from dedicated glyphs, shared symbols, gutters, and selective state
highlighting rather than from shrinking the CNOT endpoints below legibility.

## Horizontal 4Q variant

`framework/qilin_game_framework_4Qh.p8` uses a rotated Controller while
preserving the same simulator, queue, controls, Mission, and 16-room Response.
Its Controller uses the shared `42 x 50` shell at `(86,78)`; Mission,
Operation Feedback, and Key Map occupy the 86-pixel lower-left column at
y=`78`, `104`, and `110`.
Response remains the shared `128 x 78` upper canvas. Circuit depths `1>2>3>4` run left-to-right along the bottom, and qubit
labels `q3 q2 q1 q0` run top-to-bottom along the left side.

The vertical and horizontal cartridges are separate source variants. Derived
games should copy one variant and keep its orientation stable.

The horizontal directional axis rotates with the Controller: tap X adds X,
hold X plus Up/Down selects a CNOT target, tap O adds H, Up/Down selects a
qubit row while X is not held, Left clears, and Right runs.

## Two-player 3Qv specialization

`framework/qilin_game_framework_3Qv_pvp.p8` is the maintained PVP exception to
the five-block single-player shell. It expands Response to `128 x 94` and uses
the remaining 34-pixel band as three edge-to-edge blocks:

| Block | Origin | Size | Bounds |
|---|---:|---:|---:|
| P1 Controller | `(0,94)` | `29 x 34` | `x=0..28, y=94..127` |
| Key Map | `(29,94)` | `70 x 34` | `x=29..98, y=94..127` |
| P2 Controller | `(99,94)` | `29 x 34` | `x=99..127, y=94..127` |

Both Controllers contain three qubits and three depths, with visible `7 x 7`
cells on an 8-pixel pitch. P1 declares `anchor="bottom_left"` and places Depth
Index at the far left. P2 declares `anchor="bottom_right"` and places Depth
Index at the far right. Qubit Index and Qubit Selector remain below both
grids. The mirror changes label placement only; q0 remains q0 and both cursors
initialize to it.

The center Key Map stacks three rows: Run/Clear, X/H, then CNOT. It reuses the
Controller's X, H, control-dot, connector, and target-plus drawing functions.
Mission and Operation Feedback declarations are inherited compatibility data
and are not drawn by the PVP `_draw()` path.

Full PVP geometry, input-state isolation, keyboard-hint policy, and preview
requirements are defined in
[`QILIN_3QV_PVP_CONTRACT.md`](QILIN_3QV_PVP_CONTRACT.md).

## Controller input contract

The canonical context-by-context reservation table is
[`QILIN_RESERVED_INPUT_MATRIX.md`](QILIN_RESERVED_INPUT_MATRIX.md). The
sections below explain the Controller implementation behind that table.

### Current implemented mappings

All active framework cartridges use the release-confirmed tap/hold model.
Every level load, restart, and new-game initialization selects internal
`q0` (`cursor_q=0`). Orientation changes only where q0 is drawn: it is the
rightmost column in vertical layouts and the bottom row in 4Qh. Do not derive
the initial cursor from `num_qubits-1` or from a visual column/row index.

Vertical 4Q:

| Input | Action |
|---|---|
| Left/Right | Select qubit column |
| Down | Clear selected qubit |
| Tap X | Append X on release |
| Hold X + Left/Right | Select cyclic CNOT target; release to commit |
| Tap O | Append H on release |
| Up | Run |

Horizontal 4Q rotates the directional mapping with the Controller:

| Input | Action |
|---|---|
| Up/Down | Select qubit row |
| Left | Clear selected qubit |
| Tap X | Append X on release |
| Hold X + Up/Down | Select cyclic CNOT target; release to commit |
| Tap O | Append H on release |
| Right | Run |

### Tap/hold state-machine requirement

Tap/hold is framework-owned and is the required default for future derived
games. X and O commit on release. Pressing X locks the control qubit; fresh
direction presses move a cyclic pending target. Releasing X commits X when no
target movement occurred, commits one CNOT when target differs, or cancels
when the target returned to the control. Direction selects qubits only while
X is not held. A new game may change this only when explicitly requested, and
must then update cartridge input, Key Map, Operation Feedback, README, and
renderer-facing layout together.

### Modal input ownership requirement

Every frame must have exactly one input owner. The required priority is:

```text
completion > modal > handoff > O+X mode chord > controller
```

The highest active owner consumes the frame's buttons and returns before a
lower-priority owner updates. PICO-8 O (`btnp(4)`) is the standard dialogue
confirm/advance input and is exposed through `modal_confirm_pressed()`. Right
may be used for game-owned modal navigation, but is not the default dialogue
advance action.

Closing an overlay requires a release handoff. The controller must not regain
input until the button that closed or advanced the modal has been released;
otherwise that same press can pass through and move a qubit, select a CNOT
target, place a gate, clear, or run. This rule applies to dialogue, completion
screens, tutorials, pause screens, and any game-specific overlay.

Use an explicit dispatcher rather than letting independent systems poll the
same buttons:

```lua
function active_input_owner()
  if game_complete then return "completion" end
  if modal_input_active() then return "modal" end
  if input_handoff then return "handoff" end
  if mode_chord or (btn(4) and btn(5)) then
    return "mode_chord"
  end
  return "controller"
end

function _update()
  local owner=active_input_owner()
  if owner=="completion" then
    update_completion()
    return
  elseif owner=="modal" then
    update_modal_input()
    return
  elseif owner=="handoff" then
    update_input_handoff()
    return
  elseif owner=="mode_chord" then
    update_mode_chord()
    return
  end
  update_controller()
end
```

Modal integration must preserve the framework's release-confirmed X tap/hold
state machine. Do not change the gate mapping to work around an input conflict.

### Implemented dispatcher and reserved mode chord

The maintained 3Qv, 4Qv, 4Qh, and 3Qv PVP variants implement this runtime order:

```text
completion > modal > handoff > O+X mode chord > controller
```

`modal_input_active()` and `update_modal_input()` are the game-owned dialogue
integration points. `begin_input_handoff()` cancels pending H/X/CNOT state;
the handoff owner consumes frames until all six standard PICO-8 buttons are
released. This protects transitions triggered by face buttons or directions.
In PVP, the owner checks both player indices and handoff does not finish until
all six standard buttons are up for both players.

O+X is reserved for switching between a game's traditional controls and the
Quantum Controller. The chord latches whenever both face buttons are held,
cancels pending gate state, waits until both buttons are released, and then
calls `request_control_mode_switch()`. The base hook is intentionally empty so
framework demos remain in Quantum Controller mode while still proving that
the reserved chord cannot place a gate. Modal ownership outranks the chord, so
dialogue input cannot switch modes accidentally.

Standalone O and X remain game-owned in Classical mode, but their actions must
be chord-safe. Confirm them on release, or keep press-time effects pending and
cancellable. Detecting O+X in either order cancels both pending single-button
actions before the mode-switch hook runs; an irreversible Classical action
must not commit on the first face-button press.

Regardless of input style, CNOT control remains a filled circle, its target a
circled plus, and its committed connector uses color 1. The scheduling model
reserves the full linear span between endpoints at one depth; crossing or
nested spans are rejected, and clearing a CNOT control or target removes it.

## Naming discipline

Use these names in future layout requests:

- Controller
- Controller Grid
- Depth Index
- Qubit Index
- Qubit Selector
- Key Map
- Operation Feedback
- Mission
- Response

Regenerate a guided preview after any geometry change and confirm final
behavior in native PICO-8.
