import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from render_core import parse_grid_colors


class CartridgeColorParsingTest(unittest.TestCase):
    def test_grid_colors_come_from_draw_circuit(self) -> None:
        source = """
function draw_circuit()
  local border_color=12
  rectfill(x,y,x+grid_layout.cell_w,y+grid_layout.cell_h,3)
end
function print_centered_in_region()
end
"""
        self.assertEqual(parse_grid_colors(source), (3, 12))

if __name__ == "__main__":
    unittest.main()
