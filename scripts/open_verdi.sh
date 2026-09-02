#!/usr/bin/env bash
set -euo pipefail
if [[ ! -f proof/axi_apb_wave.fsdb ]]; then
  echo "proof/axi_apb_wave.fsdb not found. Run 'make vcs' with VERDI_HOME configured first."
  exit 1
fi
verdi -dbdir sim_build/simv.daidir -ssf proof/axi_apb_wave.fsdb &
