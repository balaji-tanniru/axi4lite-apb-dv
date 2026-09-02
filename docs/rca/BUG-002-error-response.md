# BUG-002: APB error not propagated to AXI

## Symptom

A misaligned APB access asserts `PSLVERR`, but the AXI response incorrectly reports `OKAY` instead of `SLVERR`.

## Reproduction

Enable `INJECT_RESP_BUG=1` and issue an access to a misaligned address.

## Root cause

The injected response mapping ignores `PSLVERR` and always generates an AXI `OKAY` response.

## Correction and proof

Map `PSLVERR=1` to AXI response `2'b10`. Confirm the directed error test, assertions and full regression pass.

