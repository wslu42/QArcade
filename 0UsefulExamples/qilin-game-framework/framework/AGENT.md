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
`completion > modal (including dialogue) > controller`; higher-priority update
branches return before Controller input runs. When a modal closes, wait for its
trigger button to be released before returning ownership to the Controller;
this required transition is the release handoff.
Contextual reuse such as Right-to-advance is valid only while the modal owns
input and must not change the release-confirmed gate mapping.

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
matter. The five official top-level blocks are:

| Block | Bounds |
|---|---|
| Controller | `x=0..36, y=0..50` |
| Key Map | `x=37..127, y=0..18` |
| Operation Feedback | `x=37..127, y=19..24` |
| Mission | `x=37..127, y=25..50` |
| Response | `x=0..127, y=51..127` |

The Controller is compact and highly structured. Response is the main
creative canvas, with the full 128-pixel width and 74 pixels of height. It
should show a meaningful consequence of measurement instead of repeating
information already visible in the Controller.

Mission is a single developer-owned `91 x 26` canvas with no required title,
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
