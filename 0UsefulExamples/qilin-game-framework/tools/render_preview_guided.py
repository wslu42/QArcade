#!/usr/bin/env python3
"""Render Qilin previews with output-resolution layout guide rectangles.

The native 128x128 preview remains untouched. Guide rectangles are added only
after nearest-neighbor scaling, so a one-pixel guide stays one output pixel
instead of becoming an 8-pixel-wide native line in the default preview.
"""

from __future__ import annotations

import time
from typing import Any

from PIL import Image, ImageDraw, ImageFont

import render_preview
from render_core import PICO8_PALETTE
from render_core import render_source as render_source_without_guides


GUIDED_RENDERER_VERSION = "3.8.0-controller-schema-promotion"
GUIDE_COLOR_INDEX = 13
LABEL_COLOR_INDEX = 7
OUTPUT_LINE_WIDTH = 1
LABEL_PADDING_X = 3
LABEL_PADDING_Y = 2
LABEL_SCALE = 4
MISSION_LEFT_LINE_WIDTH = 2

DISPLAY_NAMES = {
    "controller": "controller",
    "controller_left": "controller p1",
    "controller_p2": "controller p2",
    "key_map": "key map",
    "operation_feedback": "feedback",
    "mission": "mission",
    "response": "response",
}


def _layout_blocks(layout: dict[str, Any]) -> list[dict[str, int | str]]:
    controller = layout["controller"]
    controller_left = layout.get("controller_left")
    if controller_left:
        response = layout["response"]
        key_map = layout["key_map"]
        return [
            {
                "name": "controller_left",
                "x": int(controller_left["x"]),
                "y": int(controller_left["y"]),
                "w": int(controller_left["w"]),
                "h": int(controller_left["h"]),
            },
            {
                "name": "controller_p2",
                "x": int(controller["x"]),
                "y": int(controller["y"]),
                "w": int(controller["w"]),
                "h": int(controller["h"]),
            },
            {
                "name": "key_map",
                "x": int(key_map["x"]),
                "y": int(key_map["y"]),
                "w": int(key_map["w"]),
                "h": int(key_map["h"]),
            },
            {
                "name": "response",
                "x": int(response["x"]),
                "y": int(response["y"]),
                "w": int(response["w"]),
                "h": int(response["h"]),
            },
        ]
    key_map = layout["key_map"]
    operation_feedback = layout["operation_feedback"]
    mission = layout["mission"]
    response = layout["response"]

    return [
        {
            "name": "controller",
            "x": int(controller["x"]),
            "y": int(controller["y"]),
            "w": int(controller["w"]),
            "h": int(controller["h"]),
        },
        {
            "name": "key_map",
            "x": int(key_map["x"]),
            "y": int(key_map["y"]),
            "w": int(key_map["w"]),
            "h": int(key_map["h"]),
        },
        {
            "name": "operation_feedback",
            "x": int(operation_feedback["x"]),
            "y": int(operation_feedback["y"]),
            "w": int(operation_feedback["w"]),
            "h": int(operation_feedback["h"]),
        },
        {
            "name": "mission",
            "x": int(mission["x"]),
            "y": int(mission["y"]),
            "w": int(mission["w"]),
            "h": int(mission["h"]),
        },
        {
            "name": "response",
            "x": int(response["x"]),
            "y": int(response["y"]),
            "w": int(response["w"]),
            "h": int(response["h"]),
        },
    ]


def _draw_output_box(
    draw: ImageDraw.ImageDraw,
    image: Image.Image,
    *,
    x: int,
    y: int,
    width: int,
    height: int,
    scale: int,
) -> tuple[int, int, int, int] | None:
    """Draw a one-output-pixel rectangle around a native-space block."""
    if width <= 0 or height <= 0:
        return None

    left = max(0, x * scale)
    top = max(0, y * scale)
    right = min(image.width - 1, (x + width) * scale - 1)
    bottom = min(image.height - 1, (y + height) * scale - 1)
    if left > right or top > bottom:
        return None

    color = PICO8_PALETTE[GUIDE_COLOR_INDEX]
    draw.line((left, top, right, top), fill=color, width=OUTPUT_LINE_WIDTH)
    draw.line((left, bottom, right, bottom), fill=color, width=OUTPUT_LINE_WIDTH)
    draw.line((left, top, left, bottom), fill=color, width=OUTPUT_LINE_WIDTH)
    draw.line((right, top, right, bottom), fill=color, width=OUTPUT_LINE_WIDTH)
    return left, top, right, bottom


def _draw_scaled_label(
    image: Image.Image,
    *,
    x: int,
    y: int,
    text: str,
    color: tuple[int, int, int],
) -> None:
    if not text:
        return
    base_font = ImageFont.load_default()
    bbox = base_font.getbbox(text)
    width = max(1, bbox[2] - bbox[0])
    height = max(1, bbox[3] - bbox[1])
    label = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    label_draw = ImageDraw.Draw(label)
    label_draw.text((-bbox[0], -bbox[1]), text, fill=color + (255,), font=base_font)
    label = label.resize((width * LABEL_SCALE, height * LABEL_SCALE), Image.Resampling.NEAREST)
    max_x = max(0, image.width - label.width)
    max_y = max(0, image.height - label.height)
    image.alpha_composite(label, (min(max(x, 0), max_x), min(max(y, 0), max_y)))


def _add_output_layout_guides(
    image: Image.Image,
    layout: dict[str, Any],
    *,
    scale: int,
) -> list[dict[str, int | str]]:
    blocks = _layout_blocks(layout)
    if image.mode != "RGBA":
        raise ValueError("Guide rendering expects an RGBA image")
    draw = ImageDraw.Draw(image)
    guide_color = PICO8_PALETTE[GUIDE_COLOR_INDEX]
    text_color = PICO8_PALETTE[LABEL_COLOR_INDEX]
    for block in blocks:
        box = _draw_output_box(
            draw,
            image,
            x=int(block["x"]),
            y=int(block["y"]),
            width=int(block["w"]),
            height=int(block["h"]),
            scale=scale,
        )
        if box is None:
            continue
        left, top, right, bottom = box
        if str(block["name"]) == "mission":
            draw.line(
                (left, top, left, bottom),
                fill=guide_color,
                width=MISSION_LEFT_LINE_WIDTH,
            )
        label_x = left + LABEL_PADDING_X
        label_y = top + LABEL_PADDING_Y
        _draw_scaled_label(
            image,
            x=label_x,
            y=label_y,
            text=DISPLAY_NAMES.get(str(block["name"]), str(block["name"])),
            color=text_color,
        )
    return blocks


class GuidedRenderSession(render_preview.RenderSession):
    """Render a pure native frame and overlay guides only on the scaled copy."""

    def render_if_changed(self) -> tuple[bool, float, str]:
        started = time.perf_counter()
        source_bytes = self.source.read_bytes()
        fingerprint = render_preview.compute_fingerprint(
            source_bytes,
            self.header_text,
            self.state,
            scale=self.scale,
        )
        key = str(self.output.resolve())
        cached = self.cache["entries"].get(key, {})
        outputs_exist = self.output.exists()
        if self.native_output is not None:
            outputs_exist = outputs_exist and self.native_output.exists()
        if self.metadata_output is not None:
            outputs_exist = outputs_exist and self.metadata_output.exists()

        if not self.force and outputs_exist and cached.get("fingerprint") == fingerprint:
            return False, time.perf_counter() - started, fingerprint

        source = source_bytes.decode("utf-8")
        native, metadata = render_source_without_guides(
            source,
            self.font,
            self.state,
        )

        scaled = (
            native.copy()
            if self.scale == 1
            else native.resize(
                (native.width * self.scale, native.height * self.scale),
                Image.Resampling.NEAREST,
            )
        ).convert("RGBA")
        blocks = _add_output_layout_guides(
            scaled,
            metadata["normalized_layout"],
            scale=self.scale,
        )

        render_preview.save_image_atomic(scaled, self.output)
        if self.native_output is not None:
            render_preview.save_image_atomic(native, self.native_output)

        metadata["renderer_version"] = GUIDED_RENDERER_VERSION
        metadata["layout_guides"] = {
            "enabled": True,
            "labels_enabled": True,
            "label_scale": LABEL_SCALE,
            "label_names": DISPLAY_NAMES,
            "mission_left_line_width": MISSION_LEFT_LINE_WIDTH,
            "draw_stage": "after_scaling",
            "output_line_width": OUTPUT_LINE_WIDTH,
            "output_scale": self.scale,
            "effective_native_line_width": OUTPUT_LINE_WIDTH / self.scale,
            "native_preview_contains_guides": False,
            "color_index": GUIDE_COLOR_INDEX,
            "label_color_index": LABEL_COLOR_INDEX,
            "blocks": blocks,
        }
        metadata.update({
            "source": str(self.source),
            "font_source": self.font_source,
            "fingerprint": fingerprint,
            "scaled_output": str(self.output),
            "native_output": str(self.native_output) if self.native_output else None,
        })
        if self.metadata_output is not None:
            render_preview.save_json_atomic(metadata, self.metadata_output)

        self.cache["entries"][key] = {
            "fingerprint": fingerprint,
            "source": str(self.source.resolve()),
            "updated_unix": time.time(),
        }
        render_preview.save_cache(self.cache_file, self.cache)
        self.force = False
        return True, time.perf_counter() - started, fingerprint


def main() -> int:
    render_preview.RENDERER_VERSION = GUIDED_RENDERER_VERSION
    render_preview.RenderSession = GuidedRenderSession
    return render_preview.main()


if __name__ == "__main__":
    raise SystemExit(main())
