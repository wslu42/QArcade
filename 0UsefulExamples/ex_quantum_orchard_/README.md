# Quantum Orchard

Grow a tiny orchard by steering quantum seeds into the right plots. Each of
the sixteen plots represents one four-bit measurement state, from `0000` to
`1111`.

## Objective

Match the glowing target plots in each of six missions. Press Up to run the
circuit and measure 16 seeds. Exact single-plot missions require a perfect
match; missions involving superposition allow for normal sampling variation.

## Controls

- Left / Right: select a qubit.
- Tap X: add an X gate when released.
- Hold X + Left / Right: select a CNOT target; release X to commit.
- Tap O: add an H gate when released.
- Up: run and measure the circuit.
- Down: clear every gate involving the selected qubit.
- After success, Up advances and O lets you keep editing.

On a keyboard, the usual PICO-8 keys are Z for O and X for X.

## Quantum gardening

An X gate flips one address bit, H lets seeds reach multiple plots, and CNOT
links plot bits so they change together. After each run, fruit appears in the
plots that were measured; the number beside each plant is its seed count.

This game is derived from the Qilin vertical four-qubit framework. Its
authoritative cartridge is `ex_quantum_orchard.p8`.
