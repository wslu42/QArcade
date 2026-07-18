#!/usr/bin/env python3
"""Safe parser and schema normalizer for Qilin's data-only Lua tables.

The parser intentionally supports only the subset used by Qilin layout and
level tables. Arithmetic expressions are limited to numeric literals,
parentheses, and + - * / operators. Arbitrary Lua execution is never used.
"""

from __future__ import annotations

import copy
import re
from dataclasses import dataclass
from typing import Any


class LayoutParseError(RuntimeError):
    """Raised when source data is unsupported or internally inconsistent."""


@dataclass(frozen=True)
class Token:
    kind: str
    value: str


TOKEN_RE = re.compile(
    r"""
    (?P<WS>\s+)
  | (?P<COMMENT>--[^\n]*)
  | (?P<STRING>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')
  | (?P<NUMBER>\d+(?:\.\d+)?)
  | (?P<IDENT>[A-Za-z_][A-Za-z0-9_]*)
  | (?P<SYM>[\{\}\[\]=,()+\-*/])
    """,
    re.VERBOSE,
)


def tokenize_lua(text: str) -> list[Token]:
    tokens: list[Token] = []
    pos = 0
    while pos < len(text):
        match = TOKEN_RE.match(text, pos)
        if not match:
            raise LayoutParseError(
                f"Unsupported Lua syntax near {text[pos:pos + 50]!r}"
            )
        pos = match.end()
        kind = match.lastgroup or ""
        if kind in {"WS", "COMMENT"}:
            continue
        tokens.append(Token(kind, match.group()))
    return tokens


def extract_assigned_table(source: str, name: str) -> str:
    match = re.search(rf"\b{re.escape(name)}\s*=\s*\{{", source)
    if not match:
        raise LayoutParseError(f"Lua table {name!r} was not found.")

    start = source.find("{", match.start())
    depth = 0
    in_string: str | None = None
    escaped = False
    index = start

    while index < len(source):
        char = source[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == in_string:
                in_string = None
        else:
            if char in {'"', "'"}:
                in_string = char
            elif char == "-" and index + 1 < len(source) and source[index + 1] == "-":
                newline = source.find("\n", index)
                if newline == -1:
                    break
                index = newline
                continue
            elif char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    return source[start:index + 1]
        index += 1

    raise LayoutParseError(f"Lua table {name!r} is not balanced.")


class LuaDataParser:
    """Recursive-descent parser for Qilin's data-only Lua subset."""

    def __init__(self, tokens: list[Token]):
        self.tokens = tokens
        self.index = 0

    def peek(self, *, value: str | None = None, kind: str | None = None) -> bool:
        if self.index >= len(self.tokens):
            return False
        token = self.tokens[self.index]
        return (
            (value is None or token.value == value)
            and (kind is None or token.kind == kind)
        )

    def pop(self, *, value: str | None = None, kind: str | None = None) -> Token:
        if self.index >= len(self.tokens):
            raise LayoutParseError("Unexpected end of Lua data.")
        token = self.tokens[self.index]
        if value is not None and token.value != value:
            raise LayoutParseError(f"Expected {value!r}; got {token.value!r}.")
        if kind is not None and token.kind != kind:
            raise LayoutParseError(
                f"Expected token type {kind!r}; got {token.kind!r}."
            )
        self.index += 1
        return token

    def parse(self) -> Any:
        value = self.parse_value()
        if self.index != len(self.tokens):
            raise LayoutParseError(
                f"Unexpected trailing token {self.tokens[self.index].value!r}."
            )
        return value

    def parse_value(self) -> Any:
        if self.peek(value="{"):
            return self.parse_table()
        if self.peek(kind="STRING"):
            token = self.pop(kind="STRING")
            raw = token.value[1:-1]
            return bytes(raw, "utf-8").decode("unicode_escape") if "\\" in raw else raw
        if self.peek(kind="IDENT"):
            token = self.pop(kind="IDENT")
            if token.value == "true":
                return True
            if token.value == "false":
                return False
            if token.value == "nil":
                return None
            # Bare identifiers are retained as strings for data-only tables.
            return token.value
        if self.peek(kind="NUMBER") or self.peek(value="+") or self.peek(value="-") or self.peek(value="("):
            return self.parse_expression()
        token = self.pop()
        raise LayoutParseError(f"Unsupported table value {token.value!r}.")

    # Numeric expression grammar:
    # expression := term ((+|-) term)*
    # term       := factor ((*|/) factor)*
    # factor     := (+|-) factor | NUMBER | '(' expression ')'
    def parse_expression(self) -> int | float:
        value = self.parse_term()
        while self.peek(value="+") or self.peek(value="-"):
            op = self.pop().value
            rhs = self.parse_term()
            value = value + rhs if op == "+" else value - rhs
        return normalize_number(value)

    def parse_term(self) -> int | float:
        value = self.parse_factor()
        while self.peek(value="*") or self.peek(value="/"):
            op = self.pop().value
            rhs = self.parse_factor()
            if op == "*":
                value *= rhs
            else:
                if rhs == 0:
                    raise LayoutParseError("Division by zero in Lua arithmetic expression.")
                value /= rhs
        return normalize_number(value)

    def parse_factor(self) -> int | float:
        if self.peek(value="+"):
            self.pop(value="+")
            return self.parse_factor()
        if self.peek(value="-"):
            self.pop(value="-")
            return -self.parse_factor()
        if self.peek(value="("):
            self.pop(value="(")
            value = self.parse_expression()
            self.pop(value=")")
            return value
        token = self.pop(kind="NUMBER")
        return float(token.value) if "." in token.value else int(token.value)

    def parse_key(self) -> Any | None:
        if self.peek(value="["):
            self.pop(value="[")
            key = self.parse_value()
            self.pop(value="]")
            return key
        if self.peek(kind="IDENT"):
            return self.pop(kind="IDENT").value
        return None

    def parse_table(self) -> Any:
        self.pop(value="{")
        entries: list[tuple[Any, Any]] = []
        next_array_index = 1

        while not self.peek(value="}"):
            saved_index = self.index
            key = self.parse_key()
            if key is not None and self.peek(value="="):
                self.pop(value="=")
                value = self.parse_value()
                entries.append((key, value))
            else:
                self.index = saved_index
                value = self.parse_value()
                entries.append((next_array_index, value))
                next_array_index += 1

            if self.peek(value=","):
                self.pop(value=",")

        self.pop(value="}")
        expected = list(range(1, len(entries) + 1))
        if [key for key, _ in entries] == expected:
            return [value for _, value in entries]
        return {key: value for key, value in entries}


def normalize_number(value: int | float) -> int | float:
    if isinstance(value, float) and value.is_integer():
        return int(value)
    return value


def parse_lua_table(source: str, name: str) -> Any:
    table_text = extract_assigned_table(source, name)
    return LuaDataParser(tokenize_lua(table_text)).parse()


def parse_numeric_expression(expression: str) -> int | float:
    parser = LuaDataParser(tokenize_lua(expression))
    value = parser.parse_expression()
    if parser.index != len(parser.tokens):
        raise LayoutParseError(
            f"Unexpected arithmetic token {parser.tokens[parser.index].value!r}."
        )
    return value


def parse_scalar(source: str, name: str, default: int) -> int:
    match = re.search(
        rf"(?m)^\s*{re.escape(name)}\s*=\s*([^\n;]+)",
        source,
    )
    if not match:
        return default
    expression = re.sub(r"--.*$", "", match.group(1)).strip()
    value = parse_numeric_expression(expression)
    if not isinstance(value, (int, float)):
        raise LayoutParseError(f"Scalar {name!r} is not numeric.")
    return int(value)


def _setdefault(mapping: dict[str, Any], key: str, value: Any) -> Any:
    if key not in mapping:
        mapping[key] = value
    return mapping[key]


def _child_extent(parent: dict[str, Any], *child_names: str) -> tuple[int, int]:
    max_right = 0
    max_bottom = 0
    for name in child_names:
        child = parent.get(name)
        if not isinstance(child, dict):
            continue
        x = int(child.get("x", 0))
        y = int(child.get("y", 0))
        w = int(child.get("w", 0))
        h = int(child.get("h", 0))
        max_right = max(max_right, x + w)
        max_bottom = max(max_bottom, y + h)
    return max_right, max_bottom


def normalize_layout(
    raw_layout: dict[str, Any],
    source: str,
    *,
    num_qubits: int,
    circuit_depth: int,
) -> dict[str, Any]:
    """Return one canonical layout schema without changing visible geometry."""

    layout = copy.deepcopy(raw_layout)
    controller = _setdefault(layout, "controller", {})
    controller.setdefault("x", 0)
    controller.setdefault("y", 0)

    grid = _setdefault(controller, "grid", {})
    grid.setdefault("x", 0)
    grid.setdefault("y", 0)
    grid.setdefault("col_pitch", 11)
    grid.setdefault("row_pitch", 11)

    # v49 stores inclusive far-edge offsets (8) and draws x+cell_w. Canonical
    # schema stores true dimensions (9) and draws x+cell_w-1.
    source_uses_inclusive_cell_extent = bool(
        re.search(r"x\s*\+\s*grid_layout\.cell_w\b", source)
        and re.search(r"y\s*\+\s*grid_layout\.cell_h\b", source)
    )
    raw_cell_w = int(grid.get("cell_w", 9))
    raw_cell_h = int(grid.get("cell_h", 9))
    grid["cell_w"] = raw_cell_w + 1 if source_uses_inclusive_cell_extent else raw_cell_w
    grid["cell_h"] = raw_cell_h + 1 if source_uses_inclusive_cell_extent else raw_cell_h
    grid["source_cell_extent_mode"] = (
        "inclusive_offset" if source_uses_inclusive_cell_extent else "true_dimension"
    )

    defaults = {
        "wire_top_overhang": 2,
        "wire_bottom_overhang": 0,
        "wire_arrow_half_w": 2,
        "control_radius": 1,
        "target_radius": 2,
        "gate_text_y": 2,
        "single_gate_text_x": 3,
        "multi_gate_text_x": 1,
        "fresh_outline": 1,
    }
    for key, value in defaults.items():
        grid.setdefault(key, value)

    depth_index = _setdefault(controller, "depth_index", {})
    depth_index.setdefault("x", 0)
    depth_index.setdefault("y", 0)
    if "text_y" not in depth_index:
        depth_index["text_y"] = depth_index.get("text_dy", 0)

    has_depth_flow = isinstance(controller.get("depth_flow"), dict)
    depth_flow = _setdefault(controller, "depth_flow", {})
    depth_flow["enabled"] = has_depth_flow
    depth_flow.setdefault("x", 0)
    depth_flow.setdefault("y", 0)
    if "gap_y" not in depth_flow:
        depth_flow["gap_y"] = depth_flow.get("gap_dy", 0)

    qubit_index = _setdefault(controller, "qubit_index", {})
    qubit_index.setdefault("x", 0)
    qubit_index.setdefault("y", 0)
    qubit_selector = _setdefault(controller, "qubit_selector", {})
    qubit_selector.setdefault("x", 0)
    qubit_selector.setdefault("y", 0)
    qubit_selector.setdefault("w", 4)
    qubit_selector.setdefault("h", 6)
    qubit_selector.setdefault("style", "text_caret")

    grid_width = (num_qubits - 1) * int(grid["col_pitch"]) + int(grid["cell_w"])
    grid_height = (circuit_depth - 1) * int(grid["row_pitch"]) + int(grid["cell_h"])
    required_widths = [
        int(grid.get("x", 0)) + grid_width,
        # A single P8SCII digit occupies four pixels.
        int(depth_index.get("x", 0)) + 4,
    ]
    if has_depth_flow:
        required_widths.append(int(depth_flow.get("x", 0)) + 4)
    required_controller_w = max(required_widths)
    required_controller_h = max(
        int(grid.get("y", 0)) + grid_height + int(grid["wire_bottom_overhang"]),
        int(qubit_index.get("y", 0)) + 6,
        int(qubit_selector.get("y", 0)) + int(qubit_selector["h"]),
    )
    controller["w"] = max(int(controller.get("w", 0)), required_controller_w)
    controller["h"] = max(int(controller.get("h", 0)), required_controller_h)

    key_map = _setdefault(layout, "key_map", {})
    key_map.setdefault("x", 0)
    key_map.setdefault("y", 0)
    key_map.setdefault("items", [])
    key_map.setdefault("w", 0)
    key_map.setdefault("h", 0)

    operation_feedback = _setdefault(layout, "operation_feedback", {})
    operation_feedback.setdefault("x", 2)
    operation_feedback.setdefault("y", 2)
    operation_feedback.setdefault("w", 64)
    operation_feedback.setdefault("h", 6)

    mission = _setdefault(layout, "mission", {})
    mission.setdefault("x", 0)
    mission.setdefault("y", 0)
    mission.setdefault("w", 0)
    mission.setdefault("h", 0)
    mission_children = [
        name
        for name in ("title", "instruction", "feedback")
        if isinstance(mission.get(name), dict)
    ]
    for name in mission_children:
        child = mission[name]
        child.setdefault("x", 0)
        child.setdefault("y", 0)
        child.setdefault("w", int(mission.get("w", 0)))
        child.setdefault("h", 6)
    if mission_children:
        mission_extent_w, mission_extent_h = _child_extent(
            mission, *mission_children
        )
        mission["w"] = max(int(mission["w"]), mission_extent_w)
        mission["h"] = max(int(mission["h"]), mission_extent_h)

    response = _setdefault(layout, "response", {})
    response.setdefault("x", 0)
    response.setdefault("y", 0)
    response.setdefault("w", 128)
    response.setdefault("h", 128 - int(response["y"]))

    rooms = _setdefault(response, "rooms", {})
    rooms.setdefault("x", 2)
    rooms.setdefault("y", 2)
    rooms.setdefault("cols", 4)
    rooms.setdefault("rows", 4)
    rooms.setdefault("w", 29)
    rooms.setdefault("h", 16)
    rooms.setdefault("col_pitch", 31)
    rooms.setdefault("row_pitch", 18)

    legend = _setdefault(response, "legend", {})
    legend.setdefault("x", 0)
    legend.setdefault("y", 0)
    legend.setdefault("w", int(response["w"]))
    legend.setdefault("h", 6)
    target = _setdefault(legend, "target", {})
    target.setdefault("box_x", 3)
    target.setdefault("text_x", 10)
    measured = _setdefault(legend, "measured", {})
    measured.setdefault("box_x", 53)
    measured.setdefault("text_x", 60)

    canvas = _setdefault(response, "canvas", {})
    canvas.setdefault("x", 0)
    canvas.setdefault("y", 0)
    canvas.setdefault("w", int(response["w"]))
    canvas.setdefault("h", 17)
    canvas.setdefault("base_y", int(canvas["h"]) - 1)
    canvas.setdefault("first_state_x", 0)
    canvas.setdefault("state_pitch", 16)
    canvas.setdefault("bar_w", 9)
    canvas.setdefault("measured_inset_x", 2)
    canvas.setdefault("measured_w", 5)

    state_index = _setdefault(response, "state_index", {})
    state_index.setdefault("x", 0)
    state_index.setdefault("y", 0)
    state_index.setdefault("w", int(response["w"]))
    state_index.setdefault("h", 6)
    state_index.setdefault("state_pitch", int(canvas["state_pitch"]))
    # v49 declares x=1 but subtracts 1 at draw time. Normalize the effective
    # screen origin to zero so the renderer never needs contradictory math.
    if re.search(r"state_index\.state_pitch\s*-\s*1", source):
        state_index["x"] = int(state_index.get("x", 0)) - 1

    return layout


def parse_project(source: str) -> dict[str, Any]:
    num_qubits = parse_scalar(source, "num_qubits", 3)
    circuit_depth = parse_scalar(source, "circuit_depth", 4)
    raw_layout = parse_lua_table(source, "layout")
    return {
        "num_qubits": num_qubits,
        "circuit_depth": circuit_depth,
        "states": parse_lua_table(source, "states"),
        "levels": parse_lua_table(source, "levels"),
        "layout": normalize_layout(
            raw_layout,
            source,
            num_qubits=num_qubits,
            circuit_depth=circuit_depth,
        ),
    }
