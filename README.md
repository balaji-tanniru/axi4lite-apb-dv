AXI4-Lite to APB Bridge Verification

I built this project to practice RTL design and design verification using an AXI4-Lite to APB bridge.

The bridge receives read and write requests from the AXI4-Lite side and converts them into APB transfers. I used an APB memory model to check that the correct address, data and response are returned.

Test result

The directed smoke test completed successfully:

AXI_APB_TEST_PASS checks=5 errors=0

The test performed:

Two write transactions

Two read transactions

One invalid-address transaction to check the error response

Waveform

The waveform below was generated during the passing test and opened using GTKWave.



In the waveform, I can check the AXI request and response signals together with the APB setup and access phases. This helps confirm that every AXI transaction becomes the correct APB transaction.

Tools used

SystemVerilog for RTL and testbench code

Icarus Verilog for the completed functional smoke test

GTKWave for waveform debugging

Python and Makefile scripts for automation and regressions

Git and GitHub for version control

VS Code for development

Verification components

Directed self-checking smoke test

UVM testbench structure with driver, monitor, scoreboard and coverage model

SystemVerilog protocol assertions

APB memory slave with wait-state and error support

Regression script with repeatable seeds

Intentional bug cases and root-cause-analysis notes

Assertions

The assertion module checks rules such as:

PENABLE must not be active without PSEL

An APB access phase must have a setup phase first

APB address and control signals must remain stable during wait states

AXI read and write responses must remain stable during backpressure

The assertion and UVM files are included in the project. The passing result shown above is from the Icarus Verilog functional smoke test; I do not report assertion or coverage percentages that were not measured by a supported simulator.

Project folders

rtl/              Bridge RTL and APB memory slave
tb/smoke/         Directed self-checking testbench
tb/uvm/           UVM environment
tb/assertions/    Protocol assertions
scripts/          Regression and simulator scripts
docs/             Verification plan, waveform and RCA notes

Debug method

When a test fails, I first check the test name, seed and simulation time. Then I open the waveform, compare the AXI and APB handshakes, find the first incorrect signal and trace it back to the RTL or testbench source. After correcting the issue, I rerun the same test and then the regression.

Current status

Functional smoke test: PASS

Checks: 5

Errors: 0

Waveform: generated and reviewed in GTKWave

UVM, assertions and coverage: included for use with a simulator that supports them

Simple interview explanation

I designed and verified an AXI4-Lite to APB bridge. I tested write, read and error transactions with a self-checking testbench. I used the waveform to verify the AXI handshakes, APB setup/access phases and returned data. I also organized UVM components, assertions, regression scripts and bug-analysis notes in the repository.
