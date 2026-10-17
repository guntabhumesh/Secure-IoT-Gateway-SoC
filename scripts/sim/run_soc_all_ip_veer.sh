#!/bin/bash
# =============================================================================
# run_soc_all_ip_veer.sh
#
# Helper script to build firmware, compile SoC with VCS, run simulation,
# and view waveforms in Verdi.
#
# Usage:
#   ./scripts/sim/run_soc_all_ip_veer.sh fw       # Build firmware + hex banks
#   ./scripts/sim/run_soc_all_ip_veer.sh compile  # Compile RTL with VCS + Verdi PLI
#   ./scripts/sim/run_soc_all_ip_veer.sh sim      # Run simulation (dumps dump_all_ip.fsdb)
#   ./scripts/sim/run_soc_all_ip_veer.sh wave     # Open waveforms in Verdi
#   ./scripts/sim/run_soc_all_ip_veer.sh all      # fw -> compile -> sim (default)
#   ./scripts/sim/run_soc_all_ip_veer.sh clean    # Clean build artifacts
# =============================================================================

set -e

# Tool environment setup
export VCS_HOME="${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}"
export VERDI_HOME="${VERDI_HOME:-/home/student/snps_tools_target/verdi/U-2023.03-SP1}"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}"
export LM_LICENSE_FILE="${LM_LICENSE_FILE:-27021@14.139.1.126}"
export PATH="$VCS_HOME/bin:$VERDI_HOME/bin:/opt/riscv/bin:$PATH"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

do_fw() {
    echo "============================================================"
    echo "  1. Building Firmware (.elf -> .hex bank files)"
    echo "============================================================"
    /opt/riscv/bin/riscv64-unknown-elf-gcc -march=rv32imc_zicsr -mabi=ilp32 -O2 \
        -fno-delete-null-pointer-checks \
        -T firmware/link_iccm.ld -nostdlib -Wl,--gc-sections \
        firmware/startup.S firmware/soc_all_ip_test.c -o firmware/soc_all_ip_test.elf

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

subprocess.run(['/opt/riscv/bin/riscv64-unknown-elf-objcopy', '-O', 'binary', '--only-section=.text', 'firmware/soc_all_ip_test.elf', 'firmware/iccm.bin'], check=True)
with open('firmware/iccm.bin', 'rb') as f:
    make_banks(f.read(), 'firmware/soc_all_ip_test')

subprocess.run(['/opt/riscv/bin/riscv64-unknown-elf-objcopy', '-O', 'binary', '--only-section=.rodata', '--only-section=.data', 'firmware/soc_all_ip_test.elf', 'firmware/dccm.bin'], check=True)
with open('firmware/dccm.bin', 'rb') as f:
    make_banks(f.read(), 'firmware/soc_all_ip_test_dccm')
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
        -f scripts/sim/run_soc_all_ip_veer.f -l scripts/sim/compile.log
    echo "[INFO] VCS Compilation completed: ./simv (Verdi FSDB dumping enabled)"
}

do_sim() {
    echo "============================================================"
    echo "  3. Running Simulation"
    echo "============================================================"
    ./simv +hex_file+firmware/soc_all_ip_test.hex
    echo "[INFO] Waveform generated: dump_all_ip.fsdb"
}

do_wave() {
    echo "============================================================"
    echo "  4. Launching Verdi Waveform Viewer"
    echo "============================================================"
    if [ ! -f "dump_all_ip.fsdb" ]; then
        echo "[ERROR] dump_all_ip.fsdb not found. Run simulation first!"
        exit 1
    fi
    verdi -dbdir simv.daidir -ssf dump_all_ip.fsdb &
}

do_clean() {
    echo "============================================================"
    echo "  Cleaning build files"
    echo "============================================================"
    rm -rf simv simv.daidir csrc ucli.key vc_hdrs.h *.log dump_all_ip.fsdb novas.* verdiLog
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
