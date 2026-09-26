#!/bin/bash
# =============================================================================
# run_soc_veer.sh  –  VCS + Verdi run script for Secure IoT Gateway SoC + VeeR EL2
#
# Project  : Secure IoT Gateway SoC
# DUT top  : soc_top_with_veer
# Testbench: tb_soc_top  (existing TB — drives s00/s01 AXI directly)
#
# Usage (run from proj_dir/run/):
#   chmod +x run_soc_veer.sh
#   ./run_soc_veer.sh              # compile → simulate → open Verdi
#   ./run_soc_veer.sh compile      # compile only
#   ./run_soc_veer.sh sim          # simulate only (needs prior compile)
#   ./run_soc_veer.sh wave         # open Verdi on existing FSDB
#   ./run_soc_veer.sh clean        # remove generated artifacts
#
# =============================================================================

# ---------------------------------------------------------------------------
# 0.  Tool environment
# ---------------------------------------------------------------------------
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export PATH=${VCS_HOME}/bin:${VERDI_HOME}/bin:${PATH}
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126

# VeeR EL2 root (needed by el2_veer_wrapper for `include resolution)
export RV_ROOT=$(realpath ../rtl/Cores-VeeR-EL2)

# ---------------------------------------------------------------------------
# 1.  Names
# ---------------------------------------------------------------------------
FILELIST="run_soc_veer.f"
SIMV="simv_soc_veer"
FSDB="dump_soc_veer.fsdb"
COMPILE_LOG="compile_soc_veer.log"
SIM_LOG="sim_soc_veer.log"

# ---------------------------------------------------------------------------
# 2.  VCS flags
# ---------------------------------------------------------------------------
#
#  -sverilog            : required — VeeR RTL is SystemVerilog (.sv)
#  -full64              : 64-bit compile (Linux x86_64)
#  -f run_soc_veer.f    : file list
#  -o simv_soc_veer     : output binary name
#  -debug_acc+all       : full signal access for Verdi probing
#  -debug_region+cell   : include all hierarchy levels
#  -kdb                 : Verdi Knowledge Database for RTL annotation
#  -timescale=1ns/1ps   : global timescale (matches existing SoC TB)
#  -ntb_opts uvm-1.2    : needed if any VeeR UVM assertions are compiled
#  +define+RV_BUILD_AXI4 : force AXI4 bus mode (matches generated headers)
#  -P novas.tab / pli.a : Verdi PLI for $fsdbDumpvars
# ---------------------------------------------------------------------------
VCS_FLAGS=(
    -sverilog
    -full64
    -f "${FILELIST}"
    -o "${SIMV}"
    -debug_acc+all
    -debug_region+cell
    -kdb
    -timescale=1ns/1ps
    +define+RV_BUILD_AXI4
    +define+RV_BUILD_AXI_NATIVE
    -P "${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab"
    "${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a"
)

# ---------------------------------------------------------------------------
# 3.  Simulation flags
# ---------------------------------------------------------------------------
SIM_FLAGS=(
    -l "${SIM_LOG}"
    +fsdbfile+"${FSDB}"
    +fsdb+autoflush
    +vcs+finish+10000000    # safety timeout: 10M ns
)

# ---------------------------------------------------------------------------
# 4.  Functions
# ---------------------------------------------------------------------------
do_compile() {
    echo "============================================================"
    echo " [1/3] Compiling SoC+VeeR with VCS ..."
    echo "============================================================"
    vcs "${VCS_FLAGS[@]}" 2>&1 | tee "${COMPILE_LOG}"
    local rc=${PIPESTATUS[0]}
    [ $rc -ne 0 ] && { echo "ERROR: Compile failed (rc=$rc). See ${COMPILE_LOG}"; exit $rc; }
    echo "Compile OK  →  ${SIMV}"
}

do_simulate() {
    [ ! -x "${SIMV}" ] && { echo "ERROR: ${SIMV} not found. Run compile first."; exit 1; }
    echo "============================================================"
    echo " [2/3] Running simulation ..."
    echo "============================================================"
    ./"${SIMV}" "${SIM_FLAGS[@]}"
    echo "Simulation done  →  ${FSDB}  |  ${SIM_LOG}"
}

do_wave() {
    [ ! -f "${FSDB}" ] && { echo "ERROR: ${FSDB} not found. Run simulate first."; exit 1; }
    echo "============================================================"
    echo " [3/3] Opening Verdi ..."
    echo "============================================================"
    verdi -f "${FILELIST}" \
          -ssf "${FSDB}"   \
          -nologo &
    echo "Verdi PID $!"
}

do_clean() {
    rm -rf "${SIMV}" "${SIMV}.daidir" simv_soc_veer.daidir csrc \
           "${COMPILE_LOG}" "${SIM_LOG}" "${FSDB}" \
           ucli.key vc_hdrs.h verdi_config_file \
           novas.conf novas.rc novas_dump.log verdiLog AN.DB
    echo "Clean done."
}

case "${1:-all}" in
    compile) do_compile ;;
    sim)     do_simulate ;;
    wave)    do_wave ;;
    clean)   do_clean ;;
    all|"")  do_compile; do_simulate; do_wave ;;
    *)       echo "Usage: $0 [compile|sim|wave|clean|all]"; exit 1 ;;
esac
