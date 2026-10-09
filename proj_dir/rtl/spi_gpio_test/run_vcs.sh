#!/bin/bash
# run_vcs.sh
# Script to compile and run the SPI and GPIO testbench using Synopsys VCS

# Exit on error
set -e

echo "Compiling SPI & GPIO Testbench with VCS..."

# Paths
SPI_DIR="../axi-lite_spi-ipcore-develop/src"
GPIO_DIR="../gpio/src"

vcs -sverilog -full64 -debug_access+all \
    +incdir+${SPI_DIR}/include \
    ${SPI_DIR}/include/*.vh \
    ${SPI_DIR}/rtl/*.v \
    tb_spi_gpio_vcs.sv \
    -top tb_spi_gpio_vcs

# Note: The GPIO files are NOT included in the compile list above by default 
# because they rely on missing PULP platform dependencies (register_interface, 
# common_cells, axi). Once those are fetched, you can add them below like this:
#   +incdir+../common_cells/include \
#   ../common_cells/src/*.sv \
#   ${GPIO_DIR}/*.sv \

echo "Running Simulation..."
./simv +vcs+lic+wait

echo "Done!"
