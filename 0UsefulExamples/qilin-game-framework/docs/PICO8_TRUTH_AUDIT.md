# PICO-8 Truth Audit — Compact Qilin Framework

## Source audited

The default authoritative cartridge is:

```text
framework/qilin_game_framework_4Qv.p8
```

`qilin_game_framework_3Qv.p8` is the compact 3Q variant and
`qilin_game_framework_4Qh.p8` is the optional horizontal 4Q variant.
`qilin_game_framework_3Qv_pvp.p8` is the maintained two-player specialization.
`reference/qilin.p8` is historical reference material only.

## Current vertical 4Q Response-first contract

```text
Response:           (0,0),   128 x 78
Mission:            (0,78),   86 x 26
Operation Feedback: (0,104),  86 x 6
Key Map:            (0,110),  86 x 18
Controller:         (86,78),  42 x 50
```

Response is deliberately first in the visual hierarchy and receives the full
upper screen. The framework controls occupy the lower band: narrative and
feedback are on the left, while the compact Controller anchors the right.

Every maintained single-player Controller declares `anchor="bottom_right"`. The complete
Controller content envelope is anchored, including Grid, Depth Index, Qubit
Index, and Qubit Selector. A variant with fewer qubits moves its grid and
Qubit labels right; a variant with fewer circuit depths moves its grid and
Depth labels down. The unused space therefore accumulates at the upper-left,
while Q/D labels remain adjacent to the occupied grid.
The PVP P1 Controller's documented `bottom_left` mirror is the sole maintained
anchor exception.

The Controller contains four `7 x 7` qubit columns and five depths on an
8-pixel pitch. Columns alternate colors 13 and 6; each qubit label uses its
column color. Gates and CNOT connectors use color 1, selection uses yellow 10,
and blocked feedback uses red 8. X shares the circled-plus CNOT-target glyph,
H is code-drawn, and the obsolete depth-flow marks are absent.

The Key Map follows the cartridge's release-confirmed tap/hold controls and
reuses the same X, H, and CNOT shapes as the Controller. Button glyphs use
`key_map.color=6`; gate symbols plus the `run` / `clr` labels use
`control_examples.color=13`. X/H/Run occupy the first aligned row;
CNOT/Clear occupy the second. The Python renderer reads both colors and all
coordinates from the layout table.

The selected-qubit caret is a code-drawn 3-by-2 pixel glyph declared as
`style="pixel_caret"`. Its explicit height participates in parent-bound
normalization; the renderer does not reserve the old six-pixel font height.
Level and game initialization always select internal `q0` (`cursor_q=0`).

Mission is one developer-owned `86 x 26` canvas. It has no required title,
instruction, or feedback children; the cartridge's `draw_mission()` is only a
clipped example that derived games may replace.

Dialogue and overlays must use one input owner per frame. The required
priority is `completion > modal > handoff > O+X mode chord > controller`.
The release handoff must finish before Controller input resumes. O is the standard
dialogue confirm/advance button; Right is not the default advance action.

## Renderer behavior

The fallback renderer follows a 128 x 128 native integer-pixel canvas, the
PICO-8 default palette, P8SCII bitmap glyphs, and nearest-neighbor scaling.
With no `--gate` arguments it adds representative X, CNOT, and H gates to the
preview only. Explicit `--gate` arguments replace them;
`--blank-controller` disables them.

The one-click maintained outputs are:

```text
previews/current.png
previews/current_128x128.png
previews/current.json
```

The one-click render and watch scripts currently track
`qilin_game_framework_3Qv_pvp.p8` while that specialization is under active
layout development. This tooling target does not change the default
`qilin_game_framework_4Qv.p8` source of truth. Layout reviews cover the named
single-player artifacts `framework_4Qv`, `framework_3Qv`, and `framework_4Qh`,
plus the PVP artifact when its two-Controller shell is in scope.

## Current PVP specialization

The PVP cartridge uses a `128 x 94` Response and a 34-pixel lower band split
exactly into P1 Controller `29 x 34`, Key Map `70 x 34`, and P2 Controller
`29 x 34`. Both Controllers use three qubits, three depths, visible `7 x 7`
cells, separate player-indexed state, and q0 initialization. P1 mirrors the
Depth Index to the far left; P2 retains it at the far right.

The center Key Map stacks Run/Clear, X/H, and CNOT. The inherited Mission and
Operation Feedback layout tables are not rendered. The fallback renderer and
guided-preview tool explicitly recognize both Controller blocks. See
`QILIN_3QV_PVP_CONTRACT.md` for the full accepted PVP contract.

## Authority boundary

The fallback renderer is not a complete emulator. Native PICO-8 remains
authoritative for input timing, animation, runtime palette/font changes,
sprites, maps, sound, and arbitrary Lua paths. After framework visual or input
changes, regenerate and inspect the guided preview, run the tests, and verify
native PICO-8 when available.
