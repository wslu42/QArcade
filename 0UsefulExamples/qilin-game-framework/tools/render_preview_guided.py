#!/usr/bin/env python3
"""Render Qilin previews with thin guide rectangles for major layout blocks.

This wrapper keeps the main renderer unchanged and adds a one-native-pixel
muted-lavender overlay after the normal 128x128 frame has been rendered.
"""

from __future__ import annotations

from typing import Any

from PIL import Image, ImageDraw

import render_preview
from render_core import PICO8_PALETTE, Pico8BitmapFont, PreviewState
from render_core import render_source as render_source_without_guides


GUIDED_RENDERER_VERSION = "3.1.0-guides"
GUIDE_COLOR_INDEX = 13
SCREEN_MAX = 127


def _draw_box(
    draw: ImageDraw.ImageDraw,
    *,
    x: int,
    y: int,
    width: int,
    height: int,
) -> None:
    """Draw one native pixel around a declared layout rectangle."""
    if width <= 0 or height <= 0:
        return

    left = max(0, x)
    top = max(0, y)
    right = min(SCREEN_MAX, x + width - 1)
    bottom = min(SCREEN_MAX, y + height - 1)
    if left > right or top > bottom:
        return

    draw.rectangle(
        (left, top, right, bottom),
        outline=PICO8_PALETTE[GUIDE_COLOR_INDEX],
        width=1,
    )


def _add_layout_guides(
    image: Image.Image,
    layout: dict[str, Any],
) -> list[dict[str, int | str]]:
    """Overlay the declared major block boundaries and return their metadata."""
    controller = layout["controller"]
    controller_x = int(controller["x"])
    controller_y = int(controller["y"])

    feedback = controller["operation_feedback"]
    core = controller["core"]
    key_map = controller["key_map"]
    mission = layout["mission"]
    response = layout["response"]

    blocks: list[dict[str, int | str]] = [
        {
            "name": "controller_operation_feedback",
            "x": controller_x + int(feedback["x"]),
            "y": controller_y + int(feedback["y"]),
            "w": int(feedback["w"]),
            "h": int(feedback["h"]),
        },
        {
            "name": "controller_core_group",
            "x": controller_x + int(core["x"]),
            "y": controller_y + int(core["y"]),
            "w": int(core["w"]),
            "h": int(core["h"]),
        },
        {
            "name": "key_map_group",
            "x": controller_x + int(key_map["x"]),
            "y": controller_y + int(key_map["y"]),
            "w": int(key_map["w"]),
            "h": int(key_map["h"]),
        },
        {
            "name": "mission_area",
            "x": int(mission["x"]),
            "y": int(mission["y"]),
            "w": int(mission["w"]),
            "h": int(mission["h"]),
        },
        {
            "name": "quantum_response_area",
            "x": int(response["x"]),
            "y": int(response["y"]),
            "w": int(response["w"]),
            "h": int(response["h"]),
        },
    ]

    draw = ImageDraw.Draw(image)
    for block in blocks:
        _draw_box(
            draw,
            x=int(block["x"]),
            y=int(block["y"]),
            width=int(block["w"]),
            height=int(block["h"]),
        )
    return blocks


def guided_render_source(
    source: str,
    font: Pico8BitmapFont,
    state: PreviewState,
) -> tuple[Image.Image, dict[str, Any]]:
    image, metadata = render_source_without_guides(source, font, state)
    blocks = _add_layout_guides(image, metadata["normalized_layout"])
    metadata["layout_guides"] = {
        "enabled": True,
        "native_line_width": 1,
        "color_index": GUIDE_COLOR_INDEX,
        "blocks": blocks,
    }
    metadata["renderer_version"] = GUIDED_RENDERER_VERSION
    return image, metadata


def main() -> int:
    # RenderSession resolves these names from the render_preview module.
    # Updating both also invalidates an existing preview cache on next start.
    render_preview.RENDERER_VERSION = GUIDED_RENDERER_VERSION
    render_preview.render_source = guided_render_source
    return render_preview.main()


if __name__ == "__main__":
    raise SystemExit(main())
