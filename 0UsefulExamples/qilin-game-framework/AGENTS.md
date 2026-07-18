# Qilin Agent Instructions

Before changing this framework, read:

- `README.md`
- `docs/QILIN_LAYOUT_CONTRACT.md`
- `docs/QILIN_AGENT_PREVIEW_WORKFLOW.md`
- `docs/QILIN_GAME_DESIGNER_GUIDE.md`

The default authoritative cartridge is `framework/qilin_game_framework_4Qv.p8`.
Use `framework/qilin_game_framework_4Qh.p8` when the horizontal Controller
orientation is explicitly selected.

The authoritative screen allocation is Response-first: a `128 x 78` Response
at the top, with Mission, Operation Feedback, Key Map, and Controller sharing
the lower band. Do not restore the former Controller-first top region or the
`y=51` Response arrangement in active variants or derived games.

All active framework variants and future derived games use the framework-owned
tap/hold control contract: tap X commits X on release; hold X plus the visual
qubit axis selects a cyclic CNOT target and release commits it; tap O commits
H on release; directions select qubits when X is not held; the remaining axis
provides Run and Clear. Do not restore modifier-first gate entry. Only
`reference/qilin.p8` preserves upstream controls as historical evidence.

Dialogue, completion screens, and other overlays use modal input ownership.
Exactly one owner consumes buttons per frame, with priority
`completion > modal (including dialogue) > controller`. Higher-priority
branches return before Controller input runs, and closing a modal requires a
release handoff before the Controller regains input. Contextual Right-to-advance
is valid only while dialogue owns input; it does not replace Controller Right.

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
