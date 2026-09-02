SHELL := /bin/bash
TEST ?= bridge_base_test
SEED ?= 1
BUG ?= none
BUILD := sim_build
RTL := rtl/axi4lite_to_apb_bridge.sv rtl/apb_memory_slave.sv
SVA := tb/assertions/axi_apb_assertions.sv
BUG_DEFINE := $(if $(filter addr,$(BUG)),+define+INJECT_ADDR_BUG,$(if $(filter resp,$(BUG)),+define+INJECT_RESP_BUG,))

.PHONY: help smoke uvm vcs verdi regression clean

help:
	@echo "make smoke                  Run directed self-checking test"
	@echo "make uvm TEST=$(TEST) SEED=1 Run UVM test with Questa"
	@echo "make vcs TEST=$(TEST) SEED=1 Run UVM test with VCS"
	@echo "make verdi                 Open the latest FSDB"
	@echo "make regression BACKEND=questa"

smoke:
	mkdir -p logs proof
	vlib $(BUILD) 2>/dev/null || true
	vlog -sv -work $(BUILD) $(RTL) $(SVA) tb/smoke/axi_apb_smoke_tb.sv
	vsim -c -lib $(BUILD) axi_apb_smoke_tb -do "run -all; quit -f" | tee logs/smoke.log
	grep -q "AXI_APB_TEST_PASS" logs/smoke.log

uvm:
	mkdir -p logs proof
	vlib $(BUILD) 2>/dev/null || true
	vlog -sv -L uvm -work $(BUILD) $(BUG_DEFINE) $(RTL) tb/uvm/axi_lite_if.sv tb/uvm/apb_if.sv $(SVA) tb/uvm/axi_apb_uvm_pkg.sv tb/uvm/tb_top.sv
	vsim -c -L uvm -lib $(BUILD) tb_top +UVM_TESTNAME=$(TEST) -sv_seed $(SEED) -do "run -all; quit -f" | tee logs/$(TEST)_$(SEED).log
	grep -q "AXI_APB_UVM_PASS" logs/$(TEST)_$(SEED).log

vcs:
	bash scripts/run_vcs.sh $(TEST) $(SEED) $(BUG)

verdi:
	bash scripts/open_verdi.sh

regression:
	python3 scripts/run_regression.py --backend $${BACKEND:-questa}

clean:
	rm -rf sim_build csrc simv simv.daidir ucli.key novas.conf novas.rc verdiLog
