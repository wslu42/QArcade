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
        cls.source = (ROOT / "framework" / "qilin_game_framework_4Qv.p8").read_text(
            encoding="utf-8"
        )
        cls.project = parse_project(cls.source)

    def test_current_adjusted_origins(self) -> None:
        layout = self.project["layout"]
        self.assertEqual(self.project["num_qubits"], 4)
        self.assertEqual(self.project["circuit_depth"], 5)
        self.assertEqual(len(self.project["states"]), 16)
        self.assertEqual((layout["controller"]["x"], layout["controller"]["y"]), (91, 78))
        self.assertEqual((layout["key_map"]["x"], layout["key_map"]["y"]), (0, 110))
        self.assertEqual(layout["key_map"]["color"], 6)
        self.assertEqual((layout["mission"]["x"], layout["mission"]["y"]), (0, 78))
        self.assertEqual((layout["operation_feedback"]["x"], layout["operation_feedback"]["y"]), (0, 104))
        self.assertEqual((layout["response"]["x"], layout["response"]["y"]), (0, 0))
        self.assertEqual(layout["response"]["rooms"]["cols"], 4)
        self.assertEqual(layout["response"]["rooms"]["rows"], 4)
        self.assertEqual(
            (layout["response"]["rooms"]["x"], layout["response"]["rooms"]["y"]),
            (3, 3),
        )
        self.assertEqual(
            layout["mission"],
            {"x": 0, "y": 78, "w": 91, "h": 26},
        )

    def test_schema_aliases_and_dimensions(self) -> None:
        layout = self.project["layout"]
        grid = layout["controller"]["grid"]
        self.assertEqual(grid["source_cell_extent_mode"], "inclusive_offset")
        self.assertEqual((grid["cell_w"], grid["cell_h"]), (7, 7))
        self.assertEqual(layout["controller"]["depth_index"]["text_y"], 1)
        self.assertFalse(layout["controller"]["depth_flow"]["enabled"])
        self.assertEqual(layout["controller"]["h"], 50)
        self.assertEqual(
            layout["controller"]["qubit_selector"]["style"], "pixel_caret"
        )
        self.assertEqual(
            (
                layout["controller"]["qubit_selector"]["w"],
                layout["controller"]["qubit_selector"]["h"],
            ),
            (3, 2),
        )
        self.assertEqual(layout["response"]["state_index"]["x"], 0)

    def test_mission_is_a_single_developer_owned_canvas(self) -> None:
        mission = self.project["layout"]["mission"]
        self.assertNotIn("title", mission)
        self.assertNotIn("instruction", mission)
        self.assertNotIn("feedback", mission)

    def test_compact_key_map_has_matching_control_examples(self) -> None:
        items_4q = self.project["layout"]["key_map"]["items"]
        self.assertEqual(
            [item["text"] for item in items_4q],
            ["❎", "🅾️", "⬆️", "❎⬅️/❎➡️", "⬇️"],
        )

        examples_4q = self.project["layout"]["key_map"]["control_examples"]
        self.assertEqual(
            set(examples_4q),
            {"color", "x", "h", "cx", "run", "clear"},
        )
        self.assertEqual(examples_4q["color"], 13)
        self.assertEqual(examples_4q["run"]["text"], "run")
        self.assertEqual(examples_4q["clear"]["text"], "clr")

        source_3q = (
            ROOT / "framework" / "qilin_game_framework_3Qv.p8"
        ).read_text(encoding="utf-8")
        examples_3q = parse_project(source_3q)["layout"]["key_map"]["control_examples"]
        self.assertEqual(
            set(examples_3q),
            {"color", "x", "h", "cx", "run", "clear"},
        )
        self.assertEqual(examples_3q["color"], 13)

        source_orchard = (
            ROOT.parent / "ex_quantum_orchard_" / "ex_quantum_orchard.p8"
        ).read_text(encoding="utf-8")
        examples_orchard = parse_project(source_orchard)["layout"]["key_map"][
            "control_examples"
        ]
        self.assertEqual(
            set(examples_orchard),
            {"color", "x", "h", "cx", "run", "clear"},
        )
        self.assertEqual(examples_orchard["color"], 13)


class HorizontalControllerLayoutTest(unittest.TestCase):
    def test_horizontal_variant_geometry(self) -> None:
        source = (ROOT / "framework" / "qilin_game_framework_4Qh.p8").read_text(
            encoding="utf-8"
        )
        layout = parse_project(source)["layout"]
        controller = layout["controller"]
        self.assertEqual(controller["orientation"], "horizontal")
        self.assertEqual((controller["x"], controller["y"]), (78, 78))
        self.assertEqual((controller["w"], controller["h"]), (50, 50))
        self.assertEqual((layout["key_map"]["x"], layout["mission"]["x"]), (0, 0))
        self.assertEqual((layout["key_map"]["y"], layout["key_map"]["h"]), (110, 18))
        self.assertEqual(
            (layout["operation_feedback"]["y"], layout["mission"]["y"]),
            (104, 78),
        )
        self.assertEqual((layout["response"]["y"], layout["response"]["h"]), (0, 78))
        self.assertEqual(controller["depth_index"]["col_pitch"], 9)
        self.assertEqual(controller["qubit_index"]["row_pitch"], 10)


class LayoutSourceOfTruthTest(unittest.TestCase):
    CARTRIDGES = [
        ROOT / "framework" / "qilin_game_framework_4Qv.p8",
        ROOT / "framework" / "qilin_game_framework_3Qv.p8",
        ROOT / "framework" / "qilin_game_framework_4Qh.p8",
        ROOT.parent / "photon_runner" / "photon_runner.p8",
        ROOT.parent / "photon_runner" / "photon_runner_4Qv.p8",
        ROOT.parent / "ex_quantum_orchard_" / "ex_quantum_orchard.p8",
    ]

    def test_photon_3q_uses_authoritative_compact_controller_metrics(self) -> None:
        framework = parse_project(
            (ROOT / "framework" / "qilin_game_framework_3Qv.p8").read_text(
                encoding="utf-8"
            )
        )["layout"]["controller"]
        photon = parse_project(
            (ROOT.parent / "photon_runner" / "photon_runner.p8").read_text(
                encoding="utf-8"
            )
        )["layout"]["controller"]

        for key in ("x", "cell_w", "cell_h", "col_pitch", "row_pitch"):
            self.assertEqual(photon["grid"][key], framework["grid"][key])
        self.assertEqual(photon["depth_index"]["x"], framework["depth_index"]["x"])
        self.assertEqual(photon["qubit_index"], framework["qubit_index"])
        self.assertEqual(photon["qubit_selector"], framework["qubit_selector"])

    def test_q_and_depth_labels_stay_anchored_to_the_grid(self) -> None:
        for cartridge in self.CARTRIDGES:
            with self.subTest(cartridge=cartridge.name):
                project = parse_project(cartridge.read_text(encoding="utf-8"))
                controller = project["layout"]["controller"]
                grid = controller["grid"]
                num_qubits = project["num_qubits"]
                circuit_depth = project["circuit_depth"]

                if controller.get("orientation") == "horizontal":
                    grid_bottom = (
                        grid["y"]
                        + (num_qubits - 1) * grid["row_pitch"]
                        + grid["cell_h"]
                        - 1
                    )
                    self.assertEqual(controller["depth_index"]["y"], grid_bottom + 3)
                    self.assertEqual(controller["depth_index"]["x"], grid["x"] + 2)
                    self.assertEqual(controller["qubit_index"]["x"] + 8, grid["x"] - 1)
                    self.assertEqual(controller["qubit_index"]["y"], grid["y"] + 2)
                else:
                    grid_bottom = (
                        grid["y"]
                        + (circuit_depth - 1) * grid["row_pitch"]
                        + grid["cell_h"]
                        - 1
                    )
                    self.assertEqual(controller["qubit_index"]["y"], grid_bottom + 2)
                    self.assertEqual(
                        controller["qubit_selector"]["y"],
                        controller["qubit_index"]["y"] + 6,
                    )
                    self.assertEqual(
                        controller["depth_index"]["y"]
                        + controller["depth_index"]["text_y"],
                        grid["y"] + 2,
                    )

    def test_all_maintained_qilin_cartridges_share_top_level_bands(self) -> None:
        for cartridge in self.CARTRIDGES:
            with self.subTest(cartridge=cartridge.name):
                layout = parse_project(cartridge.read_text(encoding="utf-8"))["layout"]
                horizontal = layout["controller"].get("orientation") == "horizontal"
                controller_w = 50 if horizontal else 37
                left_w = 128 - controller_w
                self.assertEqual(
                    (layout["controller"]["h"], layout["key_map"]["h"]),
                    (50, 18),
                )
                self.assertEqual(
                    (layout["controller"]["x"], layout["controller"]["y"]),
                    (left_w, 78),
                )
                self.assertEqual(
                    (layout["key_map"]["x"], layout["key_map"]["y"], layout["key_map"]["w"]),
                    (0, 110, left_w),
                )
                self.assertEqual(
                    (layout["operation_feedback"]["y"], layout["mission"]["y"]),
                    (104, 78),
                )
                self.assertEqual(
                    (layout["mission"]["w"], layout["mission"]["h"]),
                    (left_w, 26),
                )
                self.assertEqual(
                    (layout["response"]["y"], layout["response"]["h"]),
                    (0, 78),
                )
                for child in ("title", "instruction", "feedback"):
                    self.assertNotIn(child, layout["mission"])


if __name__ == "__main__":
    unittest.main()
