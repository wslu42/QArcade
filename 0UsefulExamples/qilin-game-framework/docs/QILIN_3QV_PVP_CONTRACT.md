# Qilin 3Qv PVP Contract

## Status and source

The maintained two-player specialization is:

```text
framework/qilin_game_framework_3Qv_pvp.p8
```

It is derived from the vertical 3Q Controller but is not the default framework
source of truth. `qilin_game_framework_4Qv.p8` remains the canonical starting
point for ordinary single-player games. Use the PVP cartridge when two players
need independent quantum Controllers on one screen.

## Screen allocation

PVP replaces the single-player lower-band composition with a symmetric
three-block control band:

| Block | Origin | Size | Inclusive bounds |
|---|---:|---:|---:|
| Response | `(0,0)` | `128 x 94` | `x=0..127, y=0..93` |
| P1 Controller | `(0,94)` | `29 x 34` | `x=0..28, y=94..127` |
| Key Map | `(29,94)` | `70 x 34` | `x=29..98, y=94..127` |
| P2 Controller | `(99,94)` | `29 x 34` | `x=99..127, y=94..127` |

The widths sum exactly to 128 pixels. Mission and Operation Feedback tables
remain in the cartridge only as inherited compatibility metadata; `_draw()`
does not render them. Their former screen area belongs to the taller Response.

## Controller geometry

Both players have three qubits and three circuit depths. Cells occupy `7 x 7`
visible pixels on an 8-pixel pitch. The source layout records the inclusive
cell extent as `cell_w=6` and `cell_h=6`.

- P1 uses `layout.controller_left`, `anchor="bottom_left"`, and
  `player="p1"`. Its Depth Index is on the far left.
- P2 uses `layout.controller`, `anchor="bottom_right"`, and `player="p2"`.
  Its Depth Index is on the far right.
- Qubit Index and the pixel-caret Qubit Selector sit below each grid.
- Mirroring changes the label side, not internal qubit meaning or circuit
  compilation order.
- Both cursors initialize to internal `q0`.

The P1 bottom-left anchor is an explicit PVP exception. The maintained
single-player Controllers continue to use the canonical bottom-right anchor.

## Player state and input

The cartridge keeps independent Controller state for each player, including
grid, cursor, fresh/blocked feedback, held-button history, and pending X/H/CX
state. It activates the relevant player state before updating or drawing that
Controller.

- P1 reads `btn/btnp(button,0)`.
- P2 reads `btn/btnp(button,1)`.
- Run and Clear act on the active player's circuit.
- A run updates the shared Response with the most recently measured circuit.
- Shared completion, modal, chord, and release-handoff ownership must consume
  both players and wait until every standard button is released.

The portable cartridge API remains the six PICO-8 buttons. Keyboard choices
belong to PICO-8 `KEYCONFIG`, not hard-coded raw keyboard reads.

## PVP Key Map

The center Key Map is a three-row, stacked layout and reuses the same code-drawn
gate symbols as the Controllers:

1. Run: `Up/e`; Clear: `Down/d`.
2. X: `X/a` plus the circled-plus X glyph; H: `O/sf` plus the H glyph.
3. Hold-X plus the qubit axis, followed by the CNOT control/target glyph.

Here `Up`, `Down`, `X`, and `O` refer to the P1 PICO-8 button symbols; the
letters after the slash show the compact P2 default-keyboard hints used by the
cartridge artwork. They are display hints only. The recommended shared-keyboard
remap remains P1=`WASD + F(O)/G(X)` and P2=`Arrows + K(O)/L(X)` when a custom
`KEYCONFIG` is desired.

## Preview and verification

The fallback renderer recognizes both Controller tables, reconstructs the
mirrored P1 Controller, clears the obsolete single-player lower band, and
draws the PVP Key Map from layout data. Guided preview labels are
`controller p1`, `key map`, `controller p2`, and `response`.

At the current development checkpoint, `RENDER_PNG.bat` and
`WATCH_PREVIEW.bat` track `qilin_game_framework_3Qv_pvp.p8`. This is a preview
target choice, not a change to the default 4Qv source-of-truth designation.

After layout or input changes:

1. render both guided and native-size PNGs;
2. inspect both Controller edges and all three Key Map rows;
3. run `python -m unittest discover -s tests -v`;
4. verify two-player timing in native PICO-8 when available.
