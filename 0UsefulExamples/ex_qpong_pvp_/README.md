# Quantum Pong PVP

Quantum Pong PVP is a local two-player PICO-8 game built from the Qilin
3Qv PVP framework. Each player programs a three-qubit circuit that controls
where their paddles appear. Running a circuit converts its expected state
distribution into one or more simultaneously active paddles.

The first player to five points wins. The development build starts with P2
controlled by an NPC so one person can test the full match loop.

## Start menu

The cartridge opens on a lane-order menu instead of starting immediately:

- Up / Down: choose Binary or Gray.
- O: confirm and start the match.
- Binary is selected by default on the first launch.

The selected mode appears in the HUD as `bin>=5` or `gry>=5`. After a match,
press O on the result screen to return to the same menu and choose the next
mode. Starting a match resets both quantum Controller states, scores, and the
NPC position.

## NPC test mode

`p2_is_npc=true` is the default cartridge setting. In this mode:

- P1 uses the quantum Controller and threshold-based multi-paddle defense.
- P2 uses one classical paddle with unrestricted horizontal movement.
- The NPC follows the incoming ball at a limited speed and returns toward the
  center while the ball travels away.
- P2's lower-right Controller is replaced by an `NPC / CLASSIC / AUTO X`
  status panel.

Set `p2_is_npc=false` in the cartridge to restore the human-vs-human quantum
PVP path.

## Rotated court

The Pong court is rotated clockwise inside the `128 x 94` Response. P1
defends the top edge and P2/NPC defends the bottom edge. The ball primarily
travels vertically, while the eight state lanes run from left to right. Both
paddles are horizontal, and the court leaves dedicated space inside its top
and bottom edges for their full collision shapes.

## Layout variants

- `ex_qpong_pvp.p8` keeps the two Controllers in the lower control band.
- `ex_qpong_pvp_vertical.p8` gives the entire left `91 x 128` region to the
  Response. P1's quantum Controller occupies the upper-right corner, the P2
  classical NPC status panel occupies the lower-right corner, and the widened
  `37`-pixel Key Map fills the space
  between them with
  Run, Clear, X, H, CNOT-left, and CNOT-right on separate lines. The two CNOT
  rows use opposite control/target diagrams matching their target direction.
  P1 uses the quantum Controller while P2 remains a classical NPC. The NPC
  samples the incoming ball position only after a reaction delay and can move
  only one complete state lane at a time, such as `000` to `001`. Each lane
  change has a long cooldown, and reversing direction adds another pause,
  giving the paddle visible latency and heavy inertia. State bar labels appear
  once near each paddle without overlapping its collision area.

## Controls

In human-vs-human mode, both players use a standard PICO-8 six-button
controller. P1 is player index 0 and P2 is player index 1.

- Left / Right: select a qubit.
- Tap X: append an X gate.
- Hold X and press Left / Right: choose a CNOT target; release X to commit.
- Tap O: append an H gate.
- Up: run the circuit and update the paddle distribution.
- Down: clear every gate involving the selected qubit.

For two players sharing one keyboard, configure PICO-8 `KEYCONFIG` with the
recommended mapping:

- P1: WASD, F for O, G for X.
- P2: arrow keys, K for O, L for X.

## Quantum gameplay

The active lane-order mode maps states `000` through `111` onto the eight Pong
lanes. A state becomes a solid, collidable paddle when its expected count is
at least 5 out of 16. X can address one deterministic lane, while H and CNOT
can produce multiple valid paddles through superposition and correlation.

Press Up after editing to commit a new distribution. The game uses expected
counts, so repeating the same circuit produces the same paddle set. If no
state reaches 5, the run is invalid and the previous valid paddle set remains
active.

## Lane-order modes

The cartridge separates quantum state identity from its horizontal Pong
position. Set `lane_mode` near the top of the cartridge to select a mapping.

Binary / X-friendly is the default:

```lua
lane_mode="binary"
-- 000 001 010 011 100 101 110 111
```

Gray / superposition-friendly is also available:

```lua
lane_mode="gray"
-- 000 001 011 010 110 111 101 100
```

In Gray mode, neighboring lanes differ by one bit along the Gray-code path,
so selected H-generated pairs become adjacent defensive paddles. Changing the
mode only remaps states to screen positions; it does not change the circuit,
expected counts, threshold, or collision rules. The HUD shows `bin>=5` or
`gry>=5` for the active mapping.

The rotated court labels each left-to-right lane with compact `q2 q1 q0` bar
notation. A bright three-pixel vertical bar represents `1`; a dim baseline
pixel represents `0`. One empty pixel separates neighboring bits, so each
three-bit state occupies five pixels. Full binary strings remain visible in
the start menu examples.

## Credits and provenance

This derived example uses the Qilin Game Framework's MicroQiskit simulator,
two-player Controller, modal input ownership, and layout contract.

Gameplay is loosely inspired by QPong:
https://github.com/QPong/QPong

No QPong source code is copied into this cartridge.
