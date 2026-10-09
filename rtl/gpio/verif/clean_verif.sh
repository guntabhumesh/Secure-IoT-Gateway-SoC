#!/bin/bash
# Clean up verification artifacts

# Ensure environment is set up
if [ -z "$GEMINI_IP_ROOT" ]; then
    echo "Error: GEMINI_IP_ROOT is not set."
    echo "Please source the project setup script:"
    echo "  source <path_to_gemini_ip>/setup.sh"
    exit 1
fi

# Determine script location regarding execution
VERIF_ROOT="$GEMINI_IP_ROOT/IP/interface/GPIO/verif"

echo "Cleaning up verification artifacts in $VERIF_ROOT..."

# Cocotb
rm -rf $VERIF_ROOT/cocotb/sim_build_*
rm -f  $VERIF_ROOT/cocotb/results.xml
rm -rf $VERIF_ROOT/cocotb/__pycache__
rm -f  $VERIF_ROOT/cocotb/*.o

# Formal
rm -rf $VERIF_ROOT/formal/axi
rm -rf $VERIF_ROOT/formal/apb
rm -rf $VERIF_ROOT/formal/wb

# UVM
rm -rf $VERIF_ROOT/uvm/work
rm -f  $VERIF_ROOT/uvm/xcrg.log
rm -f  $VERIF_ROOT/uvm/*.jou
rm -f  $VERIF_ROOT/uvm/*.pb
rm -f  $VERIF_ROOT/uvm/*.log
rm -rf $VERIF_ROOT/uvm/xsim.dir
rm -rf $VERIF_ROOT/uvm/xsim.covdb

echo "Cleanup complete."
