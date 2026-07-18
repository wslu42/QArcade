# Preview Performance Architecture

The preview renderer is designed for an interactive game-designer loop rather than a release pipeline.

## Completed priorities

### 1. Directly parse the current framework cartridge

`tools/layout_parser.py` accepts numeric layout expressions such as:

```lua
x=14-8
y=11-4
x=0+1
x=2*(3+1)
```

Only numeric literals, parentheses, and `+ - * /` are allowed. The parser does not execute Lua.

### 2. Normalize layout schemas

The parser normalizes current and earlier field conventions into one renderer schema, including:

- `text_dy` → `text_y`
- `gap_dy` → `gap_y`
- current inclusive cell extents `cell_w=6` → true width `7`, while retaining
  compatibility with earlier inclusive extents such as `8` → `9`
- missing wire, gate-symbol, and response-bar defaults
- the former `state_index.x=1` plus draw-time `-1` → effective `x=0`
- parent bounds expanded when child clusters exceed declared bounds

Normalization preserves visible geometry while removing contradictory arithmetic from the renderer.

### 3. Persistent watch mode

```bash
python tools/watch_preview.py framework/qilin_game_framework_4Qv.p8 \
  -o previews/current.png
```

The process remains alive and retains:

- Python and Pillow startup state
- parsed P8SCII bitmap font
- glyph cache
- tokenized text cache
- previous content fingerprint

The source file is polled every 150 ms by default, configurable with `--poll-interval`.

### 4. Preview and release are separate

Fast preview:

```bash
python tools/render_preview.py framework/qilin_game_framework_4Qv.p8 \
  -o previews/current.png
```

Explicit release:

```bash
python tools/release.py --project-root . \
  --output release/qilin-game-framework.zip
```

Previewing does not split Lua, create a version folder, build a ZIP, or produce an audit unless explicitly requested.

### 5. SHA-256 no-change cache

The renderer fingerprints:

- cartridge contents
- renderer version
- font-header contents
- level/cursor/gate/count/feedback state
- scale

If the fingerprint matches and requested outputs exist, rendering is skipped. The default cache is:

```text
.qilin-cache/preview-cache.json
```

Use `--force` to bypass the cache.

## Test coverage

```bash
python -m unittest discover -s tests -v
```

The tests cover arithmetic parsing, compact 4Q/3Q layout normalization,
default gate examples, cache skipping, guided output, colors, and release
separation.

## Local benchmark

Using the framework cartridge and a loaded in-memory bitmap font,
100 repeated render-core runs produced:

```text
median: 2.43 ms
mean:   2.46 ms
p95:    2.98 ms
```

This measures parse + normalization + 128×128 render in one persistent Python
process. Process startup, first-run font download, and PNG write time are not
included. Watch mode is designed to eliminate repeated startup and font-load
costs.
