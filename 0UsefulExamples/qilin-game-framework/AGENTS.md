# Qilin Agent Instructions

Before changing this framework, read:

- `README.md`
- `docs/QILIN_LAYOUT_CONTRACT.md`
- `docs/QILIN_AGENT_PREVIEW_WORKFLOW.md`
- `docs/QILIN_GAME_DESIGNER_GUIDE.md`

The authoritative cartridge is `framework/qilin_game_framework.p8`.

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

Start by copying the authoritative cartridge, then make only game-owned
changes in the copied `.p8`: levels, Mission text, scoring and progression,
Response visualization, game mechanics, and the completion experience. Keep
the framework-owned controller behavior stable unless explicitly requested.

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
