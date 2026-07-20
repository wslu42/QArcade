# Qilin Reserved Input Matrix

This is the canonical input-reservation table for framework variants and
derived games. When another document summarizes controls, this matrix wins if
the descriptions differ.

## Ownership priority

```text
completion > modal > handoff > O+X mode chord > active control mode
```

Only the highest active owner reads buttons in a frame. Leaving completion or
modal input starts a release handoff; the next owner does not run until all six
standard PICO-8 buttons are released for every participating player.

## Reserved inputs

| Context | Input | Reservation / action | Commit timing | Owner |
|---|---|---|---|---|
| Completion/result | O | Confirm, return, retry, or replay as defined by the screen | Press, followed by release handoff | Completion/modal |
| Dialogue/modal | O | Standard confirm / advance | Press, followed by release handoff when closing | Modal |
| Dialogue/modal | Right or other directions | Optional game-owned modal navigation; never the default advance action | Game-defined | Modal |
| Any non-modal gameplay mode | O+X | Reserved Classical/Quantum control-mode switch | Latch while both are held; switch after both are released | Mode chord |
| Quantum Controller | Tap X | Append X | X release | Controller |
| Quantum Controller, vertical | Hold X + Left/Right | Select cyclic CNOT target | X release | Controller |
| Quantum Controller, horizontal | Hold X + Up/Down | Select cyclic CNOT target | X release | Controller |
| Quantum Controller | Tap O | Append H | O release | Controller |
| Quantum Controller, vertical | Left/Right | Select qubit | Press | Controller |
| Quantum Controller, vertical | Up / Down | Run / clear selected qubit | Press | Controller |
| Quantum Controller, horizontal | Up/Down | Select qubit | Press | Controller |
| Quantum Controller, horizontal | Right / Left | Run / clear selected qubit | Press | Controller |
| Classical gameplay | O alone | Available for a game-owned action | Release-confirmed or pending/cancellable | Classical game |
| Classical gameplay | X alone | Available for a game-owned action | Release-confirmed or pending/cancellable | Classical game |
| Classical gameplay | Directions and face-button + direction combinations | Available for game-owned movement/actions, except O+X | Game-defined | Classical game |
| Multiplayer/PVP | Each player's Left, Right, Up, Down, O, and X | Read through `btn/btnp(button, player_index)`; P1 is index 0 and P2 is index 1 | Same action timing as the selected mode | That player's active owner |
| Keyboard remapping | Host keyboard keys mapped to the standard six buttons | Configure with PICO-8 `KEYCONFIG`; cartridges must not hard-code QWERTY letters as required controls | Host configuration | PICO-8 runtime |
| Raw/devkit keyboard | Arbitrary character events through devkit input | Optional fallback only; must not replace standard Controller input or be required for normal play | Experimental/platform-dependent | Game extension |
| Handoff | Any standard button | Consumed until all six buttons are up | No gameplay action | Handoff |

## Chord safety

O+X is recognized in either press order. Once both face buttons have been down
together, cancel pending standalone O, X, H, X-gate, and CNOT actions. Do not
perform an irreversible Classical action on the first face-button press;
confirm it on release or keep it pending so the chord can cancel it.

Modal ownership outranks the chord. O and X used by dialogue or another modal
must not switch modes or place gates. The base framework consumes O+X safely
and calls `request_control_mode_switch()` after release; derived games fill
that hook only when they implement both control modes.

Opposite D-pad chords such as Left+Right and Up+Down are not reserved and must
not be required, because many physical controllers cannot report them
reliably.

## Multiplayer and keyboard policy

PVP cartridges keep gameplay expressed in PICO-8's portable six-button
vocabulary. Give each player independent input and pending state, read P1 with
player index 0 and P2 with player index 1, and make modal handoff wait for both
players. Recommended QWERTY layouts may be documented, but they are configured
outside the cartridge with `KEYCONFIG`; the game logic remains controller- and
remapping-safe.

The maintained example is `framework/qilin_game_framework_3Qv_pvp.p8`. It
keeps separate grids, cursors, press/release history, and pending H/X/CNOT
state for player indices 0 and 1. Its center Key Map uses compact default-key
hints (`Up/e`, `Down/d`, `X/a`, and `O/sf`) only as artwork; cartridge logic
still reads standard player-indexed buttons. See `QILIN_3QV_PVP_CONTRACT.md`.

Experimental devkit keyboard input (`poke(0x5f2d,1)` with `stat(30/31)`) may be
offered as an optional enhancement only. It is not a substitute for `btn()`:
it is less suitable for held buttons, release-confirmed actions, simultaneous
gate chords, physical controllers, mobile, and portable BBS play.

### Recommended PVP QWERTY preset

When two players share one QWERTY keyboard, recommend this `KEYCONFIG` layout:

| Player | Directions | O | X |
|---|---|---|---|
| P1 / player index 0 | WASD | F | G |
| P2 / player index 1 | Arrow keys | K | L |

This separates the players into left and right keyboard zones while keeping
each face-button pair adjacent for O+X and keeping X close enough for the
X+direction CNOT gesture. It is a recommended host configuration, not a
cartridge dependency; game logic and on-screen control vocabulary remain the
standard PICO-8 buttons.
