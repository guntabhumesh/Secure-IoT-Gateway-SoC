#!/bin/bash
# =============================================================================
# run_spi.sh  -  VCS + Verdi run script for SPI Master verification
#
# Project  : Secure IoT Gateway SoC
# Block    : SPI Master  (spi-master-master)
# DUT      : SPI_Master_With_Single_CS  (wraps SPI_Master)
# Testbench: SPI_Master_With_Single_CS_TB.sv
#
# Usage (run from proj_dir/run/):
#   chmod +x run_spi.sh
#   ./run_spi.sh              # compile + simulate + open Verdi
#   ./run_spi.sh compile      # compile only
#   ./run_spi.sh sim          # simulate only (needs prior compile)
#   ./run_spi.sh wave         # open Verdi waveform only
#   ./run_spi.sh clean        # remove generated files
#
# Prerequisites:
#   - VCS   installed at /home/student/snps_tools_target/vcs/U-2023.03
#   - Verdi installed at /home/student/snps_tools_target/verdi/U-2023.03-SP1
#   - License server: 27021@14.139.1.126
# =============================================================================

# ---------------------------------------------------------------------------
# 0.  Tool paths and license
# ---------------------------------------------------------------------------

# VCS installation root
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
# Verdi installation root
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1

# Add tool binaries to PATH
export PATH=${VCS_HOME}/bin:${VERDI_HOME}/bin:${PATH}

# Synopsys license server  (change if your server address differs)
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126

# ---------------------------------------------------------------------------
# 1.  File / directory names
# ---------------------------------------------------------------------------

FILELIST="run_spi.f"           # VCS filelist created alongside this script
SIMV="simv_spi"                # Compiled simulation binary
FSDB="dump_spi.fsdb"           # FSDB waveform file (written by TB)
COMPILE_LOG="compile_spi.log"  # VCS compilation log
SIM_LOG="sim_spi.log"          # Simulation run log
RC_FILE="spi_signals.rc"       # Verdi signal/waveform RC file

# ---------------------------------------------------------------------------
# 2.  VCS compilation flags
# ---------------------------------------------------------------------------
#
#  -sverilog          : enable SystemVerilog (needed by TB .sv files)
#  -full64            : 64-bit compilation (required on 64-bit Linux)
#  -f run_spi.f       : read source file list from run_spi.f
#  -o simv_spi        : name the compiled binary simv_spi
#  -debug_acc+all     : full debug access (needed for Verdi probing)
#  -debug_region+cell : include cell/instance-level debug regions
#  -kdb               : generate Knowledge Database for Verdi (RTL-aware)
#  -lca               : enable Low-Coverage Acceleration
#  -timescale=1ns/1ps : global timescale (TB sets its own via $dumpfile)
#
#  Verdi PLI integration:
#  -P  <novas.tab>    : PLI table for FSDB dump calls ($fsdbDumpvars etc.)
#  pli.a              : Verdi PLI archive linked into simv
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
    -P "${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab"
    "${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a"
)

# ---------------------------------------------------------------------------
# 3.  Simulation run flags
# ---------------------------------------------------------------------------
#
#  -l sim_spi.log    : write simulation log to file
#  +fsdbfile+...     : tell the PLI layer which FSDB file to create
#  -ucli             : enable TCL/UCLI interactive debug shell
#  +fsdb+autoflush   : flush FSDB on every $finish (avoids truncated files)
# ---------------------------------------------------------------------------

SIM_FLAGS=(
    -l "${SIM_LOG}"
    +fsdbfile+"${FSDB}"
    +fsdb+autoflush
)

# ---------------------------------------------------------------------------
# 4.  Helper functions
# ---------------------------------------------------------------------------

do_compile() {
    echo "============================================================"
    echo " [1/3] Compiling SPI Master with VCS ..."
    echo "============================================================"
    echo "CMD: vcs ${VCS_FLAGS[*]} 2>&1 | tee ${COMPILE_LOG}"
    vcs "${VCS_FLAGS[@]}" 2>&1 | tee "${COMPILE_LOG}"
    local status=${PIPESTATUS[0]}
    if [ $status -ne 0 ]; then
        echo "ERROR: VCS compilation failed (exit $status). See ${COMPILE_LOG}."
        exit $status
    fi
    echo "Compilation OK  ->  ${SIMV}"
}

do_simulate() {
    if [ ! -x "${SIMV}" ]; then
        echo "ERROR: '${SIMV}' not found. Run compile first."
        exit 1
    fi
    echo "============================================================"
    echo " [2/3] Running simulation ..."
    echo "============================================================"
    echo "CMD: ./${SIMV} ${SIM_FLAGS[*]}"
    ./"${SIMV}" "${SIM_FLAGS[@]}"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "WARNING: Simulation exited with status $status. Check ${SIM_LOG}."
    fi
    echo "Simulation finished  ->  ${FSDB}  |  ${SIM_LOG}"
}

do_wave() {
    if [ ! -f "${FSDB}" ]; then
        echo "ERROR: '${FSDB}' not found. Run simulate first."
        exit 1
    fi
    echo "============================================================"
    echo " [3/3] Opening Verdi waveform viewer ..."
    echo "============================================================"
    # -f       : source filelist (gives Verdi access to RTL for annotation)
    # -ssf     : specify FSDB file to load
    # -rc      : load signal/waveform RC configuration
    # -nologo  : suppress splash screen
    # &        : run Verdi in background
    echo "CMD: verdi -f ${FILELIST} -ssf ${FSDB} -rc ${RC_FILE} -nologo &"
    verdi -f "${FILELIST}" -ssf "${FSDB}" -rc "${RC_FILE}" -nologo &
    echo "Verdi launched (PID $!)."
}

do_clean() {
    echo "Cleaning generated files ..."
    rm -rf "${SIMV}" "${SIMV}.daidir" csrc \
           "${COMPILE_LOG}" "${SIM_LOG}" "${FSDB}" \
           ucli.key vc_hdrs.h verdi_config_file \
           novas.conf novas.rc novas_dump.log verdiLog \
           AN.DB dump.vcd
    echo "Clean done."
}

# ---------------------------------------------------------------------------
# 5.  Main dispatch
# ---------------------------------------------------------------------------

case "${1:-all}" in
    compile)
        do_compile
        ;;
    sim)
        do_simulate
        ;;
    wave)
        do_wave
        ;;
    clean)
        do_clean
        ;;
    all|"")
        do_compile
        do_simulate
        do_wave
        ;;
    *)
        echo "Usage: $0 [compile|sim|wave|clean|all]"
        exit 1
        ;;
esac
