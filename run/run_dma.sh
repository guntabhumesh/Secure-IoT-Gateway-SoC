#!/bin/bash
# =============================================================================
# run_dma.sh
#
# Compile and run the DMA + AXI Interconnect testbench with VCS
# =============================================================================

set -e

export VCS_HOME="${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}"
export LM_LICENSE_FILE="${LM_LICENSE_FILE:-27021@14.139.1.126}"
export PATH="$VCS_HOME/bin:$PATH"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "============================================================"
echo " Compiling SoC DMA Interconnect Testbench with VCS"
echo "============================================================"
vcs -sverilog -full64 -timescale=1ns/1ps -debug_access+all \
    -f run/run_dma_sim.f \
    -o run/simv_dma_ic \
    -l run/compile_dma_ic.log

echo "============================================================"
echo " Running SoC DMA Simulation"
echo "============================================================"
./run/simv_dma_ic -no_save +vcs+lic+wait -l run/sim_dma_ic.log

echo ">> SoC DMA simulation completed successfully!"
