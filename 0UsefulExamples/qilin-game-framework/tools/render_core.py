#!/usr/bin/env python3
"""Pure rendering core for Qilin PICO-8 previews.

This module performs no release packaging and no file watching. A caller gives
it parsed project data, a loaded P8SCII font, and an explicit preview state.
"""

from __future__ import annotations

import re
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw

from layout_parser import LayoutParseError, parse_project, parse_scalar


SCREEN_W = 128
SCREEN_H = 128
RENDERER_VERSION = "3.0.0"

PICO8_PALETTE = [
    (0, 0, 0),
    (29, 43, 83),
    (126, 37, 83),
    (0, 135, 81),
    (171, 82, 54),
    (95, 87, 79),
    (194, 195, 199),
    (255, 241, 232),
    (255, 0, 77),
    (255, 163, 0),
    (255, 236, 39),
    (0, 228, 54),
    (41, 173, 255),
    (131, 118, 156),
    (255, 119, 168),
    (255, 204, 170),
]

DEFAULT_FONT_URL = (
    "https://raw.githubusercontent.com/libretro/retro8/"
    "master/src/gen/pico_font.h"
)

SPECIAL_UNICODE_TO_P8SCII = {
    "⬇️": 128 + (ord("D") - ord("A")),
    "⬅️": 128 + (ord("L") - ord("A")),
    "🅾️": 128 + (ord("O") - ord("A")),
    "➡️": 128 + (ord("R") - ord("A")),
    "⬆️": 128 + (ord("U") - ord("A")),
    "❎": 128 + (ord("X") - ord("A")),
    "⬇": 128 + (ord("D") - ord("A")),
    "⬅": 128 + (ord("L") - ord("A")),
    "🅾": 128 + (ord("O") - ord("A")),
    "➡": 128 + (ord("R") - ord("A")),
    "⬆": 128 + (ord("U") - ord("A")),
}


class PreviewError(RuntimeError):
    """Raised when a preview cannot be generated safely."""


@dataclass(frozen=True)
class GateSpec:
    visual_q: int
    depth: int
    gate_type: str
    target_visual_q: int | None = None


@dataclass(frozen=True)
class PreviewState:
    level_number: int = 1
    cursor_visual_q: int | None = None
    gates: tuple[GateSpec, ...] = ()
    counts: dict[str, int] | None = None
    feedback: str | None = None


def default_cache_dir(project_root: Path) -> Path:
    return project_root / ".qilin-cache"


def load_font_header(
    *,
    explicit_path: Path | None,
    cache_path: Path,
    font_url: str = DEFAULT_FONT_URL,
    no_download: bool = False,
) -> tuple[str, str]:
    if explicit_path is not None:
        if not explicit_path.exists():
            raise PreviewError(f"Font header not found: {explicit_path}")
        return explicit_path.read_text(encoding="utf-8"), str(explicit_path)

    if cache_path.exists():
        return cache_path.read_text(encoding="utf-8"), str(cache_path)

    if no_download:
        raise PreviewError(
            "No P8SCII font header is cached. Supply --font-header or allow "
            "the first-run font download."
        )

    cache_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with urllib.request.urlopen(font_url, timeout=30) as response:
            data = response.read()
    except Exception as exc:  # pragma: no cover - network environment dependent
        raise PreviewError(
            "Could not download the PICO-8-compatible bitmap font. Supply "
            "--font-header for offline use."
        ) from exc

    cache_path.write_bytes(data)
    return data.decode("utf-8"), f"{font_url} (cached at {cache_path})"


def parse_font_map(header_text: str) -> list[int]:
    match = re.search(
        r"font_map\s*\[\s*\]\s*=\s*\{(?P<body>.*?)\};",
        header_text,
        re.DOTALL,
    )
    if not match:
        raise PreviewError("font_map[] was not found in the font header.")
    values = [
        int(value, 16)
        for value in re.findall(r"0x([0-9a-fA-F]{2})", match.group("body"))
    ]
    if len(values) != 1280:
        raise PreviewError(
            f"Expected 1280 font bytes (128x80 bitmap); found {len(values)}."
        )
    return values


class Pico8BitmapFont:
    """P8SCII bitmap renderer: 4x6 standard glyphs and 8x6 symbols."""

    def __init__(self, font_map: list[int]):
        self.font_map = font_map
        self._glyph_cache: dict[int, tuple[tuple[bool, ...], ...]] = {}
        self._token_cache: dict[str, tuple[tuple[int, int], ...]] = {}

    def glyph(self, code: int) -> tuple[tuple[bool, ...], ...]:
        if not 0 <= code < 160:
            code = ord("?")
        cached = self._glyph_cache.get(code)
        if cached is not None:
            return cached

        glyph_row = code // 16
        glyph_col = code % 16
        rows: list[tuple[bool, ...]] = []
        for y in range(8):
            byte_index = glyph_row * 128 + y * 16 + glyph_col
            value = self.font_map[byte_index]
            rows.append(tuple(bool(value & (1 << (7 - x))) for x in range(8)))
        result = tuple(rows)
        self._glyph_cache[code] = result
        return result

    def tokenize(self, text: str) -> tuple[tuple[int, int], ...]:
        cached = self._token_cache.get(text)
        if cached is not None:
            return cached

        result: list[tuple[int, int]] = []
        index = 0
        specials = sorted(SPECIAL_UNICODE_TO_P8SCII, key=len, reverse=True)
        while index < len(text):
            for symbol in specials:
                if text.startswith(symbol, index):
                    result.append((SPECIAL_UNICODE_TO_P8SCII[symbol], 8))
                    index += len(symbol)
                    break
            else:
                code = ord(text[index])
                result.append((code if code <= 127 else ord("?"), 4))
                index += 1
                continue
            continue

        tokenized = tuple(result)
        self._token_cache[text] = tokenized
        return tokenized

    def width(self, text: str) -> int:
        return sum(advance for _, advance in self.tokenize(text))

    def draw(
        self,
        image: Image.Image,
        text: str,
        x: int,
        y: int,
        color: tuple[int, int, int],
    ) -> int:
        pixels = image.load()
        cursor_x = x
        for code, advance in self.tokenize(text):
            glyph = self.glyph(code)
            for gy in range(6):
                for gx in range(advance):
                    if glyph[gy][gx]:
                        px = cursor_x + gx
                        py = y + gy
                        if 0 <= px < image.width and 0 <= py < image.height:
                            pixels[px, py] = color
            cursor_x += advance
        return cursor_x


class PicoCanvas:
    def __init__(self, font: Pico8BitmapFont):
        self.image = Image.new("RGB", (SCREEN_W, SCREEN_H), PICO8_PALETTE[0])
        self.draw_api = ImageDraw.Draw(self.image)
        self.font = font

    @staticmethod
    def color(index: int) -> tuple[int, int, int]:
        return PICO8_PALETTE[index % 16]

    def line(self, x1: int, y1: int, x2: int, y2: int, color: int) -> None:
        self.draw_api.line((x1, y1, x2, y2), fill=self.color(color))

    def rect(self, x1: int, y1: int, x2: int, y2: int, color: int) -> None:
        self.draw_api.rectangle((x1, y1, x2, y2), outline=self.color(color))

    def rectfill(self, x1: int, y1: int, x2: int, y2: int, color: int) -> None:
        self.draw_api.rectangle((x1, y1, x2, y2), fill=self.color(color))

    def circ(self, x: int, y: int, radius: int, color: int) -> None:
        self.draw_api.ellipse(
            (x - radius, y - radius, x + radius, y + radius),
            outline=self.color(color),
        )

    def circfill(self, x: int, y: int, radius: int, color: int) -> None:
        self.draw_api.ellipse(
            (x - radius, y - radius, x + radius, y + radius),
            fill=self.color(color),
            outline=self.color(color),
        )

    def text(self, value: str, x: int, y: int, color: int) -> None:
        self.font.draw(self.image, value, x, y, self.color(color))

    def centered_text(self, value: str, x: int, y: int, width: int, color: int) -> None:
        text_x = x + max(0, (width - self.font.width(value)) // 2)
        self.text(value, text_x, y, color)


def parse_gate_spec(spec: str) -> GateSpec:
    parts = spec.lower().split(":")
    if len(parts) not in {3, 4}:
        raise PreviewError("Gate must be qN:dN:x, qN:dN:h, or qN:dN:cx:qM.")
    try:
        visual_q = int(parts[0].removeprefix("q"))
        depth = int(parts[1].removeprefix("d"))
    except ValueError as exc:
        raise PreviewError(f"Invalid gate specification: {spec}") from exc
    gate_type = parts[2]
    target = None
    if gate_type == "cx":
        if len(parts) != 4:
            raise PreviewError("CX requires a target qN.")
        try:
            target = int(parts[3].removeprefix("q"))
        except ValueError as exc:
            raise PreviewError(f"Invalid CX target: {spec}") from exc
    elif gate_type not in {"x", "h"}:
        raise PreviewError(f"Unsupported gate type: {gate_type}")
    return GateSpec(visual_q, depth, gate_type, target)


def _draw_target_plus(
    canvas: PicoCanvas,
    x: int,
    y: int,
    grid: dict[str, Any],
    color: int,
) -> None:
    center_x = x + int(grid["cell_w"]) // 2
    center_y = y + int(grid["cell_h"]) // 2
    radius = int(grid["target_radius"])
    canvas.circ(center_x, center_y, radius, color)
    canvas.line(center_x - radius, center_y, center_x + radius, center_y, color)
    canvas.line(center_x, center_y - radius, center_x, center_y + radius, color)


def render_source(
    source: str,
    font: Pico8BitmapFont,
    state: PreviewState,
) -> tuple[Image.Image, dict[str, Any]]:
    try:
        project = parse_project(source)
    except LayoutParseError as exc:
        raise PreviewError(str(exc)) from exc
    return render_project(project, source, font, state)


def render_project(
    project: dict[str, Any],
    source: str,
    font: Pico8BitmapFont,
    state: PreviewState,
) -> tuple[Image.Image, dict[str, Any]]:
    layout = project["layout"]
    levels = project["levels"]
    states = project["states"]
    num_qubits = int(project["num_qubits"])
    circuit_depth = int(project["circuit_depth"])

    if not 1 <= state.level_number <= len(levels):
        raise PreviewError(
            f"Level {state.level_number} is outside 1..{len(levels)}."
        )
    level = levels[state.level_number - 1]

    cursor_visual_q = state.cursor_visual_q
    if cursor_visual_q is None:
        internal_cursor = parse_scalar(source, "cursor_q", num_qubits - 1)
        cursor_visual_q = num_qubits - internal_cursor
    if not 1 <= cursor_visual_q <= num_qubits:
        raise PreviewError(
            f"Cursor q{cursor_visual_q} is outside q1..q{num_qubits}."
        )

    canvas = PicoCanvas(font)
    controller = layout["controller"]
    core = controller["core"]
    grid = core["grid"]
    key_map = controller["key_map"]

    # Key Map Group
    key_x = int(controller["x"]) + int(key_map["x"])
    key_y = int(controller["y"]) + int(key_map["y"])
    for item in key_map["items"]:
        canvas.text(
            str(item["text"]),
            key_x + int(item["x"]),
            key_y + int(item["y"]),
            5,
        )

    # Controller Operation Feedback
    if state.feedback:
        feedback = controller["operation_feedback"]
        canvas.text(
            state.feedback,
            int(controller["x"]) + int(feedback["x"]),
            int(controller["y"]) + int(feedback["y"]),
            13,
        )

    core_x = int(controller["x"]) + int(core["x"])
    core_y = int(controller["y"]) + int(core["y"])
    grid_x = core_x + int(grid["x"])
    grid_y = core_y + int(grid["y"])

    # Qubit Index and Qubit Selector
    for visual_col in range(num_qubits):
        visual_q = visual_col + 1
        column_x = visual_col * int(grid["col_pitch"])
        color = 10 if visual_q == cursor_visual_q else 6
        canvas.text(
            f"q{visual_q}",
            core_x + int(core["qubit_index"]["x"]) + column_x,
            core_y + int(core["qubit_index"]["y"]),
            color,
        )
        if visual_q == cursor_visual_q:
            canvas.text(
                "^",
                core_x + int(core["qubit_selector"]["x"]) + column_x,
                core_y + int(core["qubit_selector"]["y"]),
                color,
            )

    # Qubit Wires derived from Controller Grid
    wire_local_x = int(grid["cell_w"]) // 2
    wire_top_y = grid_y - int(grid["wire_top_overhang"])
    wire_bottom_y = (
        grid_y
        + (circuit_depth - 1) * int(grid["row_pitch"])
        + int(grid["cell_h"])
        - 1
        + int(grid["wire_bottom_overhang"])
    )
    for visual_col in range(num_qubits):
        wire_x = grid_x + visual_col * int(grid["col_pitch"]) + wire_local_x
        canvas.line(wire_x, wire_top_y, wire_x, wire_bottom_y, 5)
        half_w = int(grid["wire_arrow_half_w"])
        canvas.line(wire_x - half_w, grid_y, wire_x, wire_top_y, 5)
        canvas.line(wire_x + half_w, grid_y, wire_x, wire_top_y, 5)

    # Depth Flow Indicator
    depth_flow = core["depth_flow"]
    for visual_row in range(1, circuit_depth):
        marker_y = (
            core_y
            + int(depth_flow["y"])
            + visual_row * int(grid["row_pitch"])
            + int(depth_flow["gap_y"])
        )
        canvas.text("^", core_x + int(depth_flow["x"]), marker_y, 6)

    gate_map: dict[tuple[int, int], tuple[str, int | None]] = {}
    incoming: dict[tuple[int, int], int] = {}
    for gate in state.gates:
        if not (1 <= gate.visual_q <= num_qubits):
            raise PreviewError(f"Gate qubit q{gate.visual_q} is out of range.")
        if not (1 <= gate.depth <= circuit_depth):
            raise PreviewError(f"Gate depth d{gate.depth} is out of range.")
        gate_map[(gate.visual_q, gate.depth)] = (
            gate.gate_type,
            gate.target_visual_q,
        )
        if gate.gate_type == "cx":
            target = gate.target_visual_q
            if target is None or not 1 <= target <= num_qubits:
                raise PreviewError(f"Invalid CX target: {target}")
            incoming[(target, gate.depth)] = gate.visual_q

    # Controller Grid and Depth Index
    depth_index = core["depth_index"]
    for visual_row in range(circuit_depth):
        depth = circuit_depth - visual_row
        row_y = visual_row * int(grid["row_pitch"])
        y = grid_y + row_y
        canvas.text(
            f"d{depth}",
            core_x + int(depth_index["x"]),
            core_y + int(depth_index["y"]) + row_y + int(depth_index["text_y"]),
            6,
        )

        for visual_col in range(num_qubits):
            visual_q = visual_col + 1
            x = grid_x + visual_col * int(grid["col_pitch"])
            right = x + int(grid["cell_w"]) - 1
            bottom = y + int(grid["cell_h"]) - 1
            canvas.rectfill(x, y, right, bottom, 1)
            canvas.rect(x, y, right, bottom, 5)

            gate_type, target = gate_map.get((visual_q, depth), ("-", None))
            if gate_type == "cx":
                center_x = x + int(grid["cell_w"]) // 2
                center_y = y + int(grid["cell_h"]) // 2
                canvas.circfill(center_x, center_y, int(grid["control_radius"]), 7)
            elif (visual_q, depth) in incoming:
                _draw_target_plus(canvas, x, y, grid, 7)
            elif gate_type in {"x", "h"}:
                text_x = x + int(grid["single_gate_text_x"])
                canvas.text(gate_type, text_x, y + int(grid["gate_text_y"]), 7)

    # Mission Area
    mission = layout["mission"]
    title = mission["title"]
    instruction = mission["instruction"]
    canvas.centered_text(
        str(level["name"]),
        int(mission["x"]) + int(title["x"]),
        int(mission["y"]) + int(title["y"]),
        int(title["w"]),
        10,
    )
    canvas.centered_text(
        str(level["hint"]),
        int(mission["x"]) + int(instruction["x"]),
        int(mission["y"]) + int(instruction["y"]),
        int(instruction["w"]),
        6,
    )

    # Quantum Response Area
    response = layout["response"]
    legend = response["legend"]
    legend_x = int(response["x"]) + int(legend["x"])
    legend_y = int(response["y"]) + int(legend["y"])
    target_legend = legend["target"]
    measured_legend = legend["measured"]
    canvas.rect(
        legend_x + int(target_legend["box_x"]),
        legend_y,
        legend_x + int(target_legend["box_x"]) + 4,
        legend_y + 4,
        8,
    )
    canvas.text("target", legend_x + int(target_legend["text_x"]), legend_y, 6)
    canvas.rectfill(
        legend_x + int(measured_legend["box_x"]),
        legend_y,
        legend_x + int(measured_legend["box_x"]) + 4,
        legend_y + 4,
        11,
    )
    canvas.text(
        "measured",
        legend_x + int(measured_legend["text_x"]),
        legend_y,
        6,
    )

    response_canvas = response["canvas"]
    response_x = int(response["x"]) + int(response_canvas["x"])
    response_y = int(response["y"]) + int(response_canvas["y"])
    base_y = response_y + int(response_canvas["base_y"])
    counts = state.counts or {str(key): 0 for key in states}

    state_index = response["state_index"]
    state_x = int(response["x"]) + int(state_index["x"])
    state_y = int(response["y"]) + int(state_index["y"])

    for index, basis_state in enumerate(states):
        basis_state = str(basis_state)
        state_offset = index * int(response_canvas["state_pitch"])
        x = response_x + int(response_canvas["first_state_x"]) + state_offset
        target_h = int(level["target"].get(basis_state, 0))
        count_h = int(counts.get(basis_state, 0))
        bar_w = int(response_canvas["bar_w"])
        bar_right = x + bar_w - 1
        bar_center = x + bar_w // 2
        canvas.line(bar_center, base_y - 16, bar_center, base_y, 1)
        if target_h > 0:
            canvas.rect(x, base_y - target_h, bar_right, base_y, 8)
        if count_h > 0:
            measured_x = x + int(response_canvas["measured_inset_x"])
            measured_w = int(response_canvas["measured_w"])
            canvas.rectfill(
                measured_x,
                base_y - count_h + 1,
                measured_x + measured_w - 1,
                base_y - 1,
                11,
            )
        canvas.text(
            basis_state,
            state_x + index * int(state_index["state_pitch"]),
            state_y,
            6,
        )

    metadata = {
        "renderer_version": RENDERER_VERSION,
        "screen": [SCREEN_W, SCREEN_H],
        "level": state.level_number,
        "cursor_visual_q": cursor_visual_q,
        "normalized_layout": layout,
        "state": {
            "gates": [gate.__dict__ for gate in state.gates],
            "counts": counts,
            "feedback": state.feedback,
        },
    }
    return canvas.image, metadata
