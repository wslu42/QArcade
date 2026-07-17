from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from layout_parser import parse_lua_table, parse_numeric_expression, parse_project


class ArithmeticParserTest(unittest.TestCase):
    def test_arithmetic_expressions(self) -> None:
        self.assertEqual(parse_numeric_expression("14-8"), 6)
        self.assertEqual(parse_numeric_expression("0+1"), 1)
        self.assertEqual(parse_numeric_expression("2*(3+4)"), 14)
        self.assertEqual(parse_numeric_expression("9/3"), 3)
        self.assertEqual(parse_numeric_expression("-(2+3)"), -5)

    def test_arithmetic_inside_table(self) -> None:
        source = "layout={x=14-8,y=(11-4),z=2*(3+1)}"
        self.assertEqual(parse_lua_table(source, "layout"), {"x": 6, "y": 7, "z": 8})


class CurrentFrameworkNormalizationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = (ROOT / "framework" / "qilin_game_framework.p8").read_text(
            encoding="utf-8"
        )
        cls.project = parse_project(cls.source)

    def test_current_adjusted_origins(self) -> None:
        layout = self.project["layout"]
        self.assertEqual((layout["controller"]["x"], layout["controller"]["y"]), (0, 0))
        self.assertEqual((layout["key_map"]["x"], layout["key_map"]["y"]), (36, 0))
        self.assertEqual((layout["mission"]["x"], layout["mission"]["y"]), (36, 29))
        self.assertEqual((layout["operation_feedback"]["x"], layout["operation_feedback"]["y"]), (36, 23))
        self.assertEqual((layout["response"]["x"], layout["response"]["y"]), (0, 54))

    def test_schema_aliases_and_dimensions(self) -> None:
        layout = self.project["layout"]
        grid = layout["controller"]["grid"]
        self.assertEqual(grid["source_cell_extent_mode"], "inclusive_offset")
        self.assertEqual((grid["cell_w"], grid["cell_h"]), (9, 9))
        self.assertEqual(layout["controller"]["depth_index"]["text_y"], 2)
        self.assertEqual(layout["controller"]["depth_flow"]["gap_y"], -2)
        self.assertEqual(layout["response"]["state_index"]["x"], 3)

    def test_parent_bounds_expand_to_children(self) -> None:
        mission = self.project["layout"]["mission"]
        self.assertGreaterEqual(mission["h"], mission["feedback"]["y"] + mission["feedback"]["h"])


if __name__ == "__main__":
    unittest.main()
