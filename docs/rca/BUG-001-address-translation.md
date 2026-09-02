# BUG-001: Incorrect read-address translation

## Symptom

The scoreboard reports correct AXI request timing but incorrect read data.

## Reproduction

Enable `INJECT_ADDR_BUG=1`, write two different values to adjacent words, and read the first address.

## Evidence

- AXI `ARADDR` requests the expected aligned address.
- APB `PADDR` is four bytes higher than `ARADDR`.
- The APB slave legally returns data from that higher address.
- The AXI response therefore carries data from the wrong word.

## Root cause

The injected RTL path assigns `PADDR = ARADDR + 4` instead of copying `ARADDR`.

## Correction and proof

Disable the injection or correct the assignment to `PADDR = ARADDR`. Rerun the original test and seed, followed by the complete regression. Preserve the failing and passing logs and waveform markers.

