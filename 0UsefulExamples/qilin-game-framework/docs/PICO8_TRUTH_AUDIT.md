# PICO-8 Truth Audit — Compact Qilin Framework

## Source audited

The default authoritative cartridge is:

```text
framework/qilin_game_framework_4Qv.p8
```

`qilin_game_framework_3Qv.p8` is the compact 3Q variant and
`qilin_game_framework_4Qh.p8` is the optional horizontal 4Q variant.
`reference/qilin.p8` is historical reference material only.

## Current vertical 4Q Response-first contract

```text
Response:           (0,0),   128 x 78
Mission:            (0,78),   91 x 26
Operation Feedback: (0,104),  91 x 6
Key Map:            (0,110),  91 x 18
Controller:         (91,78),  37 x 50
```

Response is deliberately first in the visual hierarchy and receives the full
upper screen. The framework controls occupy the lower band: narrative and
feedback are on the left, while the compact Controller anchors the right.

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

Mission is one developer-owned `91 x 26` canvas. It has no required title,
instruction, or feedback children; the cartridge's `draw_mission()` is only a
clipped example that derived games may replace.

Dialogue and overlays must use one modal input owner per frame. The required
priority is `completion > modal (including dialogue) > controller`, followed
by a release handoff before Controller input resumes. Right may advance
dialogue only while dialogue owns input.

## Renderer behavior

The fallback renderer follows a 128 x 128 native integer-pixel canvas, the
PICO-8 default palette, P8SCII bitmap glyphs, and nearest-neighbor scaling.
With no `--gate` arguments it adds representative X, CNOT, and H gates to the
preview only. Explicit `--gate` arguments replace them;
`--blank-controller` disables them.

The normal maintained outputs are:

```text
previews/current.png
previews/current_128x128.png
previews/current.json
```

Both render and watch scripts use `qilin_game_framework_4Qv.p8`. Superseded
variant snapshots are not maintained in `previews/`.

## Authority boundary

The fallback renderer is not a complete emulator. Native PICO-8 remains
authoritative for input timing, animation, runtime palette/font changes,
sprites, maps, sound, and arbitrary Lua paths. After framework visual or input
changes, regenerate and inspect the guided preview, run the tests, and verify
native PICO-8 when available.
