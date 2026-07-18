# License Scope: Qilin Game Framework

## Purpose

This directory contains the reusable Qilin quantum-game framework, controller
runtime, preview/release tooling, tests, technical documentation, generated
previews, and historical reference material.

## Ownership and intended license

Subject to final contributor and copyright-name review, these QArcade-authored
components are intended to be covered by root `LICENSE-CODE` (Apache-2.0):

```text
framework/qilin_game_framework_4Qv.p8
framework/qilin_game_framework_4Qh.p8
framework/qilin_game_framework_3Qv.p8
framework/AGENT.md
tools/**
tests/**
bootstrap/**
docs/**
preview_viewer.html
RENDER_PNG.bat
WATCH_PREVIEW.bat
requirements.txt
README.md
AGENTS.md
.gitignore
```

The framework cartridges are mixed works. Apache-2.0 applies to reusable
Qilin-authored framework code, but does not erase these exceptions:

- embedded MicroQiskit remains under upstream Apache-2.0 with IBM/Qiskit
  copyright and attribution notices preserved;
- game-owned levels, Mission canvas content, scoring/progression, Response visualization,
  game mechanics, and completion experience remain reserved until expressly
  designated as an open example; and
- externally adapted routines retain their source attribution and applicable
  license obligations.

The following are not currently included in the new Apache allowlist:

```text
reference/**
previews/**
release/**
.qilin-cache/**
.venv/**
```

The repository owner states that `reference/qilin.p8` comes from an upstream
repository they own. It remains reserved historical reference until an exact
copyright statement and release decision are recorded. Generated previews can
embody reserved game content. Local environments and caches are not release
artifacts.

## Contributions

Framework code contributions are submitted under Apache-2.0 when accepted.
Keep framework-owned and game-owned components distinct, follow `AGENTS.md`,
and document third-party sources. Content contributions require separate
license agreement before acceptance.
