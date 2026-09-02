# Verification Plan

## Objective

Prove that the bridge converts one-outstanding AXI4-Lite read and write requests into legal APB transfers and returns correct data and responses under normal traffic, wait states, backpressure, reset and error conditions.

## Requirements and evidence

| ID | Requirement | Test/stimulus | Checker | Coverage intent |
|---|---|---|---|---|
| VP-01 | Reset returns all channels to idle | Reset at startup and between transfers | Reset assertions and monitor | Reset observed |
| VP-02 | AXI write becomes an APB write | Directed and random writes | End-to-end scoreboard | Write crossed with response |
| VP-03 | AXI read returns APB data | Directed and random reads | Reference model and scoreboard | Read crossed with address region |
| VP-04 | APB setup precedes access | Every transfer | `apb_setup_before_access` | Setup-to-access cover property |
| VP-05 | APB controls remain stable during wait | Slave inserts wait state | `apb_control_stable_during_wait` | Wait-state completion covered |
| VP-06 | AXI response remains stable under backpressure | Random BREADY/RREADY delay | AXI stability assertions | 0-3 backpressure cycles |
| VP-07 | APB error maps to AXI SLVERR | Misaligned address | Scoreboard response comparison | OKAY and SLVERR bins |
| VP-08 | Byte strobes update selected bytes only | Random WSTRB | Reference memory model | Nonzero strobe values |

## Exit criteria

- All planned tests pass with zero unexpected UVM errors.
- Every assertion passes; intended cover properties are observed.
- Functional coverage holes are reviewed and explained or closed.
- Every discovered bug has a reproducible test name and seed.
- The original failing test and complete regression pass after each fix.

