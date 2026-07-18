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
RENDERER_VERSION = "3.6.0"

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


def parse_grid_colors(source: str) -> tuple[int, int]:
    """Read the grid colors from the cartridge's real draw_circuit code."""
    function_match = re.search(
        r"\bfunction\s+draw_circuit\s*\(\s*\)(.*?)"
        r"\nend\s*\n\s*function\s+print_centered_in_region\b",
        source,
        re.DOTALL,
    )
    if function_match is None:
        raise PreviewError("Could not find the draw_circuit function.")
    draw_circuit = function_match.group(1)

    background_match = re.search(
        r"rectfill\s*\(\s*x\s*,\s*y\s*,"
        r"\s*x\s*\+\s*grid_layout\.cell_w\s*,"
        r"\s*y\s*\+\s*grid_layout\.cell_h\s*,\s*(\d+)\s*\)",
        draw_circuit,
        re.DOTALL,
    )
    border_match = re.search(
        r"\blocal\s+border_color\s*=\s*(\d+)\b",
        draw_circuit,
    )
    compact_match = re.search(
        r"\blocal\s+cell_color\s*=\s*visual_col\s*%\s*2\s*==\s*0\s*and\s*(\d+)\s*or\s*(\d+)",
        draw_circuit,
    )
    if compact_match is not None:
        return int(compact_match.group(1)), 1
    if background_match is None or border_match is None:
        raise PreviewError(
            "Could not read the grid background and border colors from draw_circuit."
        )

    background = int(background_match.group(1))
    border = int(border_match.group(1))
    if not 0 <= background <= 15 or not 0 <= border <= 15:
        raise PreviewError("Grid colors must be PICO-8 palette indices from 0 to 15.")
    return background, border


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
    grid_background_color, grid_border_color = parse_grid_colors(source)
    compact_controller = bool(
        re.search(
            r"\blocal\s+cell_color\s*=\s*visual_col\s*%\s*2\s*==\s*0",
            source,
        )
    )

    if not 1 <= state.level_number <= len(levels):
        raise PreviewError(
            f"Level {state.level_number} is outside 1..{len(levels)}."
        )
    level = levels[state.level_number - 1]
    controller = layout["controller"]
    horizontal_controller = controller.get("orientation") == "horizontal"

    cursor_visual_q = state.cursor_visual_q
    if cursor_visual_q is None:
        internal_cursor = parse_scalar(source, "cursor_q", num_qubits - 1)
        cursor_visual_q = internal_cursor + 1 if horizontal_controller else num_qubits - internal_cursor
    if not 1 <= cursor_visual_q <= num_qubits:
        raise PreviewError(
            f"Cursor q{cursor_visual_q} is outside q1..q{num_qubits}."
        )

    canvas = PicoCanvas(font)
    grid = controller["grid"]
    key_map = layout["key_map"]

    # Key Map
    key_x = int(key_map["x"])
    key_y = int(key_map["y"])
    key_color = int(key_map.get("color", 13 if compact_controller else 5))
    for item in key_map["items"]:
        canvas.text(
            str(item["text"]),
            key_x + int(item["x"]),
            key_y + int(item["y"]),
            key_color,
        )
    control_examples = key_map.get("control_examples")
    if control_examples:
        gate_color = int(control_examples.get("color", 13))
        for control_name in ("run", "clear"):
            control = control_examples.get(control_name)
            if control:
                canvas.text(
                    str(control["text"]),
                    key_x + int(control["x"]),
                    key_y + int(control["y"]),
                    gate_color,
                )

        x_gate = control_examples["x"]
        _draw_target_plus(
            canvas,
            key_x + int(x_gate["x"]),
            key_y + int(x_gate["y"]),
            grid,
            gate_color,
        )
        h_gate = control_examples["h"]
        h_x = key_x + int(h_gate["x"]) + int(grid["cell_w"]) // 2
        h_y = key_y + int(h_gate["y"]) + int(grid["cell_h"]) // 2
        canvas.line(h_x - 1, h_y - 1, h_x - 1, h_y + 1, gate_color)
        canvas.line(h_x + 1, h_y - 1, h_x + 1, h_y + 1, gate_color)
        canvas.line(h_x - 1, h_y, h_x + 1, h_y, gate_color)

        cx_gate = control_examples["cx"]
        cx_y = key_y + int(cx_gate["y"])
        control_x = key_x + int(cx_gate["control_x"])
        target_x = key_x + int(cx_gate["target_x"])
        center_y = cx_y + int(grid["cell_h"]) // 2
        canvas.line(
            control_x + int(grid["cell_w"]) // 2,
            center_y,
            target_x + int(grid["cell_w"]) // 2,
            center_y,
            gate_color,
        )
        canvas.circfill(
            control_x + int(grid["cell_w"]) // 2,
            center_y,
            2,
            gate_color,
        )
        _draw_target_plus(canvas, target_x, cx_y, grid, gate_color)

    # Operation Feedback
    if state.feedback:
        feedback = layout["operation_feedback"]
        canvas.text(
            state.feedback,
            int(feedback["x"]),
            int(feedback["y"]),
            13,
        )

    controller_x = int(controller["x"])
    controller_y = int(controller["y"])
    grid_x = controller_x + int(grid["x"])
    grid_y = controller_y + int(grid["y"])

    # Qubit Index and Qubit Selector
    for visual_col in range(num_qubits):
        visual_q = visual_col + 1
        internal_q = visual_col if horizontal_controller else num_qubits - 1 - visual_col
        column_x = visual_col * int(grid["col_pitch"])
        color = 10 if visual_q == cursor_visual_q else (
            (13 if visual_col % 2 == 0 else 6)
            if compact_controller and not horizontal_controller
            else 6
        )
        label_x = controller_x + int(controller["qubit_index"]["x"])
        label_y = controller_y + int(controller["qubit_index"]["y"])
        if horizontal_controller:
            label_y += visual_col * int(controller["qubit_index"].get("row_pitch", grid["row_pitch"]))
        else:
            label_x += column_x
        canvas.text(
            f"q{internal_q}",
            label_x,
            label_y,
            color,
        )
        if visual_q == cursor_visual_q:
            if horizontal_controller:
                selector_x = controller_x + int(controller["qubit_selector"]["x"])
                selector_y = (
                    controller_y
                    + int(controller["qubit_selector"]["y"])
                    + visual_col * int(controller["qubit_selector"].get("row_pitch", grid["row_pitch"]))
                    + 1
                )
                canvas.rectfill(selector_x, selector_y, selector_x, selector_y, color)
                canvas.rectfill(selector_x + 1, selector_y + 1, selector_x + 1, selector_y + 1, color)
                canvas.rectfill(selector_x, selector_y + 2, selector_x, selector_y + 2, color)
            else:
                selector = controller["qubit_selector"]
                selector_x = controller_x + int(selector["x"]) + column_x
                selector_y = controller_y + int(selector["y"])
                if selector.get("style") == "pixel_caret":
                    canvas.rectfill(
                        selector_x + 1,
                        selector_y,
                        selector_x + 1,
                        selector_y,
                        color,
                    )
                    canvas.rectfill(
                        selector_x,
                        selector_y + 1,
                        selector_x,
                        selector_y + 1,
                        color,
                    )
                    canvas.rectfill(
                        selector_x + 2,
                        selector_y + 1,
                        selector_x + 2,
                        selector_y + 1,
                        color,
                    )
                else:
                    canvas.text("^", selector_x, selector_y, color)

    # Depth Flow Indicator
    depth_flow = controller["depth_flow"]
    if depth_flow.get("enabled", True):
        for visual_row in range(1, circuit_depth):
            if horizontal_controller:
                marker_x = controller_x + int(depth_flow["x"]) + (visual_row - 1) * int(depth_flow.get("col_pitch", grid["col_pitch"]))
                marker_y = controller_y + int(depth_flow["y"]) + 1
                canvas.rectfill(marker_x, marker_y, marker_x, marker_y, 6)
                canvas.rectfill(marker_x + 1, marker_y + 1, marker_x + 1, marker_y + 1, 6)
                canvas.rectfill(marker_x, marker_y + 2, marker_x, marker_y + 2, 6)
            else:
                marker_y = (
                    controller_y
                    + int(depth_flow["y"])
                    + visual_row * int(grid["row_pitch"])
                    + int(depth_flow["gap_y"])
                )
                canvas.text("^", controller_x + int(depth_flow["x"]), marker_y, 6)

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
    depth_index = controller["depth_index"]
    for visual_row in range(circuit_depth):
        depth = visual_row + 1 if horizontal_controller else circuit_depth - visual_row
        row_y = visual_row * int(grid["row_pitch"])
        if horizontal_controller:
            canvas.text(
                str(depth),
                controller_x + int(depth_index["x"]) + visual_row * int(depth_index.get("col_pitch", grid["col_pitch"])),
                controller_y + int(depth_index["y"]),
                6,
            )
        else:
            canvas.text(
                str(depth),
                controller_x + int(depth_index["x"]),
                controller_y + int(depth_index["y"]) + row_y + int(depth_index["text_y"]),
                6,
            )

        for visual_col in range(num_qubits):
            visual_q = visual_col + 1
            if horizontal_controller:
                x = grid_x + visual_row * int(grid["col_pitch"])
                y = grid_y + visual_col * int(grid["row_pitch"])
            else:
                x = grid_x + visual_col * int(grid["col_pitch"])
                y = grid_y + row_y
            right = x + int(grid["cell_w"]) - 1
            bottom = y + int(grid["cell_h"]) - 1
            cell_color = (
                13 if visual_col % 2 == 0 else 6
            ) if compact_controller and not horizontal_controller else grid_background_color
            canvas.rectfill(x, y, right, bottom, cell_color)
            if not compact_controller:
                canvas.rect(x, y, right, bottom, grid_border_color)

            gate_type, target = gate_map.get((visual_q, depth), ("-", None))
            if gate_type == "cx":
                center_x = x + int(grid["cell_w"]) // 2
                center_y = y + int(grid["cell_h"]) // 2
                canvas.circfill(
                    center_x,
                    center_y,
                    2 if compact_controller else int(grid["control_radius"]),
                    1 if compact_controller else 7,
                )
            elif (visual_q, depth) in incoming:
                _draw_target_plus(canvas, x, y, grid, 1 if compact_controller else 7)
            elif compact_controller and gate_type == "x":
                _draw_target_plus(canvas, x, y, grid, 1)
            elif compact_controller and gate_type == "h":
                center_x = x + int(grid["cell_w"]) // 2
                center_y = y + int(grid["cell_h"]) // 2
                canvas.line(center_x - 1, center_y - 1, center_x - 1, center_y + 1, 1)
                canvas.line(center_x + 1, center_y - 1, center_x + 1, center_y + 1, 1)
                canvas.line(center_x - 1, center_y, center_x + 1, center_y, 1)
            elif gate_type in {"x", "h"}:
                text_x = x + int(grid["single_gate_text_x"])
                canvas.text(gate_type, text_x, y + int(grid["gate_text_y"]), 7)

        if compact_controller and not horizontal_controller:
            for gate in state.gates:
                if (
                    gate.gate_type != "cx"
                    or gate.target_visual_q is None
                    or gate.depth != depth
                ):
                    continue
                control_col = gate.visual_q - 1
                target_col = gate.target_visual_q - 1
                center_y = grid_y + visual_row * int(grid["row_pitch"]) + int(grid["cell_h"]) // 2
                control_x = grid_x + control_col * int(grid["col_pitch"]) + int(grid["cell_w"]) // 2
                target_x = grid_x + target_col * int(grid["col_pitch"]) + int(grid["cell_w"]) // 2
                canvas.line(control_x, center_y, target_x, center_y, 1)
                canvas.circfill(control_x, center_y, 2, 1)
                target_cell_x = grid_x + target_col * int(grid["col_pitch"])
                target_cell_y = grid_y + visual_row * int(grid["row_pitch"])
                _draw_target_plus(canvas, target_cell_x, target_cell_y, grid, 1)

    # Mission
    mission = layout["mission"]
    title = mission.get("title", {"x": 0, "y": 0, "w": mission["w"]})
    instruction = mission.get(
        "instruction", {"x": 0, "y": 10, "w": mission["w"]}
    )
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

    # Response: 4 x 4 rooms for the sixteen four-qubit basis states.
    response = layout["response"]
    counts = state.counts or {str(key): 0 for key in states}
    rooms = response["rooms"]
    room_w = int(rooms["w"])
    room_h = int(rooms["h"])
    room_cols = int(rooms["cols"])

    for index, basis_state in enumerate(states):
        basis_state = str(basis_state)
        col = index % room_cols
        row = index // room_cols
        x = int(response["x"]) + int(rooms["x"]) + col * int(rooms["col_pitch"])
        y = int(response["y"]) + int(rooms["y"]) + row * int(rooms["row_pitch"])
        wanted = int(level["target"].get(basis_state, 0)) > 0
        count = int(counts.get(basis_state, 0))
        canvas.rectfill(x, y, x + room_w - 1, y + room_h - 1, 1 if count else 0)
        canvas.rect(x, y, x + room_w - 1, y + room_h - 1, 8 if wanted else 5)
        canvas.text(basis_state, x + (room_w - 16) // 2, y + 2, 6)
        if count:
            canvas.circfill(x + 5, y + room_h - 5, 2, 11)
            canvas.text(str(count), x + 10, y + room_h - 7, 11)
        else:
            canvas.rectfill(x + 5, y + room_h - 5, x + 5, y + room_h - 5, 5)
            canvas.text("-", x + 10, y + room_h - 7, 5)

    # Layout guides are drawn last so their 1-pixel boundaries remain visible.

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
