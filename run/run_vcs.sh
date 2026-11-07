#!/bin/bash
# run_vcs.sh
# Script to compile and run the SPI and GPIO testbench using Synopsys VCS

# Exit on error
set -e

# Tool environment setup
export VCS_HOME="${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}"
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}"
export LM_LICENSE_FILE="${LM_LICENSE_FILE:-27021@14.139.1.126}"
export PATH="$VCS_HOME/bin:$PATH"

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ROOT_DIR=$(readlink -f "$SCRIPT_DIR/..")

echo "Compiling SPI & GPIO Testbench with VCS..."

# Paths
SPI_DIR="$ROOT_DIR/rtl/spi/src"
GPIO_DIR="$ROOT_DIR/rtl/gpio/rtl/verilog"

vcs -timescale=1ns/1ps -sverilog -full64 -debug_access+all \
    +incdir+${SPI_DIR}/include \
    ${SPI_DIR}/include/*.vh \
    ${SPI_DIR}/rtl/*.v \
    ${GPIO_DIR}/*.sv \
    "$ROOT_DIR/rtl/general_timer/lib/rtl/axi4lite_slave_adapter.sv" \
    "$ROOT_DIR/tb/tb_spi_gpio_vcs.sv" \
    -top tb_spi_gpio_vcs \
    -o simv_spi_gpio

echo "Running Simulation..."
./simv_spi_gpio -no_save +vcs+lic+wait

echo "Done!"
