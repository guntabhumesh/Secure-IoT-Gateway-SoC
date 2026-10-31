#!/bin/bash
# =============================================================================
# run_soc_vips.sh
#
# Automation script to compile and simulate the Secure-IoT-Gateway-SoC with
# active UVM VIPs (UART, SPI, I2C, GPIO) executing the C-Test firmware.
#
# Usage:
#   ./scripts/sim/run_soc_vips.sh fw       # Compile C test firmware to bank hex
#   ./scripts/sim/run_soc_vips.sh compile  # Compile SoC + VIPs with Synopsys VCS
#   ./scripts/sim/run_soc_vips.sh sim      # Run UVM simulation with active VIP checking
#   ./scripts/sim/run_soc_vips.sh wave     # Open Verdi waveform viewer
#   ./scripts/sim/run_soc_vips.sh all      # Run full flow: fw -> compile -> sim (default)
#   ./scripts/sim/run_soc_vips.sh clean    # Clean simulation artifacts
# =============================================================================

set -e

# Tool environment setup
export VCS_HOME="${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}"
export VERDI_HOME="${VERDI_HOME:-/home/student/snps_tools_target/verdi/U-2023.03-SP1}"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}"
export LM_LICENSE_FILE="${LM_LICENSE_FILE:-27021@14.139.1.126}"
export PATH="$VCS_HOME/bin:$VERDI_HOME/bin:/home/student/riscv-toolchain/xpack-riscv-none-elf-gcc-13.2.0-2/bin:/opt/riscv/bin:$PATH"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
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
    echo "  1. Compiling C-Test Firmware (.c -> .hex 4-bank files)"
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
    echo "[INFO] Firmware compiled successfully."
}

do_compile() {
    echo "============================================================"
    echo "  2. Compiling SoC RTL + UVM VIPs with Synopsys VCS"
    echo "============================================================"
    vcs -full64 -sverilog -ntb_opts uvm -timescale=1ns/1ps -debug_access+all -kdb \
        -P $VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab \
           $VERDI_HOME/share/PLI/VCS/LINUX64/pli.a \
        +define+FSDB \
        -f scripts/sim/run_soc_vips.f -l scripts/sim/compile_vips.log \
        -o simv_soc_vips
    echo "[INFO] VCS Compilation completed: ./simv_soc_vips"
}

do_sim() {
    echo "============================================================"
    echo "  3. Running SoC C-Test Simulation with Active VIP Checking"
    echo "============================================================"
    ./simv_soc_vips +UVM_TESTNAME=soc_c_test +hex_file=firmware/soc_testplan.hex -no_save +vcs+lic+wait -l sim_soc_vips.log
    echo "[INFO] Simulation complete. Waveform generated: dump_soc_vips.fsdb"
}

do_wave() {
    echo "============================================================"
    echo "  4. Launching Verdi Waveform Viewer"
    echo "============================================================"
    if [ ! -f "dump_soc_vips.fsdb" ]; then
        echo "[ERROR] dump_soc_vips.fsdb not found. Run simulation first!"
        exit 1
    fi
    if [ -f "tb/soc_testplan.rc" ]; then
        verdi -dbdir simv_soc_vips.daidir -ssf dump_soc_vips.fsdb -sswr tb/soc_testplan.rc &
    else
        verdi -dbdir simv_soc_vips.daidir -ssf dump_soc_vips.fsdb &
    fi
}

do_clean() {
    echo "============================================================"
    echo "  Cleaning VIP build files"
    echo "============================================================"
    rm -rf simv_soc_vips simv_soc_vips.daidir csrc ucli.key vc_hdrs.h compile_vips.log sim_soc_vips.log dump_soc_vips.fsdb novas.* verdiLog
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
