#!/bin/bash
# =============================================================================
# run_axi_aes_i2c.sh
#
# Compile and run the integrated AXI Interconnect + AES + I2C testbench
# =============================================================================

set -e

export VCS_HOME="${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}"
export LM_LICENSE_FILE="${LM_LICENSE_FILE:-27021@14.139.1.126}"
export PATH="$VCS_HOME/bin:$PATH"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "============================================================"
echo " Compiling AXI Interconnect + AES + I2C Testbench"
echo "============================================================"
vcs -sverilog -full64 -timescale=1ns/1ps -debug_access+all \
    -f run/run_axi_aes_i2c.f \
    -o run/simv_axi_aes_i2c \
    -l run/compile_axi_aes_i2c.log

echo "============================================================"
echo " Running Simulation"
echo "============================================================"
./run/simv_axi_aes_i2c -no_save +vcs+lic+wait -l run/sim_axi_aes_i2c.log

echo ">> AXI Interconnect + AES + I2C simulation completed successfully!"
