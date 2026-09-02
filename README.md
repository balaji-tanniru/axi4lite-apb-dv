# AXI4-Lite to APB Bridge Design Verification

An industry-style verification project for a one-outstanding AXI4-Lite to APB bridge. The repository demonstrates specification-driven verification, reusable UVM components, SystemVerilog assertions, constrained-random stimulus, an end-to-end scoreboard, functional coverage, regression automation, waveform debugging and documented root-cause analysis.

## Why this project matters

The bridge sits between a higher-performance system bus and a simpler peripheral bus. Verification must prove more than individual signal toggles: one AXI request must become the correct APB transfer, survive wait states and backpressure, return the correct response, and never lose or corrupt data.

```text
AXI4-Lite request
        |
        v
+-------------------+        +------------------+
| AXI-to-APB bridge |------->| APB memory slave |
|       DUT         |<-------|   wait + errors  |
+-------------------+        +------------------+
        |
        v
AXI4-Lite response
```

## Verification architecture

```text
UVM test / constrained-random sequence
                  |
           AXI sequencer
                  |
             AXI driver
                  |
                  v
AXI monitor ---> DUT ---> APB monitor
      |                       |
      +--------> scoreboard <-+
      |
      +--------> functional coverage

Assertions continuously check AXI and APB protocol rules.
```

## What is verified

- AXI4-Lite read and write handshakes
- Independent AXI write-address and write-data channels
- AXI response backpressure
- APB setup and access phases
- APB wait states
- Address, control and data stability
- Byte write strobes
- Read-data integrity
- APB error to AXI error-response mapping
- Reset behavior
- Repeated random traffic using reproducible seeds

The detailed requirements-to-checker mapping is in [docs/verification_plan.md](docs/verification_plan.md).

## Direct connection to the professional verification ecosystem

The engineering method is portable even when different licenses or tools are available. The project separates source code, simulation, waveform storage, debug and regression management so the same verification environment can move between toolchains.

| Skill practiced in this repository | Current workflow | Direct professional equivalent | Knowledge that transfers |
|---|---|---|---|
| Edit RTL, UVM and assertions | VS Code | Verdi IDE or another RTL IDE | SystemVerilog navigation, hierarchy, classes, interfaces and source review |
| Compile and simulate | Questa target in `Makefile` | VCS compile, elaboration and simulation | File ordering, UVM test selection, plusargs, seeds, logs and simulator failures |
| Record simulation activity | VCD | FSDB | Selecting scopes/signals, controlling waveform size and reproducing time-based behavior |
| Inspect timing and values | GTKWave | Verdi waveform viewer | Cursors, zooming, edge-by-edge protocol analysis and expected-versus-actual comparison |
| Trace a wrong value | Waveform plus VS Code source search | Trace Driver, Trace Load, schematic and temporal-flow views | Following a symptom backward to the earliest incorrect producer |
| Analyze assertion failures | Simulator log plus waveform | Verdi assertion analysis | Jumping from a failed property to the responsible cycle, signals and source rule |
| Run test lists and seeds | `run_regression.py` | Verification management/regression system | Test submission, reproducibility, pass/fail collection, failure triage and reporting |
| Review verification completeness | UVM covergroup and verification plan | Coverage database and coverage dashboard | Mapping requirements to tests, checkers and coverage holes |
| Preserve debug evidence | RCA Markdown reports and Git history | Collaborative debug database/dashboard | Communicating symptom, evidence, root cause, correction and regression proof |

### VCS and Verdi readiness

The same UVM source supports a VCS target through `scripts/run_vcs.sh`. When a licensed environment and `VERDI_HOME` are available, the target enables debug access, creates an FSDB file and opens it using the `make verdi` command.

This repository does **not** claim that a VCS/Verdi run was completed unless genuine logs and FSDB evidence are added. Until then, the validated local workflow should be described using the simulator and waveform viewer actually used.

## Debug workflow used in the project

```text
Run one test
    |
    v
Assertion or scoreboard reports the first failure
    |
    v
Record test name, seed, time, expected value and actual value
    |
    v
Open waveform and validate AXI and APB handshakes pin by pin
    |
    v
Trace the first incorrect signal back to its producer
    |
    v
Correct the smallest faulty RTL/testbench logic
    |
    v
Rerun the exact failure, then run the complete regression
```

See [docs/debug_playbook.md](docs/debug_playbook.md) for the repeatable RCA procedure.

## Assertions

The assertion module checks important protocol invariants:

- `PENABLE` cannot be active without `PSEL`.
- Every APB access must be preceded by a setup phase.
- APB address, direction, data and strobes remain stable during a wait state.
- AXI B-channel response remains stable under backpressure.
- AXI R-channel data and response remain stable under backpressure.

Cover properties record successful wait-state completion, write response and error response scenarios.

## Intentional bug cases

The bridge contains disabled-by-default bug-injection parameters. They provide reproducible failures without leaving the normal design broken.

| Bug | Injected behavior | Expected detection | RCA |
|---|---|---|---|
| BUG-001 | Read address translated to the next word | Scoreboard read-data mismatch and AXI/APB address comparison | [Address translation RCA](docs/rca/BUG-001-address-translation.md) |
| BUG-002 | APB `PSLVERR` converted to AXI `OKAY` | Response scoreboard mismatch | [Error response RCA](docs/rca/BUG-002-error-response.md) |

This demonstrates the complete failure lifecycle: reproduce, observe, isolate, explain, correct and prove.

Reproduce each intentional failure with an exact test and seed:

```bash
make uvm TEST=bridge_smoke_test SEED=1 BUG=addr
make uvm TEST=bridge_error_test SEED=7 BUG=resp
```

Both commands are expected to fail their scoreboard checks. Run again with `BUG=none` to prove the corrected design passes.

## Repository structure

```text
rtl/
  axi4lite_to_apb_bridge.sv     DUT
  apb_memory_slave.sv           APB test slave with wait state and errors
tb/
  assertions/                   Protocol properties
  smoke/                        Small directed self-checking testbench
  uvm/                          Interfaces, sequences, agent, monitors,
                                scoreboard, coverage, environment and test
scripts/
  run_regression.py             Multi-seed regression and CSV summary
  run_vcs.sh                    VCS-compatible compile/run target
  open_verdi.sh                 FSDB debug launcher
docs/
  verification_plan.md          Requirements, tests, checkers and exit criteria
  debug_playbook.md             Repeatable failure-to-RCA method
  rca/                          Bug investigation root-cause reports
proof/                          Generated waveform evidence (not committed by default)
```

## Running with Questa

Open a Linux/WSL terminal in the project directory:

```bash
make smoke
make uvm TEST=bridge_smoke_test SEED=1
BACKEND=questa make regression
```

Open the generated VCD:

```bash
gtkwave proof/axi_apb_wave.vcd
```

## Running with VCS and Verdi

Use these commands only in a licensed environment:

```bash
make vcs TEST=bridge_smoke_test SEED=1
make verdi
BACKEND=vcs make regression
```

The flow uses:

- `-sverilog` for SystemVerilog
- `-ntb_opts uvm-1.2` for UVM
- `-debug_access+all -kdb` for source/hierarchy debug
- `+ntb_random_seed` for reproducible constrained-random tests
- FSDB dumping when `VERDI_HOME` is configured

## Regression result format

```text
PASS bridge_smoke_test        seed=    1    2.31s
PASS bridge_base_test         seed=   29    2.20s
PASS bridge_base_test         seed=   47    2.25s
REGRESSION PASS total=5 failed=0
```

The script also writes `logs/regression_summary.csv` and a complete runner log for every test/seed.

## Honest project status

- RTL, UVM architecture, assertions, automation and documentation are provided.
- CI performs synthesizable RTL lint and Python syntax checking.
- Simulator-specific UVM, assertion and coverage results must be generated in the user’s licensed local environment.
- Coverage percentages are reported only after a supported coverage run; no percentage is invented.

## Interview explanation

> I created a specification-driven UVM environment for an AXI4-Lite-to-APB bridge. The environment uses constrained-random AXI traffic, passive protocol monitoring, an end-to-end reference scoreboard, protocol assertions and functional coverage. I automated multi-seed regressions and documented reproducible injected bugs from first failure through waveform analysis, signal tracing, root-cause correction and regression proof. The source and automation are tool-portable, with separate targets for my available simulator and for VCS/Verdi environments.
