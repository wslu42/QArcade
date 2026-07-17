# Quantum Vault Heist

Crack a network of eight quantum vaults using a three-qubit controller.

Each vault has a three-bit address from `000` through `111`. Build a quantum
circuit, run 16 attempts, and try to send the measured outcomes only to the
gold-outlined loot vaults. Cyan doors and numbers show where your attempts
landed; red lamps identify vaults that should be avoided.

## Controls

- Left/right: select a qubit.
- Hold O/Z + up: add X.
- Hold O/Z + down: add H.
- Hold O/Z + left/right: add CX.
- Down: clear the selected qubit's gates.
- X: run the circuit.

Complete four increasingly difficult jobs to learn exact addressing,
superposition, and quantum correlation.

Open `ex_quantum_vault_heist.p8` in PICO-8 to play.
