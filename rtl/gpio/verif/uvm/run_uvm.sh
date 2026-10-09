#!/bin/bash
# Description: Run UVM Simulation using Xilinx Vivado

# Ensure environment is set up
if [ -z "$GEMINI_IP_ROOT" ]; then
    echo "Error: GEMINI_IP_ROOT is not set."
    echo "Please source the project setup script:"
    echo "  source <path_to_gemini_ip>/setup.sh"
    exit 1
fi

# Paths
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IP_DIR="$SCRIPT_DIR/../.."
RTL_DIR="$IP_DIR/rtl/verilog"
UVM_DIR="$SCRIPT_DIR"

# Working Directory
mkdir -p work
cd work

# Default
BUS_TYPE="apb"
TEST_NAME="gpio_apb_test"
DEFINES=""

if [ -n "$1" ]; then
    BUS_TYPE=$1
fi

OVERRIDE_TEST=""
if [ -n "$2" ]; then
    OVERRIDE_TEST=$2
fi

if [ "$BUS_TYPE" == "axi" ]; then
    echo "Configuring for AXI..."
    TEST_NAME="gpio_axi_test"
    DEFINES="-d BUS_AXI"
elif [ "$BUS_TYPE" == "wb" ]; then
    echo "Configuring for Wishbone..."
    TEST_NAME="gpio_wb_test"
    DEFINES="-d BUS_WB"
else
    echo "Configuring for APB (Default)..."
fi

if [ -n "$OVERRIDE_TEST" ]; then
    TEST_NAME=$OVERRIDE_TEST
fi

# Clean
rm -rf xsim.dir *.log *.jou *.pb

echo "=================================================="
echo "Running UVM Simulation ($BUS_TYPE)"
echo "=================================================="

echo "--- Compiling RTL ---"
SHARED_RTL_DIR="$IP_DIR/../../common/lib/rtl"
xvlog -sv -d SIMULATION \
    $SHARED_RTL_DIR/axi4lite_slave_adapter.sv \
    $SHARED_RTL_DIR/apb_slave_adapter.sv \
    $SHARED_RTL_DIR/wb_slave_adapter.sv \
    $RTL_DIR/gpio_bit.sv \
    $RTL_DIR/gpio_wrapper.sv \
    $RTL_DIR/gpio_regs.sv \
    $RTL_DIR/gpio_apb.sv \
    $RTL_DIR/gpio_axi.sv \
    $RTL_DIR/gpio_wb.sv

echo "--- Compiling Interface & Agents ---"
SHARED_AGENTS_DIR="$IP_DIR/../../common/lib/verif/uvm/agents"
xvlog -sv -L uvm \
    $SHARED_AGENTS_DIR/apb_agent/apb_if.sv \
    $SHARED_AGENTS_DIR/apb_agent/apb_agent_pkg.sv \
    $SHARED_AGENTS_DIR/axi_agent/axi_if.sv \
    $SHARED_AGENTS_DIR/axi_agent/axi_agent_pkg.sv \
    $SHARED_AGENTS_DIR/wb_agent/wb_if.sv \
    $SHARED_AGENTS_DIR/wb_agent/wb_agent_pkg.sv \
    $UVM_DIR/agents/gpio_agent/gpio_if.sv \
    $UVM_DIR/agents/gpio_agent/gpio_agent_pkg.sv

echo "--- Compiling Env & Tests ---"
xvlog -sv -L uvm \
    $UVM_DIR/uvm_env/gpio_env_pkg.sv \
    $UVM_DIR/tests/test_lib_pkg.sv

echo "--- Compiling Top ---"
xvlog -sv -L uvm $DEFINES \
    $UVM_DIR/tb/tb_top.sv

echo "--- Elaborating ---"
xelab -cc_type sbct -cc_db xsim.covdb -cc_dir xsim.covdb -debug all tb_top -s top_sim -timescale 1ns/1ps -L uvm

echo "--- Simulating ---"
xsim top_sim -runall -testplusarg UVM_TESTNAME=$TEST_NAME -log uvm_sim.log

# Check Result
if grep -q "UVM_ERROR :    0" uvm_sim.log && grep -q "UVM_FATAL :    0" uvm_sim.log; then
    echo "--------------------------"
    echo "UVM SIMULATION PASSED ($BUS_TYPE)"
    echo "--------------------------"
else
    echo "--------------------------"
    echo "UVM SIMULATION FAILED ($BUS_TYPE)"
    echo "--------------------------"
    grep "UVM_ERROR" uvm_sim.log
    grep "UVM_FATAL" uvm_sim.log
    exit 1
fi
