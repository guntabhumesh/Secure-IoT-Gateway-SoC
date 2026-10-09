#!/bin/bash
# Description: Cleans up Cocotb simulation artifacts for General Timer IP

echo "Cleaning Cocotb artifacts..."

# Remove sim_build directories
rm -rf sim_build_*

# Remove results files
rm -f results.xml

# Remove Python cache
rm -rf __pycache__

# Remove GHDL simulation binaries and objects
rm -f timer_axi timer_apb timer_wb
rm -f *.o
rm -f *.vcd

echo "Done."
