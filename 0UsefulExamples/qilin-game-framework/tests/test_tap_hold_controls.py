from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXAMPLES_ROOT = ROOT.parent


class TapHoldControlContractTest(unittest.TestCase):
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
                self.assertIn("x_released=x_was_down and not x_down", source)
                self.assertIn('try_add_gate(cx_control,"x")', source)
                preview_calls = source.count("find_gate_depth(")
                definitions = source.count("function find_gate_depth(")
                if preview_calls > definitions:
                    self.assertEqual(definitions, 1)
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
                    "completion > modal (including dialogue) > controller",
                    document,
                )
                self.assertIn("release handoff", document.lower())

        self.assertIn("exactly one input owner", contract.lower())
        self.assertIn("Right may advance dialogue", contract)

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
                    "completion > modal (including dialogue) > controller",
                    text,
                )
                self.assertIn("release handoff", text.lower())


if __name__ == "__main__":
    unittest.main()
