#!/bin/bash
# =============================================================================
# run_soc_all_ips_bfm.sh
#
# Compile and run the integrated All-IPs AXI interconnect testbench (without CPU)
# using Synopsys VCS.
# =============================================================================

set -e

# Tool environment setup
export VCS_HOME="${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}"
export LM_LICENSE_FILE="${LM_LICENSE_FILE:-27021@14.139.1.126}"
export PATH="$VCS_HOME/bin:$PATH"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "============================================================"
echo " Compiling Integrated All-IPs Testbench with VCS"
echo "============================================================"
vcs -sverilog -full64 -timescale=1ns/1ps -debug_access+all \
    -f run/run_soc_all_ips_bfm.f \
    -o run/simv_all_ips_bfm \
    -l run/compile_all_ips_bfm.log

echo "============================================================"
echo " Running Integrated All-IPs Simulation"
echo "============================================================"
./run/simv_all_ips_bfm -no_save +vcs+lic+wait -l run/sim_all_ips_bfm.log

echo ">> Integrated All-IPs simulation completed successfully!"
