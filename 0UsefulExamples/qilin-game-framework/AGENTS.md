# Qilin Agent Instructions

Before changing this framework, read:

- `README.md`
- `docs/QILIN_LAYOUT_CONTRACT.md`
- `docs/QILIN_AGENT_PREVIEW_WORKFLOW.md`
- `docs/QILIN_GAME_DESIGNER_GUIDE.md`
- `docs/QILIN_RESERVED_INPUT_MATRIX.md`
- `docs/QILIN_3QV_PVP_CONTRACT.md` when working on multiplayer/PVP

The default authoritative cartridge is `framework/qilin_game_framework_4Qv.p8`.
Use `framework/qilin_game_framework_4Qh.p8` when the horizontal Controller
orientation is explicitly selected.

The authoritative single-player screen allocation is Response-first: a `128 x 78` Response
at the top, with Mission, Operation Feedback, Key Map, and Controller sharing
the lower band. Do not restore the former Controller-first top region or the
`y=51` Response arrangement in active variants or derived games.
The maintained PVP exception is governed by `docs/QILIN_3QV_PVP_CONTRACT.md`.

All active framework variants and future derived games use the framework-owned
tap/hold control contract: tap X commits X on release; hold X plus the visual
qubit axis selects a cyclic CNOT target and release commits it; tap O commits
H on release; directions select qubits when X is not held; the remaining axis
provides Run and Clear. Do not restore modifier-first gate entry. Only
`reference/qilin.p8` preserves upstream controls as historical evidence.
The canonical context-by-context reservations are in
`docs/QILIN_RESERVED_INPUT_MATRIX.md`; keep every control summary consistent
with that table.

Dialogue, completion screens, and other overlays use modal input ownership.
Exactly one owner consumes buttons per frame, with priority
`completion > modal > handoff > O+X mode chord > controller`. Higher-priority
branches return before Controller input runs, and closing a modal requires a
release handoff before the Controller regains input. PICO-8 O (`btnp(4)`) is
the standard dialogue confirm/advance input through `modal_confirm_pressed()`;
Right is not the default dialogue advance button.
O+X is reserved
for a future traditional/quantum control-mode switch; it fires only after both
buttons are released and must cancel pending H, X, and CNOT input.
In Classical gameplay, O and X remain game-owned individually, but their
actions must be chord-safe: prefer release-confirmed actions, or make press-time
actions pending and cancellable. Never perform an irreversible O/X action on
press unless it can be rolled back when the second face button forms O+X;
detecting the chord cancels both pending single-button actions.

PVP cartridges use the standard six-button API for every player:
`btn/btnp(button,0)` for P1 and `btn/btnp(button,1)` for P2, with independent
controller state. Keep QWERTY suggestions outside gameplay logic and use
PICO-8 `KEYCONFIG` for remapping. Raw/devkit keyboard input is optional only;
never require it or use it to replace the portable Controller contract.
Multiplayer modal handoff waits for every player's standard buttons to be up.
When player-facing setup guidance is useful, recommend the shared-keyboard
`KEYCONFIG` preset P1=`WASD + F(O)/G(X)` and
P2=`Arrows + K(O)/L(X)`. Treat it as host configuration, never as hard-coded
cartridge input.

The maintained PVP specialization is
`framework/qilin_game_framework_3Qv_pvp.p8`. It uses a `128 x 94` Response and
a `29 + 70 + 29` pixel lower band containing P1 Controller, stacked Key Map,
and P2 Controller. P1's explicit `bottom_left` anchor mirrors only the
Depth-Index side; it is an exception to the single-player bottom-right rule.
Do not render the inherited Mission or Operation Feedback tables in this PVP
shell. Preserve separate grids, cursors, held/release histories, and pending
gate state for both players.

When a derived game benefits from dialogue, proactively consider the existing
Oli414 Dialogue Text Box (DTB) implementation in `reference/qilin.p8` as an
optional starting point; the human developer does not need to request DTB by
name. DTB is reference code, not a drop-in framework component: adapt its fixed
coordinates, 29-character wrapping, drawing region, and input polling to the
current Mission bounds and modal-input/release-handoff contract before use.

Follow the framework-owned versus game-owned boundary documented in
`docs/QILIN_AGENT_PREVIEW_WORKFLOW.md`. Do not add preview-only metadata or
behavior to the cartridge.

## Creating derived game examples

When asked to create a game based on this framework, do not copy this entire
framework directory unless the user explicitly requests a standalone project.

The default example structure is:

```text
0UsefulExamples/
└── ex_GAME_TITLE_/
    ├── ex_GAME_TITLE.p8
    └── README.md
```

Start by copying the selected authoritative variant, then make only game-owned
changes in the copied `.p8`: levels, Mission canvas content, scoring and progression,
Response visualization, game mechanics, and the completion experience. Keep
the framework-owned controller behavior stable unless explicitly requested.

If an explicit request replaces Controller or other framework-owned behavior
inside a derived game, follow the "Derived-game cleanup and handoff contract"
in `docs/QILIN_AGENT_PREVIEW_WORKFLOW.md`. Remove obsolete implementation
paths and stale control documentation after verifying they are game-local;
dead PICO-8 code still consumes the cartridge token budget.

Write a player-facing README with a short introduction, objective, controls,
and basic explanation of the quantum gameplay. Do not copy framework tooling,
tests, caches, previews, release folders, or framework documentation into a
simple example folder.

After visual or layout changes:

1. Update the authoritative cartridge.
2. Update the static fallback renderer only when required by the documented
   preview contract.
3. Generate and inspect the guided preview.
4. Run the test suite.
5. Verify the cartridge in native PICO-8 before treating the preview as exact.

Controller labels are grid-anchored geometry, not free-positioned decoration.
Every active cartridge initializes and resets the Controller cursor to
internal `q0` (`cursor_q=0`); do not substitute the last qubit or a visual
row/column index.
Maintained single-player Controllers declare `anchor="bottom_right"`; the complete grid and
label group must remain anchored to the Controller's lower-right corner.
The PVP P1 Controller is the documented `bottom_left` mirror exception.
Whenever `num_qubits`, `circuit_depth`, cell dimensions, or grid pitch changes,
recalculate Qubit Index, Qubit Selector, and Depth Index from the occupied grid
bounds. Run the layout parser tests; they enforce the orientation-specific
label adjacency rules documented in `docs/QILIN_LAYOUT_CONTRACT.md`.
