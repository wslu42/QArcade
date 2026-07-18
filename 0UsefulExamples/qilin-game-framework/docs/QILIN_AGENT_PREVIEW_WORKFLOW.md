# QILIN_AGENT_PREVIEW_WORKFLOW.md

## Purpose

This document defines the preview workflow for Qilin-based cartridges.

Its goal is to let an agent and a game designer co-work effectively by producing **fast visual previews** of the current cartridge state without requiring manual PICO-8 inspection for every change.

The expected artifact is a **PNG preview**.

---

## Core Principle

Preview generation is a **first-class framework capability**.

It is not an optional convenience feature.

The preview workflow is part of the normal design loop:

```text
edit cartridge
→ generate preview
→ inspect layout
→ revise
→ regenerate preview
```

## Agent operating boundary

Before changing this framework, read:

- `README.md`
- `docs/QILIN_LAYOUT_CONTRACT.md`
- `docs/QILIN_AGENT_PREVIEW_WORKFLOW.md`
- `docs/QILIN_GAME_DESIGNER_GUIDE.md`

The authoritative cartridge is:

```text
framework/qilin_game_framework_4Qv.p8
```

Do not treat `reference/qilin.p8`, the readable Lua mirror, or generated PNG
previews as authoritative. Native PICO-8 behavior is final when it differs
from the Python preview.

Framework-owned components:

- MicroQiskit simulation;
- quantum circuit compilation and measurement;
- Controller Grid, gate placement, and qubit selection;
- X, H, and CX input behavior;
- modal input ownership and release handoff;
- Key Map and Operation Feedback;
- layout parsing and preview tooling.

Game-owned components:

- level definitions;
- Mission canvas content;
- scoring and progression;
- Response visualization;
- game-specific mechanics;
- completion experience.

Keep the Controller stable unless the task explicitly requests a framework
change. Mission is one developer-owned canvas with no required child schema;
it may contain objectives, dialogue, icons, or progress. Response is the
primary game-specific output surface. Operation Feedback is only for immediate
controller actions, not mission narrative or scoring. Change the Key Map only
when the actual controls also change.

The current shared geometry is Response-first: Response occupies `(0,0)` at
`128 x 78`; the lower band begins at y=78. In the default vertical variant,
Mission, Operation Feedback, and Key Map form a 91-pixel left column while the
`37 x 50` Controller occupies `(91,78)`. Renderers and derived cartridges must
consume these layout values rather than reconstructing the former top-control
and bottom-Response arrangement.

Exactly one input owner may consume buttons per frame. Use
`completion > modal (including dialogue) > controller`, return after a
higher-priority update, and require a release handoff when a modal closes.
Right-to-advance is contextual to dialogue ownership and must not leak into
Controller navigation or X + Right CNOT targeting.

## Derived-game cleanup and handoff contract

Start a derived game from one authoritative framework variant. The copied
game cartridge then becomes that game's source of truth; do not keep a second
Lua mirror or copied framework tree that can drift from it.

When an explicit task replaces framework-owned behavior in the derived game,
finish the migration instead of layering a second path on top of the first:

- keep exactly one active `_init`, `_update` or `_update60`, and `_draw` path;
- remove superseded functions such as `_update_old`, obsolete direction
  helpers, unused gate-cycling code, and stale modifier-control branches;
- search the cartridge and README for old control strings and helper names;
- remove code only after confirming that it is obsolete and game-local;
  preserve unrelated or user-owned changes;
- remember that unreachable functions still consume PICO-8 tokens.

When scaling a derived game from 3Q to 4Q, prefer a separate named cartridge
variant when both teaching levels remain useful. Do not overwrite the clearer
3Q source merely to prove 16-state capacity. The 4Q migration must update the
simulator register count, complete state list, level targets, initial/fallback
states, Controller width, Response density, sprites, and collision geometry as
one coherent change.

`0UsefulExamples/photon_runner/photon_runner_4Qv.p8` is the tested dense-lane
reference. It retains one `_init`, `_update`, and `_draw` path and removes
unused gate-cycling and distribution helpers. Apply the same audit to future
variants: copied helpers that are no longer called still consume cartridge
tokens and should not survive a completed migration.

Keep documentation at the correct ownership level. Reusable Controller,
layout, CNOT, preview, and production rules belong in framework docs.
Game-specific scoring, collision thresholds, animation timing, levels, and
Response behavior belong in the derived game's README or source comments.
Do not copy preview tools, caches, release folders, tests, or framework docs
into a simple example. Update the fallback renderer only when a shared
framework visual contract changes, not for every game-specific Response
animation.

Before handoff, synchronize and verify:

1. input behavior (including modal ownership), Key Map / Operation Feedback,
   and player README;
2. a search for duplicate entry points and legacy control text;
3. `git diff --check` and `python -m unittest discover -s tests -v`;
4. native PICO-8 behavior and token budget when PICO-8 is available.

The handoff should name the authoritative `.p8`, summarize the final controls
and important game-owned changes, report automated checks, and state whether
native PICO-8 verification was completed. Native PICO-8 remains the final
authority when it differs from a generated preview.

After a meaningful visual or layout change:

1. update the authoritative `.p8`;
2. update the fallback renderer when required;
3. generate a guided preview;
4. run `python -m unittest discover -s tests -v`;
5. verify native PICO-8 behavior when possible.

Do not add preview-only metadata to the cartridge. Keep documented geometry,
normalized preview metadata, and test expectations synchronized.

---

## PICO-8 Truth

All preview generation must follow **PICO-8 truth**.

### That means:

1. The target display is `128 × 128`.
2. Pixel layout should remain aligned to the PICO-8 pixel grid.
3. The default PICO-8 palette should be used unless the project explicitly changes it.
4. The preview should respect PICO-8-style text appearance as closely as practical.
5. The preview should follow PICO-8 button glyph conventions and character-map intent when possible.
6. If the preview differs from live PICO-8 behavior, **PICO-8 wins**.

---

## Recommended Deliverables

A Qilin-based project should ideally provide:

```text
docs/QILIN_LAYOUT_CONTRACT.md
docs/QILIN_AGENT_PREVIEW_WORKFLOW.md
docs/QILIN_GAME_DESIGNER_GUIDE.md
tools/render_preview.py
examples/preview_blank.png
examples/preview_after_edit.png
examples/preview_after_run.png
```

This document describes the behavior expected from the preview system.

---

# 1. Inputs

The preview workflow should accept:

## Required input
- a `.p8` cartridge or bundled `.lua` source

## Optional inputs
- which game state to render:
  - blank / initial state
  - after gate insertion
  - after run
  - custom level
  - custom counts
  - custom cursor position
  - custom feedback state
- output scale
- output file path

---

# 2. Outputs

The workflow should normally produce at least one PNG.

## Required output
- `preview.png`

## Optional outputs
- `preview_blank.png`
- `preview_after_edit.png`
- `preview_after_run.png`
- `layout_audit.md`
- `layout_audit.json`

---

# 3. Preferred Rendering Order

## Priority 1 — Native PICO-8 render

If a usable PICO-8 runtime is available, the preview workflow should prefer actual PICO-8 rendering.

This is the ideal route because it most faithfully preserves:
- font
- glyphs
- spacing
- palette
- button characters
- sprite/text behavior

If this route is possible, it should be considered the best preview path.

---

## Priority 2 — Layout-faithful fallback renderer

If native PICO-8 rendering is not available, the workflow should use a fallback renderer.

The fallback renderer must be:

- **layout-aware**
- **PICO-8-inspired**
- **contract-driven**
- **documented as fallback output**

The fallback renderer does **not** need to be pixel-perfect, but it must be faithful enough for design review.

It should preserve:
- Area structure
- Cluster placement
- Pixel alignment
- Color intent
- Text hierarchy
- Control legend meaning

---

# Exact P8SCII Font Integration

The supplied Python renderer uses a PICO-8-compatible bitmap font map rather
than a generic desktop font.

It does not bundle font bytes. By default it:

1. downloads `src/gen/pico_font.h` from Retro8 at runtime;
2. caches the file under the user's cache directory;
3. parses the 128×80 one-bit font bitmap;
4. renders ordinary glyphs at 4×6 and graphical symbols at 8×6;
5. maps the six Unicode controller symbols to their P8SCII codes.

For offline or reproducible rendering, provide a local header:

```bash
python tools/render_preview.py game.p8 \
  --font-header /path/to/pico_font.h \
  --no-font-download \
  -o preview.png
```

The font source is an external runtime dependency and must not be silently
copied into a distributable project.

## Standard renderer command

```bash
python tools/render_preview.py game.p8 \
  -o preview.png \
  --native-output preview_128x128.png \
  --metadata-output preview.json
```

The scaled image uses nearest-neighbor resampling. The native image remains
exactly 128×128.

## Layout guide overlay

The preview renderer now draws subtle 1-pixel guide rectangles to show the
major layout blocks used in framework discussion:

- Controller
- Key Map
- Operation Feedback
- Mission
- Response

These guide lines are part of the preview workflow so a designer can review
block boundaries visually while iterating on layout.

## Cartridge and fallback-renderer synchronization

The Python preview is a static fallback renderer; it does not execute the
cartridge's `_draw()` function. Layout-table values are parsed directly from
the `.p8`. Grid background and normal border colors are read from the existing
PICO-8 grid drawing statements. No preview-only data should be added to the
cartridge.

When a visual algorithm changes in Lua, update the corresponding fallback
algorithm in `tools/render_core.py`. The live watcher keeps Python modules in
memory, so a running watcher must be restarted after Python renderer or parser
changes.

`WATCH_PREVIEW.bat` starts with `--force`. This guarantees one fresh render
after every watcher restart and prevents an older cached PNG from surviving a
renderer-code change. After startup, watch mode returns to content-hash-based
change detection, so the forced startup render does not create ongoing load.

Use the guided renderer when `previews/current.png` should contain the major
layout outlines:

```bash
python tools/render_preview_guided.py framework/qilin_game_framework_4Qv.p8 \
  -o previews/current.png \
  --native-output previews/current_128x128.png \
  --metadata-output previews/current.json \
  --force
```

The native 128x128 output intentionally contains no guide overlay.

## Useful state options

By default, a PNG preview includes representative X, CNOT, and H gates in the
controller. Explicit `--gate` options replace that example set; use
`--blank-controller` when the controller must be empty.

```bash
# choose a level and selected visual qubit
python tools/render_preview.py game.p8 --level 2 --cursor-q 3

# replace the default examples with an explicit gate set
python tools/render_preview.py game.p8 \
  --gate q1:d1:h \
  --gate q1:d2:cx:q2

# render an empty controller
python tools/render_preview.py game.p8 --blank-controller

# render measured counts
python tools/render_preview.py game.p8 \
  --counts '{"000":8,"111":8}'
```


# 4. Fallback Renderer Requirements

A fallback preview renderer should do the following.

## 4.1 Parse current source
It should read the current `.lua` or `.p8` file.

At minimum it should identify:
- layout contract
- game state needed for screen drawing
- currently loaded level or default level
- controller state (cursor, gates, fresh/blocked feedback if applicable)
- response state

## 4.2 Follow the layout contract
It should render using the official contract from:

> `QILIN_LAYOUT_CONTRACT.md`

Specifically:
- Top-level block origin + local offset
- `w/h` interpreted as true dimensions
- rectangles using `x..x+w-1`, `y..y+h-1`

## 4.3 Use PICO-8 palette
Use the PICO-8 palette unless the cartridge explicitly overrides it.

## 4.4 Respect PICO-8 font intent
If the exact font is unavailable:
- use a monospaced or pixel-style substitute;
- preserve spacing conservatively;
- document that a substitute font is being used.

## 4.5 Respect PICO-8 character-map intent
The preview should try to preserve:
- button glyphs
- arrows
- special display symbols
- lowercase source convention with PICO-8-like visual display

The compact Key Map should reuse the same code-drawn gate notation as the
Controller:

```text
Tap X         circled plus (X)
Tap O         compact H
Hold X+axis   filled control dot — circled-plus target (CNOT)
Run direction run
Down          clear
```

If an exact P8SCII button glyph is unavailable, use a documented substitute,
but do not fall back to obsolete gate assignments.

## 4.6 Preserve important visual semantics
Examples:
- highlighted current qubit
- blocked feedback color
- color-1 gate and committed CNOT rendering
- target vs measured response colors
- empty vs occupied controller cells

## 4.7 Make state explicit
The renderer should clearly state or encode what it rendered:
- blank state
- edited state
- post-run state
- custom state

---

# 5. Suggested Skill Behavior

If this workflow is implemented as an agent skill or playbook, the skill behavior should be:

## Skill name
`qilin-preview`

## Goal
Generate a PNG preview of the current Qilin-based cartridge so a designer can inspect layout and UI quickly.

## Standard behavior
1. Read current cartridge or Lua source.
2. Extract or confirm the layout contract.
3. Determine which state to render.
4. Render the gameplay screen.
5. Save the PNG.
6. Optionally validate layout bounds.
7. Return the output path and a concise summary.

## Success criteria
A run is successful if:
- the PNG file exists;
- the main Areas are visible;
- cluster positions match the layout contract;
- the result is useful for UI review.

---

# 6. Validation Checklist

Every preview generation should validate the following when practical.

## Geometry
- Controller elements appear in the expected positions.
- Qubit Index and Depth Index satisfy the grid-anchored label invariant; no
  qubit/depth change may leave either label group visually detached.
- Controller content with `anchor="bottom_right"` remains right- and
  bottom-aligned when its qubit count or circuit depth is reduced.
- Mission appears in the expected position.
- Response remains a rectangular region.
- child clusters remain within their parent bounds where applicable.

## Content
- Qubit labels are visible.
- Depth labels are visible.
- Key Map items are visible.
- Mission canvas content is visible and clipped to Mission bounds.
- Response legend is visible.
- Response Canvas is visible.
- State Index is visible if enabled.

## PICO-8 truth
- colors match or closely approximate the intended PICO-8 palette;
- text scale and spacing remain pixel-grid friendly;
- button glyph meaning remains intact.

## Traceability
- the preview run should note whether it used:
  - native PICO-8 rendering, or
  - fallback rendering.

---

# 7. When to Regenerate a Preview

A new preview should be generated after any meaningful change to:
- area positions
- cluster positions
- sizing
- game text placement
- controller interaction visuals
- response visuals
- glyph substitutions
- palette decisions
- educational content display

In practice:

> any non-trivial UI or gameplay change should trigger a new preview.

---

# 8. Recommended Preview Variants

For a Qilin-based educational game, the most useful minimum set is:

## 8.1 Blank / initial state
Shows the default screen before editing.

## 8.2 Edited state
Shows the controller after one or more gate insertions.

## 8.3 After-run state
Shows the response after measurement or simulation results are available.

This 3-image set is usually enough for most early UI iteration.

---

# 9. Agent Prompt Template

A future agent can be given the following operating prompt:

```text
You are working on a Qilin-based educational game.

Follow:
- docs/QILIN_LAYOUT_CONTRACT.md
- docs/QILIN_AGENT_PREVIEW_WORKFLOW.md
- docs/QILIN_GAME_DESIGNER_GUIDE.md

After every non-trivial UI or gameplay change:
1. update the cartridge or Lua source
2. generate at least one PNG preview
3. state whether the preview used native PICO-8 or fallback rendering
4. report any layout contract violations
5. summarize what changed

When generating previews, follow PICO-8 truth:
- 128x128 screen
- PICO-8 palette
- PICO-8-style text/glyph behavior when possible
- PICO-8 remains the final source of truth
```

---

# 10. Practical Recommendation

The best practical setup is:

- **documentation + reusable preview script + example outputs**

A markdown-only handoff is better than nothing, but not ideal.

The preferred co-work bundle is:

1. layout contract
2. preview workflow spec
3. designer guide
4. reusable preview renderer
5. example PNGs

---

## Final Rule

If a fallback preview and actual PICO-8 output disagree:

> **treat the preview as advisory and PICO-8 as authoritative.**

---

# Preview performance implementation

The repository implementation is split into:

```text
tools/layout_parser.py   safe arithmetic parser + schema normalization
tools/render_core.py     pure in-memory P8SCII rendering
tools/render_preview.py  one-shot CLI, cache, and --watch mode
tools/watch_preview.py   watch-mode convenience entry point
tools/release.py         explicit release packaging only
```

The active framework cartridge is:

```text
framework/qilin_game_framework_4Qv.p8
```

Do not use `reference/qilin.p8` as the preview source unless explicitly
reviewing the original game.
