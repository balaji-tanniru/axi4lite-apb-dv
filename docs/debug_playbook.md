# Debug and Root-Cause Playbook

1. Record the first failing test, seed, simulation time and checker message.
2. Reproduce that exact failure before changing code.
3. Open the waveform and place a cursor at the first failure.
4. Determine whether the failed operation is an AXI read or write.
5. Check AXI handshakes, payload stability and response timing.
6. Check the corresponding APB setup, access, wait and completion cycles.
7. Compare the AXI monitor, APB monitor and scoreboard transaction values.
8. Trace the first incorrect signal backward to its RTL or testbench producer.
9. Correct the earliest wrong logic; do not weaken a checker to hide the symptom.
10. Rerun the exact test and seed, then run the complete regression.
11. Review assertions and coverage, and save proof in an RCA report.

