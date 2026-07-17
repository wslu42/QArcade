# Quantum Signal Rescue

The station's long-range beacon network is offline. Build small quantum
circuits to route 16 signal pulses into the beacon addresses needed for each
rescue mission.

## Objective

Each of the eight beacons represents one three-bit measurement state, from
`000` through `111`. Gold rings show the mission targets. Run the circuit and
the cyan signal counts show where its measured outcomes arrived.

Match the requested beacon pattern closely enough to stabilize the channel
and advance through all four missions.

## Controls

- Left/Right: select a qubit column.
- Hold O/Z + Up: append an X gate.
- Hold O/Z + Down: append an H gate.
- Hold O/Z + Left/Right: append a CNOT to the neighboring qubit.
- Down: clear every operation involving the selected qubit.
- X: run the circuit; after success, continue to the next mission.
- O/Z after success: edit the current circuit again.

## Quantum gameplay

X changes a definite address bit. H lets a qubit contribute multiple measured
outcomes. CNOT links the behavior of two qubits, allowing correlated beacon
pairs such as `000` and `111`.

Measurements are sampled, so evenly split missions allow a little variation
around the ideal eight-and-eight result.
