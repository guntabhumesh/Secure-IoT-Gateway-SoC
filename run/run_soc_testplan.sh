#!/bin/bash
# =============================================================================
# run_soc_testplan.sh
#
# Helper script to build the UVM testplan firmware, compile SoC RTL with VCS,
# run simulation, and view waveforms in Verdi.
#
# Usage:
#   ./scripts/sim/run_soc_testplan.sh fw       # Build firmware (.c -> .hex bank files)
#   ./scripts/sim/run_soc_testplan.sh compile  # Compile RTL with VCS + Verdi PLI
#   ./scripts/sim/run_soc_testplan.sh sim      # Run simulation (dumps dump_soc_testplan.fsdb)
#   ./scripts/sim/run_soc_testplan.sh wave     # Open waveforms in Verdi
#   ./scripts/sim/run_soc_testplan.sh all      # fw -> compile -> sim (default)
#   ./scripts/sim/run_soc_testplan.sh clean    # Clean build artifacts
# =============================================================================

set -e

# Tool environment setup
export VCS_HOME="${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}"
export VERDI_HOME="${VERDI_HOME:-/home/student/snps_tools_target/verdi/U-2023.03-SP1}"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}"
export LM_LICENSE_FILE="${LM_LICENSE_FILE:-27021@14.139.1.126}"
export PATH="$VCS_HOME/bin:$VERDI_HOME/bin:/home/student/riscv-toolchain/xpack-riscv-none-elf-gcc-13.2.0-2/bin:/opt/riscv/bin:$PATH"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Detect toolchain prefix
if command -v riscv-none-elf-gcc >/dev/null 2>&1; then
    CC=riscv-none-elf-gcc
    OBJCOPY=riscv-none-elf-objcopy
elif command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
    CC=riscv64-unknown-elf-gcc
    OBJCOPY=riscv64-unknown-elf-objcopy
elif [ -f "/opt/riscv/bin/riscv64-unknown-elf-gcc" ]; then
    CC="/opt/riscv/bin/riscv64-unknown-elf-gcc"
    OBJCOPY="/opt/riscv/bin/riscv64-unknown-elf-objcopy"
else
    echo "ERROR: RISC-V GCC not found!"
    exit 1
fi

do_fw() {
    echo "============================================================"
    echo "  1. Building UVM Test Plan Firmware (.c -> .hex banks)"
    echo "============================================================"
    echo "[INFO] Using GCC: $CC"
    $CC -march=rv32imc_zicsr -mabi=ilp32 -O2 \
        -fno-delete-null-pointer-checks \
        -T firmware/link_iccm.ld -nostdlib -Wl,--gc-sections \
        firmware/startup.S firmware/soc_testplan.c -o firmware/soc_testplan.elf

    python3 -c "
import subprocess, struct

def make_banks(bin_data, out_prefix):
    remainder = len(bin_data) % 16
    if remainder != 0:
        bin_data += b'\x00' * (16 - remainder)
    num_words = len(bin_data) // 4
    words = struct.unpack(f'<{num_words}I', bin_data)
    for bank in range(4):
        bank_words = [words[i] for i in range(bank, len(words), 4)]
        with open(f'{out_prefix}_bank{bank}.hex', 'w') as f:
            for w in bank_words:
                f.write(f'{w:08x}\n')
    return len(words)

# ICCM (Instructions)
subprocess.run(['$OBJCOPY', '-O', 'binary', '--only-section=.text', 'firmware/soc_testplan.elf', 'firmware/soc_testplan_iccm.bin'], check=True)
with open('firmware/soc_testplan_iccm.bin', 'rb') as f:
    w_iccm = make_banks(f.read(), 'firmware/soc_testplan')
print(f'[INFO] ICCM: {w_iccm} words generated across 4 banks.')

# DCCM (Data)
subprocess.run(['$OBJCOPY', '-O', 'binary', '--only-section=.rodata', '--only-section=.data', 'firmware/soc_testplan.elf', 'firmware/soc_testplan_dccm.bin'], check=True)
with open('firmware/soc_testplan_dccm.bin', 'rb') as f:
    w_dccm = make_banks(f.read(), 'firmware/soc_testplan_dccm')
print(f'[INFO] DCCM: {w_dccm} words generated across 4 banks.')

# Monolithic Verilog hex
subprocess.run(['$OBJCOPY', '-O', 'verilog', 'firmware/soc_testplan.elf', 'firmware/soc_testplan.hex'], check=True)
"
    echo "[INFO] Firmware compiled and bank hex files generated successfully."
}

do_compile() {
    echo "============================================================"
    echo "  2. Compiling SoC RTL + Testbench with Synopsys VCS"
    echo "============================================================"
    vcs -full64 -sverilog -ntb_opts uvm -timescale=1ns/1ps -debug_access+all -kdb \
        -P $VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab \
           $VERDI_HOME/share/PLI/VCS/LINUX64/pli.a \
        +define+FSDB \
        -f run/run_soc_testplan.f -l run/compile_testplan.log \
        -o simv_testplan
    echo "[INFO] VCS Compilation completed: ./simv_testplan"
}

do_sim() {
    echo "============================================================"
    echo "  3. Running UVM Test Plan Simulation"
    echo "============================================================"
    ./simv_testplan +hex_file+firmware/soc_testplan.hex -no_save +vcs+lic+wait
    echo "[INFO] Waveform generated: dump_soc_testplan.fsdb"
}

do_wave() {
    echo "============================================================"
    echo "  4. Launching Verdi Waveform Viewer"
    echo "============================================================"
    if [ ! -f "dump_soc_testplan.fsdb" ]; then
        echo "[ERROR] dump_soc_testplan.fsdb not found. Run simulation first!"
        exit 1
    fi
    if [ -f "tb/soc_testplan.rc" ]; then
        verdi -dbdir simv_testplan.daidir -ssf dump_soc_testplan.fsdb -sswr tb/soc_testplan.rc &
    else
        verdi -dbdir simv_testplan.daidir -ssf dump_soc_testplan.fsdb &
    fi
}

do_clean() {
    echo "============================================================"
    echo "  Cleaning build files"
    echo "============================================================"
    rm -rf simv_testplan simv_testplan.daidir csrc ucli.key vc_hdrs.h compile_testplan.log dump_soc_testplan.fsdb novas.* verdiLog
    echo "[INFO] Clean complete."
}

case "${1:-all}" in
    fw)       do_fw ;;
    compile)  do_compile ;;
    sim)      do_sim ;;
    wave)     do_wave ;;
    all|"")   do_fw && do_compile && do_sim ;;
    clean)    do_clean ;;
    *)
        echo "Usage: $0 {fw|compile|sim|wave|all|clean}"
        exit 1
        ;;
esac
