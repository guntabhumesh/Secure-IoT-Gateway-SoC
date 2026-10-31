#!/bin/bash
# =============================================================================
# run_uvm.sh - Compile and run interface UVM testbenches
# Usage:
#   ./run_uvm.sh axi
#   ./run_uvm.sh uart
#   ./run_uvm.sh gpio
#   ./run_uvm.sh spi
#   ./run_uvm.sh i2c
#   ./run_uvm.sh jtag
#   ./run_uvm.sh all
# =============================================================================

set -e

# Tool environment setup
export VCS_HOME="${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}"
export VERDI_HOME="${VERDI_HOME:-/home/student/snps_tools_target/verdi/U-2023.03-SP1}"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}"
export LM_LICENSE_FILE="${LM_LICENSE_FILE:-27021@14.139.1.126}"
export PATH="$VCS_HOME/bin:$VERDI_HOME/bin:$PATH"

RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(readlink -f "$RUN_DIR/..")"
TB_BASE="$ROOT_DIR/scripts/interfacecsv"

TARGET="${1:-all}"

run_single_tb() {
    local VIP="$1"
    local TB_DIR="$TB_BASE/${VIP}_uvm_tb"

    if [ ! -d "$TB_DIR" ]; then
        echo "Error: Directory $TB_DIR does not exist!"
        exit 1
    fi

    echo "============================================================"
    echo " Compiling & Running $VIP UVM Testbench"
    echo "============================================================"
    cd "$TB_DIR"

    vcs -sverilog -full64 -ntb_opts uvm -timescale=1ns/1ps \
        "${VIP}_if.sv" "${VIP}_pkg.sv" tb_top.sv \
        -o "simv_${VIP}" -l "compile_${VIP}.log"

    ./"simv_${VIP}" +UVM_TESTNAME="${VIP}_test" -no_save +vcs+lic+wait -l "sim_${VIP}.log"
    echo ">> $VIP simulation completed successfully!"
}

if [ "$TARGET" = "all" ]; then
    for vip in axi uart gpio spi i2c jtag; do
        run_single_tb "$vip"
    done
else
    run_single_tb "$TARGET"
fi
