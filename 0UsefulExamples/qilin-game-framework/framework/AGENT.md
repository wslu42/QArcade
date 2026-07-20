# Agent Experience with the Qilin Game Framework

This note summarizes what I learned by reading the Qilin framework guidance
and using it to create the derived example **Quantum Firefly Garden**.

## The central idea

Qilin works best when the Controller is treated as a stable quantum input
device, not as the whole game. The player places X, H, and CX operations,
shapes a quantum state, runs the circuit, and sees the measurement become
a visible game consequence.

```text
player input
-> Controller
-> quantum state and measurement
-> Response
-> game behavior
```

The default 4Q framework provides sixteen basis states; the compact 3Q variant
provides eight. A designer can interpret those states as rooms, tiles, lanes,
targets, flowers, or other objects. This
mapping is the framework's strongest creative and educational feature.

## Source-of-truth discipline

The authoritative reusable cartridge is:

```text
framework/qilin_game_framework_4Qv.p8
```

`reference/qilin.p8` and `qilin_game_framework.p8` are historical material.
Neither replaces the authoritative compact framework cartridge.

For a derived game, copy the authoritative cartridge into a small example
folder and rename it. That copy becomes the source of truth for the new game.
Game-specific behavior should not be added to the reusable framework.

## Framework-owned and game-owned behavior

Deciding who owns a feature before editing makes the work much safer.

Framework-owned behavior includes:

- MicroQiskit simulation and measurement
- circuit compilation
- Controller Grid and qubit selection
- X, H, and CX input behavior
- Key Map and Operation Feedback
- layout parsing and preview tooling

The required input vocabulary is release-confirmed tap/hold: tap X adds X,
hold X plus the visible qubit axis selects and commits CNOT on release, and
tap O adds H. Future derived games inherit it; modifier-first gate entry is
historical reference behavior only.

Dialogue, completion screens, and other overlays must use modal input
ownership. Exactly one system consumes buttons per frame, with priority
`completion > modal > handoff > O+X mode chord > controller`; higher-priority update
branches return before Controller input runs. When a modal closes, wait for its
trigger button to be released before returning ownership to the Controller;
this required transition is the release handoff.
PICO-8 O (`btnp(4)`) is the standard dialogue confirm/advance input through
`modal_confirm_pressed()`. Right may be game-owned modal navigation, but is not
the default advance action and must not change the Controller mapping.

O+X is the reserved traditional/quantum control-mode chord: both buttons must be released
before `request_control_mode_switch()` runs, and the dispatcher cancels any
pending H, X, or CNOT first. Derived games implement that game-owned hook only
when they actually provide a second control mode.

Classical-mode O and X are otherwise game-owned, but must follow the same
chord-safe principle as the release-confirmed gate model. Confirm a standalone
O/X action on release, or keep its press-time effect pending and cancellable.
If the second face button forms O+X, cancel both pending single-button actions;
do not commit an irreversible action on the first button press.

PVP variants keep separate Controller state per player and read the portable
six-button API with `btn/btnp(button,0)` for P1 and
`btn/btnp(button,1)` for P2. Do not hard-code a recommended QWERTY layout into
cartridge logic; players remap those buttons with PICO-8 `KEYCONFIG`. Treat
raw/devkit keyboard input as an optional fallback only. Shared modal handoff
must wait until both players release every standard button.
The recommended shared-keyboard `KEYCONFIG` preset is
P1=`WASD + F(O)/G(X)` and P2=`Arrows + K(O)/L(X)`. Present it only as host
setup guidance; cartridge code continues to poll player-indexed buttons.

The maintained `qilin_game_framework_3Qv_pvp.p8` specialization uses a taller
`128 x 94` Response above a `29 + 70 + 29` pixel control band. P1 is a
bottom-left mirror with Depth Index on the far left; P2 is bottom-right with
Depth Index on the far right. Both Controllers are `29 x 34`, three-qubit,
three-depth devices, and the center `70 x 34` Key Map stacks Run/Clear, X/H,
and CNOT across three rows. See `../docs/QILIN_3QV_PVP_CONTRACT.md` before
changing its geometry or input ownership.

For game dialogue, agents should proactively consider the Oli414 Dialogue
Text Box (DTB) preserved in `../reference/qilin.p8`, even when the human
developer does not mention DTB. Treat it as adaptable reference code rather
than a drop-in component: replace its fixed coordinates and 29-character wrap
width with Mission-relative values, clip it to Mission, and route its input
through the modal owner plus release handoff.

Game-owned behavior includes:

- levels and educational pacing
- Mission canvas content
- scoring and progression
- Response visualization
- game-specific mechanics and theme
- completion experience

While creating Firefly Garden, I kept the simulator and Controller unchanged.
I replaced the levels, Mission content, histogram-style Response, and ending
with a garden in which eight flowers represent the eight measured states.

## Layout lessons

The screen is exactly `128 x 128`, so text length and single-pixel geometry
matter. The five official single-player top-level blocks are:

| Block | Bounds |
|---|---|
| Response | `x=0..127, y=0..77` |
| Mission | `x=0..85, y=78..103` |
| Operation Feedback | `x=0..85, y=104..109` |
| Key Map | `x=0..85, y=110..127` |
| Controller | `x=86..127, y=78..127` |

The Controller is compact and highly structured. Response is the main
creative canvas, with the full 128-pixel width and 78 pixels of height. It
should show a meaningful consequence of measurement instead of repeating
information already visible in the Controller.

Maintained single-player Controllers declare `anchor="bottom_right"`. This anchors the
complete Grid and label envelope to the Controller's lower-right corner:
fewer qubit columns move the Grid, Qubit Index, and Qubit Selector right;
fewer circuit depths move the Grid and Depth Index down. Qubit and depth
labels are structural grid extensions, so their fixed adjacency must be
recalculated and tested whenever qubit count, circuit depth, cell size, or
pitch changes.

The PVP P1 Controller is the deliberate exception: it declares
`anchor="bottom_left"` so the two Controller shells mirror one another. This
does not change the single-player anchor contract.

Every active cartridge initializes and resets the Controller cursor to
internal `q0` (`cursor_q=0`), independent of its visual orientation.

Mission is a single developer-owned `86 x 26` canvas with no required title,
instruction, or feedback children. Replace `draw_mission()` with game-specific
text, dialogue, icons, or progress, and keep drawing clipped to Mission bounds.

Official layout names should be used in discussion. A request such as
"redesign Response" or "move Mission down two pixels" is clearer than a
reference to the "bottom" or "text area."

## Game-design lessons

A strong Qilin game gives each measured outcome a concrete meaning. Changing
the circuit should visibly change the world, and the relationship should be
understandable without requiring advanced quantum theory.

A useful educational progression is:

1. X demonstrates exact addressing.
2. H introduces multiple possible outcomes.
3. CX demonstrates correlated outcomes.
4. Later missions combine those ideas with less guidance.

Superposition targets require scoring tolerance because finite-shot
measurement is sampled. Deterministic missions can require an exact result,
while evenly split distributions should accept reasonable variation.

Design priorities should be:

1. educational cause and effect
2. playability
3. code simplicity
4. visual decoration

## Preview experience

Previewing belongs inside the edit loop. The most useful minimum set contains
an initial state, a circuit-edited state, and a post-measurement state.
Previews help expose text overflow, layout mistakes, gate-highlight problems,
and unclear target-versus-measured presentation.

The Python fallback renderer has an important limitation: it is static. It
parses layout and game state from the cartridge but does not execute the
cartridge's `_draw()` function. If a derived game replaces the histogram with
a custom Response, the fallback can still validate Controller, Key Map,
Mission, and block geometry, but it cannot prove the custom drawing is exact.

Adding every example's themed visualization to the reusable renderer would
mix game-specific presentation into framework tooling. A simple derived game
should therefore use the fallback preview to validate the shared contract and
native PICO-8 to verify its custom Response. If the two disagree, native
PICO-8 is authoritative.

Preview-only fields or behavior should never be added to a cartridge.

## Recommended workflow for future agents

1. Read `AGENTS.md`, the framework README, layout contract, designer guide,
   and preview workflow in full.
2. Confirm whether the deliverable is a derived example or a standalone
   project.
3. Select the authoritative cartridge correctly.
4. Define what the selected variant's basis states mean in the game.
5. Define how Response turns measurements into visible consequences.
6. Copy only the cartridge for a simple derived example.
7. Preserve framework-owned simulation and Controller behavior.
8. Implement the levels, Mission, scoring, Response, and completion state.
9. Keep all text short and every drawing operation within `128 x 128`.
10. Render and inspect initial, edited, and measured preview states.
11. Run `python -m unittest discover -s tests -v`.
12. Validate game-specific invariants, including target totals and text width.
13. Verify custom behavior and visuals in native PICO-8.
14. Write a player-facing README describing the premise, objective, controls,
    and basic quantum mechanic.

## Final perspective

The framework's constraints are useful creative prompts. Keeping the
Controller stable reduces implementation risk and gives players a consistent
quantum vocabulary. The designer can then focus on turning an abstract state
distribution into a compact, readable, reactive game world.
