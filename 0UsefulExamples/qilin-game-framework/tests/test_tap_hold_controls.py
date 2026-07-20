from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXAMPLES_ROOT = ROOT.parent


class TapHoldControlContractTest(unittest.TestCase):
    FRAMEWORKS = [
        ROOT / "framework" / "qilin_game_framework_3Qv.p8",
        ROOT / "framework" / "qilin_game_framework_4Qv.p8",
        ROOT / "framework" / "qilin_game_framework_4Qh.p8",
    ]

    ACTIVE_CARTRIDGES = FRAMEWORKS + [
        EXAMPLES_ROOT / "photon_runner" / "photon_runner.p8",
        EXAMPLES_ROOT / "photon_runner" / "photon_runner_4Qv.p8",
        EXAMPLES_ROOT / "ex_quantum_orchard_" / "ex_quantum_orchard.p8",
    ]

    def test_all_active_quantum_cartridges_use_release_confirmed_x(self) -> None:
        cartridges = [
            ROOT / "framework" / "qilin_game_framework_3Qv.p8",
            ROOT / "framework" / "qilin_game_framework_4Qv.p8",
            ROOT / "framework" / "qilin_game_framework_4Qh.p8",
            EXAMPLES_ROOT / "photon_runner" / "photon_runner.p8",
            EXAMPLES_ROOT / "photon_runner" / "photon_runner_4Qv.p8",
            EXAMPLES_ROOT / "ex_quantum_orchard_" / "ex_quantum_orchard.p8",
        ]
        for cartridge in cartridges:
            with self.subTest(cartridge=cartridge.name):
                source = cartridge.read_text(encoding="utf-8")
                self.assertIn("cursor_q=0", source)
                self.assertNotIn("cursor_q=2\n", source)
                self.assertNotIn("cursor_q=3\n", source)
                self.assertIn("x_released=x_was_down and not x_down", source)
                self.assertIn('try_add_gate(cx_control,"x")', source)
                preview_calls = source.count("find_gate_depth(")
                definitions = source.count("function find_gate_depth(")
                if preview_calls > definitions:
                    self.assertEqual(definitions, 1)
                self.assertIn("local preview_color=7", source)
                self.assertIn("function draw_h_gate(x,y,color)", source)
                self.assertNotIn("hold z/o", source.lower())
                self.assertNotIn(
                    "if result_ready and passed then\n    if btnp(5)", source
                )

    def test_modal_input_ownership_is_part_of_the_contract(self) -> None:
        contract = (ROOT / "docs" / "QILIN_LAYOUT_CONTRACT.md").read_text(
            encoding="utf-8"
        )
        guide = (ROOT / "docs" / "QILIN_GAME_DESIGNER_GUIDE.md").read_text(
            encoding="utf-8"
        )
        agent = (ROOT / "framework" / "AGENT.md").read_text(encoding="utf-8")

        for document in (contract, guide, agent):
            with self.subTest(document=document[:40]):
                self.assertIn(
                    "completion > modal > handoff > O+X mode chord > controller",
                    document,
                )
                self.assertIn("release handoff", document.lower())

        self.assertIn("exactly one input owner", contract.lower())
        self.assertIn("O (`btnp(4)`) is the standard dialogue", contract)
        self.assertIn("Right", contract)
        self.assertIn("not the default dialogue", contract)

        supporting_docs = [
            ROOT / "AGENTS.md",
            ROOT / "README.md",
            ROOT / "docs" / "PICO8_TRUTH_AUDIT.md",
            ROOT / "docs" / "QILIN_AGENT_PREVIEW_WORKFLOW.md",
        ]
        for path in supporting_docs:
            with self.subTest(path=path.name):
                text = path.read_text(encoding="utf-8")
                self.assertIn(
                    "completion > modal > handoff > O+X mode chord > controller",
                    text,
                )
                self.assertIn("release handoff", text.lower())

    def test_agents_are_told_about_the_optional_dtb_reference(self) -> None:
        documents = [
            ROOT / "AGENTS.md",
            ROOT / "framework" / "AGENT.md",
            ROOT / "docs" / "QILIN_GAME_DESIGNER_GUIDE.md",
        ]
        for path in documents:
            with self.subTest(path=path.name):
                text = path.read_text(encoding="utf-8")
                self.assertRegex(text, r"Dialogue\s+Text Box \(DTB\)")
                self.assertIn("reference/qilin.p8", text)
                self.assertIn("29-character", text)

        reference = (ROOT / "reference" / "qilin.p8").read_text(encoding="utf-8")
        self.assertIn("function dtb_init", reference)
        self.assertIn("function dtb_update", reference)
        self.assertIn("function dtb_draw", reference)

    def test_frameworks_dispatch_modal_handoff_and_mode_chord_first(self) -> None:
        for cartridge in self.ACTIVE_CARTRIDGES:
            with self.subTest(cartridge=cartridge.name):
                source = cartridge.read_text(encoding="utf-8")
                for function in (
                    "cancel_controller_input",
                    "begin_input_handoff",
                    "update_input_handoff",
                    "modal_input_active",
                    "modal_confirm_pressed",
                    "update_modal_input",
                    "request_control_mode_switch",
                    "update_mode_chord",
                    "active_input_owner",
                ):
                    self.assertIn(f"function {function}(", source)

                owner = source[
                    source.index("function active_input_owner()") :
                    source.index("function _init()")
                ]
                priorities = [
                    owner.index('return "completion"'),
                    owner.index('return "modal"'),
                    owner.index('return "handoff"'),
                    owner.index('return "mode_chord"'),
                    owner.index('return "controller"'),
                ]
                self.assertEqual(priorities, sorted(priorities))
                self.assertIn("if standard_buttons_up() then", source)
                self.assertIn("if btn(4) and btn(5) then", source)
                self.assertIn("if not btn(4) and not btn(5) then", source)
                self.assertIn("return btnp(4)", source)
                self.assertGreaterEqual(source.count("modal_confirm_pressed()"), 2)
                self.assertLess(
                    source.index("local owner=active_input_owner()"),
                    source.index("local x_down=btn(5)"),
                )

    def test_reserved_input_matrix_is_canonical_and_complete(self) -> None:
        matrix = (ROOT / "docs" / "QILIN_RESERVED_INPUT_MATRIX.md").read_text(
            encoding="utf-8"
        )
        for expected in (
            "completion > modal > handoff > O+X mode chord > active control mode",
            "Dialogue/modal | O",
            "Any non-modal gameplay mode | O+X",
            "Quantum Controller | Tap X",
            "Quantum Controller | Tap O",
            "Classical gameplay | O alone",
            "Classical gameplay | X alone",
            "Release-confirmed or pending/cancellable",
        ):
            self.assertIn(expected, matrix)

    def test_pvp_uses_separate_pico8_player_inputs_and_state(self) -> None:
        source = (
            ROOT / "framework" / "qilin_game_framework_3Qv_pvp.p8"
        ).read_text(encoding="utf-8")
        self.assertIn("for player_id=0,1 do", source)
        for button in range(2):
            self.assertIn(f"btn({button},player_id)", source)
        self.assertIn("btn(4,player_id)", source)
        self.assertIn("btn(5,player_id)", source)
        self.assertIn("btnp(2,player_id)", source)
        self.assertIn("btnp(3,player_id)", source)
        self.assertIn("player_states[1]", source)
        self.assertIn("player_states[2]", source)
        self.assertIn("draw_controller(layout.controller_left,0)", source)
        self.assertIn("draw_controller(layout.controller,1)", source)
        self.assertIn("function any_mode_chord_down()", source)

    def test_classical_face_button_actions_are_documented_as_chord_safe(self) -> None:
        documents = [
            ROOT / "AGENTS.md",
            ROOT / "framework" / "AGENT.md",
            ROOT / "docs" / "QILIN_GAME_DESIGNER_GUIDE.md",
        ]
        for path in documents:
            with self.subTest(path=path.name):
                text = path.read_text(encoding="utf-8").lower()
                self.assertIn("classical", text)
                self.assertIn("release", text)
                self.assertIn("pending", text)
                self.assertIn("cancellable", text)
                self.assertIn("irreversible", text)

    def test_multiplayer_keyboard_policy_is_documented_consistently(self) -> None:
        documents = [
            ROOT / "AGENTS.md",
            ROOT / "framework" / "AGENT.md",
            ROOT / "docs" / "QILIN_GAME_DESIGNER_GUIDE.md",
            ROOT / "docs" / "QILIN_RESERVED_INPUT_MATRIX.md",
        ]
        for path in documents:
            with self.subTest(path=path.name):
                text = path.read_text(encoding="utf-8").lower()
                self.assertIn("keyconfig", text)
                self.assertIn("p1", text)
                self.assertIn("p2", text)
                self.assertIn("optional", text)
                self.assertIn("handoff", text)
                self.assertIn("wasd", text)
                self.assertIn("arrow", text)


if __name__ == "__main__":
    unittest.main()
