#!/bin/bash
# =============================================================================
# run_uart_rw_veer.sh  –  VCS + Verdi run script for UART R/W Verification
#
# Project  : Secure IoT Gateway SoC
# DUT      : soc_top_with_veer  (VeeR EL2 + AXI interconnect + I2C/AES/UART)
# Testbench: tb_uart_rw_veer
# Firmware : uart_rw.hex  (transmit 'A', loopback, verify, send 'P' or 'F')
#
# Usage (run from proj_dir/run/):
#   chmod +x run_uart_rw_veer.sh
#   ./run_uart_rw_veer.sh              # compile → simulate → open Verdi
#   ./run_uart_rw_veer.sh compile      # compile only
#   ./run_uart_rw_veer.sh sim          # simulate only (requires prior compile)
#   ./run_uart_rw_veer.sh wave         # open Verdi on existing FSDB
#   ./run_uart_rw_veer.sh clean        # remove all generated artifacts
#
# Pass criteria:
#   The testbench deserializes UART bytes from uart_tx_o.
#   Expected sequence: 0x41 ('A')  then  0x50 ('P')
#   "SIMULATION PASS" is printed when 'P' is received.
#   "SIMULATION FAIL" is printed when 'F' is received.
#   "SIMULATION TIMEOUT" is printed if no 'P'/'F' within 2 ms of sim time.
#
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# 0.  Tool environment  — adjust paths to match your installation
# ---------------------------------------------------------------------------
export VCS_HOME="${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}"
export VERDI_HOME="${VERDI_HOME:-/home/student/snps_tools_target/verdi/U-2023.03-SP1}"
export PATH="${VCS_HOME}/bin:${VERDI_HOME}/bin:${PATH}"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}"

# VeeR EL2 root — required so el2_veer_wrapper resolves its `include files
export RV_ROOT="$(realpath ../rtl/Cores-VeeR-EL2)"

# ---------------------------------------------------------------------------
# 1.  Names
# ---------------------------------------------------------------------------
FILELIST="run_uart_rw_veer.f"
SIMV="simv_uart_rw"
FSDB="dump_uart_rw.fsdb"
COMPILE_LOG="compile_uart_rw.log"
SIM_LOG="sim_uart_rw.log"
HEX_FILE="../scripts/uart_rw_iccm_words.hex"   # plain 32-bit word hex linked at 0xEE000000

# ---------------------------------------------------------------------------
# 2.  VCS compile flags
# ---------------------------------------------------------------------------
#  -sverilog            : required — VeeR RTL uses SystemVerilog (.sv)
#  -full64              : 64-bit binary (Linux x86_64)
#  -f run_uart_rw_veer.f: the filelist created for this test
#  -o simv_uart_rw      : simulation binary name
#  -debug_acc+all       : full signal access for Verdi post-processing
#  -debug_region+cell   : descend into all hierarchy levels
#  -kdb                 : Verdi Knowledge Database (enables Verdi annotation)
#  -timescale=1ns/1ps   : global timescale (matches TB `timescale)
#  +define+RV_BUILD_AXI4          : force VeeR into AXI4 bus mode
#  +define+RV_BUILD_AXI_NATIVE    : native AXI4 (not AHB wrapper)
#  +define+ICCM_HIER_LOAD         : TB loads uart_rw.hex into ICCM directly
#                                   via hierarchical $readmemh
#  -P novas.tab / pli.a           : Verdi PLI plug-in for $fsdbDumpvars
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
    +define+ICCM_HIER_LOAD
    -P "${VERDI_HOME}/share/PLI/VCS/LINUX64/novas.tab"
    "${VERDI_HOME}/share/PLI/VCS/LINUX64/pli.a"
)

# ---------------------------------------------------------------------------
# 3.  Simulation flags
# ---------------------------------------------------------------------------
#  -l sim_uart_rw.log   : simulation transcript
#  +hex_file+...        : firmware path passed to TB $value$plusargs
#  +fsdbfile+...        : FSDB output file
#  +fsdb+autoflush      : flush FSDB on every $finish (avoids truncated files)
#  +vcs+finish+2000000000: absolute timeout 2 ms in ps (matches TB SIM_TIMEOUT 2_000_000 ns)
# ---------------------------------------------------------------------------
SIM_FLAGS=(
    -l "${SIM_LOG}"
    "+hex_file+${HEX_FILE}"
    "+fsdbfile+${FSDB}"
    +fsdb+autoflush
    +vcs+finish+2000000000
)

# ---------------------------------------------------------------------------
# 4.  Helper functions
# ---------------------------------------------------------------------------

do_compile() {
    echo "============================================================"
    echo " [1/3]  Compiling  soc_top_with_veer + tb_uart_rw_veer ..."
    echo "        Filelist : ${FILELIST}"
    echo "        Output   : ${SIMV}"
    echo "        Log      : ${COMPILE_LOG}"
    echo "============================================================"

    # Check that the required snapshots directory exists
    if [ ! -d "snapshots/default" ]; then
        echo ""
        echo "WARNING: snapshots/default not found."
        echo "  VeeR EL2 requires generated header files (common_defines.vh,"
        echo "  el2_pdef.vh, el2_param.vh) in run/snapshots/default/."
        echo "  Generate them with:"
        echo "    cd \${RV_ROOT} && make -f tools/Makefile snapshot"
        echo "  or copy from an existing VeeR simulation setup."
        echo ""
    fi

    vcs "${VCS_FLAGS[@]}" 2>&1 | tee "${COMPILE_LOG}"
    local rc=${PIPESTATUS[0]}
    if [ ${rc} -ne 0 ]; then
        echo ""
        echo "ERROR: Compile FAILED (exit ${rc}). Check ${COMPILE_LOG}."
        echo ""
        echo "Common fixes:"
        echo "  1. Missing snapshots/default — run: make -f \${RV_ROOT}/tools/Makefile snapshot"
        echo "  2. VCS/Verdi not in PATH    — check VCS_HOME / VERDI_HOME above"
        echo "  3. License error            — check SNPSLMD_LICENSE_FILE"
        exit ${rc}
    fi
    echo ""
    echo "Compile OK → ${SIMV}"
    echo ""
}

do_simulate() {
    if [ ! -x "${SIMV}" ]; then
        echo "ERROR: ${SIMV} not found. Run '${0} compile' first."
        exit 1
    fi
    if [ ! -f "${HEX_FILE}" ]; then
        echo "ERROR: Firmware hex not found: ${HEX_FILE}"
        echo "  Generate it with:  riscv64-unknown-elf-objcopy -O verilog uart_rw.elf uart_rw.hex"
        exit 1
    fi

    # -------------------------------------------------------------------------
    # Generate per-bank interleaved hex files from the flat word hex.
    #
    # VeeR EL2 ICCM bank interleaving (ICCM_BANK_HI=3, ICCM_BANK_INDEX_LO=4):
    #   Word index i:  bank = i & 3,  row = i >> 2
    #   bank0 rows: words[0], words[4],  words[8],  ...
    #   bank1 rows: words[1], words[5],  words[9],  ...
    #   bank2 rows: words[2], words[6],  words[10], ...
    #   bank3 rows: words[3], words[7],  words[11], ...
    # The TB's $readmemh loads each per-bank file into the correct ram_core.
    # -------------------------------------------------------------------------
    HEX_DIR="$(dirname "$(realpath "${HEX_FILE}")")"
    echo "------------------------------------------------------------"
    echo " Generating per-bank ICCM hex files from: ${HEX_FILE}"
    python3 -c "
import sys, os
hex_file = '${HEX_FILE}'
hex_dir  = '${HEX_DIR}'
words = []
with open(hex_file) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('//') and not line.startswith('@'):
            words.append(int(line, 16))
for bank in range(4):
    bank_words = [words[i] for i in range(bank, len(words), 4)]
    fname = os.path.join(hex_dir, 'uart_rw_bank{}.hex'.format(bank))
    with open(fname, 'w') as fout:
        for w in bank_words:
            fout.write('{:08x}\n'.format(w))
    print('  bank{}: {} words -> {}'.format(bank, len(bank_words), fname))
    sys.stdout.flush()
"
    local py_rc=$?
    if [ ${py_rc} -ne 0 ]; then
        echo "ERROR: Failed to generate per-bank hex files (python3 exit ${py_rc})."
        exit ${py_rc}
    fi
    echo " Per-bank hex files generated OK."
    echo "------------------------------------------------------------"

    echo "============================================================"
    echo " [2/3]  Running simulation ..."
    echo "        Firmware : ${HEX_FILE}"
    echo "        FSDB     : ${FSDB}"
    echo "        Log      : ${SIM_LOG}"
    echo "============================================================"

    ./"${SIMV}" "${SIM_FLAGS[@]}"
    local rc=$?

    echo ""
    # Scan log for pass/fail string
    if grep -q "SIMULATION PASS" "${SIM_LOG}" 2>/dev/null; then
        echo "================================================================"
        echo " RESULT: SIMULATION PASS  — uart_rw UART loopback verified OK"
        echo "================================================================"
    elif grep -q "SIMULATION FAIL" "${SIM_LOG}" 2>/dev/null; then
        echo "================================================================"
        echo " RESULT: SIMULATION FAIL  — see ${SIM_LOG} for details"
        echo "================================================================"
        exit 1
    elif grep -q "SIMULATION TIMEOUT" "${SIM_LOG}" 2>/dev/null; then
        echo "================================================================"
        echo " RESULT: SIMULATION TIMEOUT — no UART P/F byte received"
        echo "         Check ICCM load, reset vector, UART baud divisor."
        echo "================================================================"
        exit 1
    else
        echo " RESULT: Simulation completed. Check ${SIM_LOG} for output."
    fi
    echo ""
}

do_wave() {
    if [ ! -f "${FSDB}" ]; then
        echo "ERROR: ${FSDB} not found. Run '${0} sim' first."
        exit 1
    fi
    echo "============================================================"
    echo " [3/3]  Opening Verdi ..."
    echo "        FSDB : ${FSDB}"
    echo "============================================================"
    verdi -f "${FILELIST}"    \
          -ssf "${FSDB}"      \
          +define+RV_BUILD_AXI4 \
          -nologo &
    echo "Verdi launched (PID $!)"
}

do_clean() {
    echo "Cleaning generated files ..."
    rm -rf "${SIMV}" "${SIMV}.daidir"         \
           "${COMPILE_LOG}" "${SIM_LOG}"       \
           "${FSDB}"                           \
           csrc ucli.key vc_hdrs.h             \
           verdi_config_file                   \
           novas.conf novas.rc novas_dump.log  \
           verdiLog AN.DB
    echo "Clean done."
}

# ---------------------------------------------------------------------------
# 5.  Main dispatch
# ---------------------------------------------------------------------------
case "${1:-all}" in
    compile) do_compile  ;;
    sim)     do_simulate ;;
    wave)    do_wave     ;;
    clean)   do_clean    ;;
    all|"")  do_compile; do_simulate; do_wave ;;
    *)
        echo "Usage: $0 [compile|sim|wave|clean|all]"
        echo ""
        echo "  compile  — compile RTL + TB with VCS"
        echo "  sim      — run simulation (loads uart_rw.hex, monitors UART)"
        echo "  wave     — open Verdi on dump_uart_rw.fsdb"
        echo "  clean    — remove all generated artifacts"
        echo "  all      — compile + sim + wave  (default)"
        exit 1
        ;;
esac
