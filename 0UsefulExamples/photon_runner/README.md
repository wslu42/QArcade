# Photon Runner

Photon Runner is a continuous side-scrolling quantum routing game for
PICO-8. Eight parallel waveguides represent the three-qubit basis states
`000` through `111`. You never steer a photon directly: every movement is
produced by the Qilin quantum Controller.

## Objective

Read the incoming waveguide pattern, build a circuit, and press Run before it
reaches the photon emitter. Gold energy packets mark the requested guides;
red blockers absorb photons traveling through the other guides.

A collected energy packet locks just before the Photon, shifts through a
short color fade, shrinks, and then disappears.

Complete all six signal waves before losing all three shields.

## Controls

- Left/Right: select a qubit column while X is not held.
- Tap X: append an X gate when the button is released.
- Hold X and tap Left/Right: move the pending CNOT target visually left/right
  across the `q2 q1 q0` columns.
  Repeated taps can reach a non-adjacent qubit and wrap cyclically. Release X
  to append one CNOT; returning the target to its control cancels it.
- Tap O/Z: append an H gate when the button is released.
- Up: run the circuit and project new photon pulses.
- Down: clear every operation controlled by, targeting, or placed on the
  selected qubit.
- O/Z on the ending screen: replay.

X and H are both release-confirmed, so holding either button never repeats a
gate. For X, pressing one or more target directions changes the gesture into
CNOT selection. If cyclic movement returns the target to its control, release
cancels the gesture; it does not fall back to an X gate.

The Controller previews a pending CNOT while X is held. A committed CNOT
draws a thin line from its control dot to its target. Its complete span is
reserved at that circuit depth, so X, H, and crossing CNOT operations cannot
be inserted between the endpoints; disjoint CNOT spans remain legal.

## Measurement and movement

Run performs 16 measurement shots. Every basis state measured at least four
times becomes a stable photon pulse in its corresponding waveguide. Several
states can therefore produce several simultaneous pulses.

The new stable pulse set replaces the old one. The Controller queue is then
cleared immediately, matching the original Qilin firing rhythm, while the
waveguides continue scrolling without a planning phase.

If no state reaches four counts, the projection is unstable: the current
photons remain, but the Controller queue is still cleared.

## Quantum ideas

- X routes a deterministic pulse by changing address bits.
- H can distribute pulses across multiple waveguides.
- CNOT creates linked measurement patterns such as `000` and `111`.

Because the circuit is sampled with a finite number of shots, split signals
can vary slightly from one Run to the next.
