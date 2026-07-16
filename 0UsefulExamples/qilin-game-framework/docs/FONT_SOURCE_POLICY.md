# FONT_SOURCE_POLICY.md

## Purpose

The Qilin preview renderer needs PICO-8-compatible glyph data, but this
toolkit does not redistribute a font file or embedded font bitmap.

## Default runtime source

The renderer defaults to Retro8's generated bitmap header:

```text
repository: libretro/retro8
path: src/gen/pico_font.h
```

Retro8 loads this as a 128×80 one-bit bitmap arranged as 16 columns ×
10 rows of 8×8 glyph cells.

The renderer fetches the source at runtime and caches it locally. Users are
responsible for reviewing and complying with the upstream license.

## Offline use

Supply a compatible local header:

```bash
python tools/render_preview.py game.p8 \
  --font-header /path/to/pico_font.h \
  --no-font-download
```

## Distribution rule

Do not place downloaded font files, generated font headers, or cached font
assets inside a shared artifact unless the license and redistribution terms
have been reviewed separately.

The PNG output and the renderer source can be shared without including the
font file itself.
