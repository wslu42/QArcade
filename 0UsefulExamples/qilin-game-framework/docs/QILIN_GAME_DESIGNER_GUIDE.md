# QILIN_GAME_DESIGNER_GUIDE.md

## Purpose

This guide is for a game designer who wants to create a new educational game using the Qilin controller framework.

The main idea is:

> keep the quantum controller framework stable, and use it as a reusable input system for new game ideas.

You do **not** need to redesign everything from scratch.

---

## High-Level Concept

A Qilin-based game has five official top-level layout blocks:

1. **Controller**
2. **Key Map**
3. **Operation Feedback**
4. **Mission**
5. **Response**

The design philosophy is:

- the **Controller** is the stable quantum input tool;
- the **Mission** explains what the player should do;
- the **Response** is the main game output space.

---

## PICO-8 Truth for Designers

When designing a new game, always think in **PICO-8 truth**.

That means:

- you are designing for a `128 × 128` pixel screen;
- every pixel matters;
- spacing should be deliberate and grid-friendly;
- colors should remain simple and readable;
- text should respect the PICO-8 aesthetic;
- previews are useful, but actual PICO-8 behavior is the final authority.

Do not design as if this were a full desktop UI.
Think like a compact pixel game.

---

# 1. What stays fixed

## 1.1 Controller is the framework anchor
The Controller is the reusable input framework.

Normally it should remain conceptually stable:
- the Controller Grid stays recognizable;
- qubit/depth interaction stays recognizable;
- the Key Map stays understandable;
- the designer does not have to rewrite the quantum input engine for every new game.

## 1.2 Layout names stay stable
Use the official names from `QILIN_LAYOUT_CONTRACT.md`.

This matters because you will likely work with an agent, and the agent needs precise references.

---

# 2. What you are expected to design

The two main designer-facing surfaces are:

## 2.1 Mission
Use this to tell the player:
- what the goal is;
- what action to try;
- what result they got.

Typical content:
- title of the challenge
- short hint
- success / retry message

## 2.2 Response
This is the main output canvas for the game concept.

In the current prototype, it shows sixteen compact state rooms.

In your future game, it could show:
- a puzzle board
- a maze
- an enemy state
- a platformer condition
- a door/unlock pattern
- a logic display
- an address decoder
- a state machine
- an educational simulation

Think of the Response as the place where quantum state affects gameplay.

---

# 3. How to think about the controller

The Controller should be treated as a **quantum controller**, not just a circuit composer.

That means the player is not editing a circuit for its own sake.

Instead, the player is:
- choosing operations;
- shaping a quantum state;
- causing a game-relevant response.

A useful mental model is:

```text
player input
→ Controller Grid
→ quantum state change
→ measurement / response
→ game behavior
```

## 3.1 PICO-8 button budget and portability

PICO-8 provides six standard buttons per player: Left, Right, Up, Down, O,
and X. `btn(b,pl)` accepts player indices 0 through 7, but a portable
single-player Qilin game must keep every required action on player 0. Player 1
controls may be useful for optional developer/debug shortcuts, but must not be
required for normal play on one gamepad, mobile controls, or the BBS player.

The default player-0 keyboard mapping uses arrow keys, Z/C/N for O, and X/V/M
for X. UI should therefore use PICO-8 O/X glyphs while a README may clarify
the common Z/X keyboard keys. Experimental devkit keyboard or mouse input is
optional only. See the [official PICO-8 Input documentation](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#Input).

All button combinations are accepted, but opposite D-pad directions are not
generally possible on physical controllers. Avoid requiring two simultaneous
directions. A face button plus one direction is portable and normally uses
one hand on each side of a controller.

The current vertical framework uses release-confirmed tap/hold input:
Left/Right selects a qubit, Down clears, Up runs, tap X appends X, hold X plus
Left/Right selects a cyclic CNOT target, and tap O appends H. The on-screen Key Map
draws the same compact gate glyphs as the Controller: circled plus for X,
compact H, and filled control dot connected to a circled-plus CNOT target.

All future framework-derived games must use this mapping by default. Every
player-facing surface must describe the same behavior: cartridge input,
Key Map / Operation Feedback, and the derived game's README. A game may adopt
a different input model only when explicitly requested; then update all three
surfaces and keep the CNOT endpoint meanings consistent.

## 3.2 Modal input and dialogue

Dialogue and overlays must own input while they are active. Each frame has one
owner, using this priority:

```text
completion > modal (including dialogue) > controller
```

This makes contextual button reuse safe. Right can advance dialogue while the
dialogue is visible, but remains qubit navigation during normal vertical
Controller play. It does not become a second global action for Right.

Route input through one dispatcher and return immediately after updating the
active completion screen or modal. Do not let dialogue and Controller code
both poll buttons in the same frame. When a modal closes, keep input locked
until its trigger button is released before returning ownership to the
Controller. This release handoff prevents the final dialogue press from also
moving the cursor or participating in X + Right CNOT targeting.

A dialogue adapter should therefore expose at least an active state and a
release-handoff state. Its exact implementation is game-owned, but it must not
alter the framework-owned tap X / hold X / tap O gate controls.

---

# 4. What 4 qubits give you

The current framework has **4 qubits**, which means:

```text
2^4 = 16 basis states
```

These sixteen states can encode information.

For design purposes, you can think of them as:
- sixteen addresses
- sixteen tiles
- sixteen rooms
- sixteen outputs
- sixteen lanes
- sixteen possible behaviors
- sixteen logical bins

This is one of the most important educational affordances of the framework.

The student does not need advanced quantum knowledge.
What matters is that they can see:

> changing quantum operations changes which states appear, and that changes game behavior.

## 4.1 Designing for all sixteen states

A 16-state game should use the fourth qubit as gameplay, not merely convert
old 3Q labels by adding a leading zero. Include objectives whose reachable
states exercise `q3`, such as `1111`, `1001`, or `1010`, and verify that their
solutions fit the available circuit depth.

Dense 16-lane designs must be planned as one visual system. At a 4-pixel lane
pitch, ordinary text and large sprites will overlap even if the lane lines
themselves fit. Choose compact state glyphs, actors, rewards, hazards, and
collision bounds together. Preserve full binary strings in Mission or hints
so compact glyphs do not weaken the educational connection to basis states.

Four-qubit level design must consider three constraints at the same time:

- circuit depth available for the intended solution;
- the full visual and scheduling span reserved by long CNOTs;
- whether the player can still read the target state and resulting Response.

It is reasonable to retain separate 3Q and 4Q examples. A 3Q version can
prioritize introductory clarity and larger objects, while a 4Q version can
demonstrate the complete 16-state design space.

---

# 5. Good design questions to ask

When designing a new game, ask:

## Mission design
- What do I want the player to achieve?
- What should Mission tell them?
- What hints are enough without over-explaining?

## Response design
- What should Response represent?
- Should I keep the histogram, or replace it with another visualization?
- How do measured outcomes influence the game?

## Educational design
- What quantum idea is visible through play?
- Can a student notice that different gates produce different behavior?
- Does the game teach cause-and-effect between operations and outcomes?

## UI design
- Is the layout readable on a 128×128 screen?
- Is the response area doing meaningful work?
- Is the Mission canvas content legible and contained within its bounds?

---

# 6. Good uses of Response

Strong uses include:
- showing how states map to outcomes;
- showing a compact puzzle surface;
- showing something that clearly reacts to `run`;
- making the measured distribution visually meaningful.

Weak uses include:
- wasting the space with decorative filler;
- duplicating information already obvious in the controller;
- putting too much tiny text there.

Response should earn its space.

---

# 7. Working with an Agent

The intended workflow is collaborative.

A good loop is:

```text
1. describe the game idea
2. ask the agent to update the cartridge
3. ask the agent to generate a preview PNG
4. inspect the preview
5. refine layout or behavior
6. repeat
```

This is why the preview workflow matters so much.

---

## Exact preview command

From the project root:

```bash
python tools/render_preview.py path/to/game.p8 \
  -o preview.png \
  --native-output preview_128x128.png
```

The default preview uses P8SCII glyph metrics and button-symbol bindings. It
also places representative X, CNOT, and H gates in the Controller; add
`--blank-controller` when reviewing a genuinely empty grid.
It should therefore show lowercase source strings with the same
uppercase-like visual behavior seen in PICO-8.

For a circuit-state mockup:

```bash
python tools/render_preview.py path/to/game.p8 \
  --gate q1:d1:h \
  --gate q1:d2:cx:q2 \
  -o preview_after_edit.png
```

For a response-state mockup:

```bash
python tools/render_preview.py path/to/game.p8 \
  --counts '{"000":8,"011":8}' \
  -o preview_after_run.png
```


# 8. When to ask for previews

You should ask the agent to regenerate a preview whenever:
- text changes;
- layout changes;
- response visuals change;
- controller visuals change;
- a new game mechanic affects the visible screen.

Useful requests include:

- “Generate a blank-state preview.”
- “Generate a preview after adding one X gate.”
- “Generate a preview after run.”
- “Generate before/after PNGs so I can compare layout.”

---

# 9. What to tell the agent

When you work with an agent, try to use precise layout names.

Good examples:
- “Move Mission down 2 px.”
- “Reduce the gap between Controller and Key Map.”
- “Keep the Controller fixed, but redesign the Response Canvas.”
- “Replace the histogram in Response with a simple tile board.”

Less helpful:
- “Move the bottom part”
- “Change the text area”
- “Fix the composer stuff”

Precision makes collaboration faster.

---

# 10. Suggested design boundaries

A good working boundary is:

## Framework-owned
- Controller
- Controller behavior
- Key Map behavior
- layout contract infrastructure
- preview tooling

## Designer-owned
- Mission wording
- challenge sequence
- educational pacing
- Response Canvas concept
- game-specific visual logic

This division keeps the framework reusable.

---

# 11. What not to overdo

Because the target is a small pixel screen, avoid:
- too many lines of text;
- overly dense legends;
- tiny decorative details;
- UI complexity that fights readability.

Clarity matters more than visual flourish.

The priority order should be:

1. educational clarity
2. playability
3. code simplicity
4. visual polish

---

# 12. Recommended first experiments

If you are designing a new Qilin-based game, good first experiments are:

1. **Addressing game**
   - use the 8 states as addresses;
   - player learns how X / H / CNOT affect state reachability.

2. **Routing game**
   - use state distributions to route outputs.

3. **Matching game**
   - player tries to produce a target distribution or target pattern.

4. **Mini puzzle board**
   - each basis state maps to a tile or object.

These work well because they use the 4-qubit / 16-state structure directly.

---

# 13. Example versus standalone project

Before implementation, confirm the folder name, cartridge filename, Response
concept, and whether the deliverable is a simple example or a standalone
project.

## 13.1 Simple example — default

Unless the user requests otherwise, create:

```text
0UsefulExamples/
└── ex_GAME_TITLE_/
    ├── ex_GAME_TITLE.p8
    └── README.md
```

Copy `framework/qilin_game_framework_4Qv.p8` into the new folder as the starting
cartridge and rename it to match the game. Apply game-owned changes to that
copy. The README should be written for players and explain the premise,
objective, controls, and basic quantum mechanic.

Use the existing framework preview tools during development when useful, but
do not copy generated previews or framework infrastructure into the example.

## 13.2 Standalone project — only when requested

Copy preview tools, tests, documentation, scripts, and other infrastructure
only when the user explicitly asks for a self-contained or independently
distributable project.

---

# 14. Final reminder

The preview system is part of the design workflow, but:

> **PICO-8 is still the final source of truth.**

Use previews to iterate quickly.
Use live cartridge behavior to confirm the final result.

---

# Repository source selection

For work on the reusable framework itself, always edit and preview:

```text
framework/qilin_game_framework_4Qv.p8
```

For a derived example, its copied and renamed `.p8` cartridge becomes the
authoritative game file. The framework cartridge remains the source template
and must not receive game-specific behavior.

Use the original cartridge only for reference:

```text
reference/qilin.p8
```

The versioned Lua file is a readable mirror, not the authoritative cartridge.
