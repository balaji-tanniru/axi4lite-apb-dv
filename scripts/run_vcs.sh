#!/usr/bin/env bash
set -euo pipefail
test_name="${1:-bridge_base_test}"
seed="${2:-1}"
bug="${3:-none}"
mkdir -p sim_build logs proof

fsdb_flags=()
bug_flags=()
[[ "$bug" == "addr" ]] && bug_flags=(+define+INJECT_ADDR_BUG)
[[ "$bug" == "resp" ]] && bug_flags=(+define+INJECT_RESP_BUG)
if [[ -n "${VERDI_HOME:-}" ]]; then
  fsdb_flags=(-P "$VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab" "$VERDI_HOME/share/PLI/VCS/LINUX64/pli.a" +define+FSDB)
else
  echo "VERDI_HOME is not set; VCS will generate VCD instead of FSDB."
fi

vcs -full64 -sverilog -ntb_opts uvm-1.2 -debug_access+all -kdb \
  "${fsdb_flags[@]}" \
  "${bug_flags[@]}" \
  rtl/axi4lite_to_apb_bridge.sv rtl/apb_memory_slave.sv \
  tb/uvm/axi_lite_if.sv tb/uvm/apb_if.sv tb/assertions/axi_apb_assertions.sv \
  tb/uvm/axi_apb_uvm_pkg.sv tb/uvm/tb_top.sv \
  -o sim_build/simv

sim_build/simv +UVM_TESTNAME="$test_name" +ntb_random_seed="$seed" \
  | tee "logs/${test_name}_${seed}.log"
grep -q "AXI_APB_UVM_PASS" "logs/${test_name}_${seed}.log"
