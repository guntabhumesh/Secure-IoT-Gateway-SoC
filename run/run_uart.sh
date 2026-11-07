#!/bin/bash
# =============================================================================
# run_uart.sh
#
# Compile and run the standalone SoC UART verification testbench
# =============================================================================

set -e

export VCS_HOME="${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}"
export LM_LICENSE_FILE="${LM_LICENSE_FILE:-27021@14.139.1.126}"
export PATH="$VCS_HOME/bin:$PATH"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "============================================================"
echo " Compiling SoC UART Standalone Testbench with VCS"
echo "============================================================"
vcs -sverilog -full64 -timescale=1ns/1ps -debug_access+all \
    -f run/run_uart.f \
    -o run/simv_uart_tb \
    -l run/compile_uart_tb.log

echo "============================================================"
echo " Running SoC UART Simulation"
echo "============================================================"
./run/simv_uart_tb -no_save +vcs+lic+wait -l run/sim_uart_tb.log

echo ">> SoC UART simulation completed successfully!"
