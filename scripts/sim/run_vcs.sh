#!/bin/bash
# run_vcs.sh
# Script to compile and run the SPI and GPIO testbench using Synopsys VCS

# Exit on error
set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ROOT_DIR=$(readlink -f "$SCRIPT_DIR/../..")

echo "Compiling SPI & GPIO Testbench with VCS..."

# Paths
SPI_DIR="$ROOT_DIR/rtl/spi/src"
GPIO_DIR="$ROOT_DIR/rtl/gpio/rtl/verilog"

vcs -sverilog -full64 -debug_access+all \
    +incdir+${SPI_DIR}/include \
    ${SPI_DIR}/include/*.vh \
    ${SPI_DIR}/rtl/*.v \
    ${GPIO_DIR}/*.sv \
    "$ROOT_DIR/rtl/general_timer/lib/rtl/axi4lite_slave_adapter.sv" \
    "$ROOT_DIR/tb/tb_spi_gpio_vcs.sv" \
    -top tb_spi_gpio_vcs

echo "Running Simulation..."
./simv +vcs+lic+wait

echo "Done!"
