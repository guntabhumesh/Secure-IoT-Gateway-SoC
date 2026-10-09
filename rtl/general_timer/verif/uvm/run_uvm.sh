#!/bin/bash
# Description: Run UVM Simulation for General Timer IP using Xilinx Vivado

if [ -z "$GEMINI_IP_ROOT" ]; then
    echo "Error: GEMINI_IP_ROOT is not set."
    echo "Please source the project setup script:"
    echo "  source <path_to_gemini_ip>/setup.sh"
    exit 1
fi

# Paths
IP_DIR="$GEMINI_IP_ROOT/IP/common/general_timer"
SV_RTL_DIR="$IP_DIR/rtl/verilog"
VHDL_RTL_DIR="$IP_DIR/rtl/vhdl"
UVM_DIR="$IP_DIR/verif/uvm"

# Defaults
BUS_TYPE="axi"
TEST_NAME="timer_reg_test"
LANG="verilog"

# Parse arguments
if [ -n "$1" ]; then BUS_TYPE=$1; fi
if [ -n "$2" ]; then LANG=$2; fi
if [ -n "$3" ]; then TEST_NAME=$3; fi

# Working Directory
WORK_DIR="work_${BUS_TYPE}_${TEST_NAME}_${LANG}"
mkdir -p $WORK_DIR
cd $WORK_DIR

# Initial Defines
DEFINES=""
TOP="tb_timer"

echo "=================================================="
echo "Running UVM Simulation: $BUS_TYPE ($LANG)"
echo "=================================================="

# Set defines and top based on bus type and language
if [ "$BUS_TYPE" == "axi" ]; then 
    DEFINES="-d BUS_AXI"
elif [ "$BUS_TYPE" == "apb" ]; then 
    DEFINES="-d BUS_APB"
elif [ "$BUS_TYPE" == "wb" ]; then 
    DEFINES="-d BUS_WB"
fi

if [ "$LANG" == "vhdl" ]; then
    TOP="tb_timer_vhdl"
fi

# Clean
rm -rf xsim.dir *.log *.jou *.pb

# Compile RTL
if [ "$LANG" == "verilog" ]; then
    echo "--- Compiling SV RTL ---"
    SHARED_RTL_DIR="$IP_DIR/../../common/lib/rtl"
    xvlog -sv -d SIMULATION \
        $SHARED_RTL_DIR/axi4lite_slave_adapter.sv \
        $SHARED_RTL_DIR/apb_slave_adapter.sv \
        $SHARED_RTL_DIR/wb_slave_adapter.sv \
        $SV_RTL_DIR/timer_core.sv \
        $SV_RTL_DIR/timer_regs.sv \
        $SV_RTL_DIR/timer_apb.sv \
        $SV_RTL_DIR/timer_axi.sv \
        $SV_RTL_DIR/timer_wb.sv
else
    echo "--- Compiling VHDL RTL ---"
    SHARED_RTL_DIR="$IP_DIR/../../common/lib/rtl"
    xvhdl -2008 $SHARED_RTL_DIR/axi4lite_slave_adapter.vhd
    xvhdl -2008 $SHARED_RTL_DIR/apb_slave_adapter.vhd
    xvhdl -2008 $SHARED_RTL_DIR/wb_slave_adapter.vhd
    xvhdl -2008 $VHDL_RTL_DIR/timer_regs.vhd
    xvhdl -2008 $VHDL_RTL_DIR/timer_core.vhd
    xvhdl -2008 $VHDL_RTL_DIR/timer_apb.vhd
    xvhdl -2008 $VHDL_RTL_DIR/timer_axi.vhd
    xvhdl -2008 $VHDL_RTL_DIR/timer_wb.vhd
fi

echo "--- Compiling UVM Components ---"
SHARED_AGENTS_DIR="$IP_DIR/../../common/lib/verif/uvm/agents"
xvlog -sv -L uvm \
    -i $UVM_DIR/seq \
    -i $UVM_DIR/tests \
    -i $UVM_DIR/agents/timer_agent \
    -i $SHARED_AGENTS_DIR/axi_agent \
    -i $SHARED_AGENTS_DIR/apb_agent \
    -i $SHARED_AGENTS_DIR/wb_agent \
    -i $UVM_DIR/uvm_env \
    $SHARED_AGENTS_DIR/apb_agent/apb_if.sv \
    $SHARED_AGENTS_DIR/apb_agent/apb_agent_pkg.sv \
    $SHARED_AGENTS_DIR/axi_agent/axi_if.sv \
    $SHARED_AGENTS_DIR/axi_agent/axi_agent_pkg.sv \
    $SHARED_AGENTS_DIR/wb_agent/wb_if.sv \
    $SHARED_AGENTS_DIR/wb_agent/wb_agent_pkg.sv \
    $UVM_DIR/agents/timer_agent/timer_if.sv \
    $UVM_DIR/agents/timer_agent/timer_agent_pkg.sv \
    $UVM_DIR/uvm_env/timer_env_pkg.sv \
    $UVM_DIR/tests/timer_test_pkg.sv

echo "--- Compiling Top ---"
xvlog -sv -L uvm $DEFINES \
    $UVM_DIR/tb/$TOP.sv

echo "--- Elaborating ---"
xelab -debug all $TOP -s top_sim -timescale 1ns/1ps -L uvm -cc_type bbc

echo "--- Simulating ---"
xsim top_sim -runall -testplusarg UVM_TESTNAME=$TEST_NAME -testplusarg BUS_TYPE=${BUS_TYPE^^} -log uvm_sim.log

# Archive Coverage
COV_REPO_DIR="$IP_DIR/coverage_repo"
mkdir -p $COV_REPO_DIR
if [ -d "xsim.codeCov/top_sim" ]; then
    rm -rf $COV_REPO_DIR/uvm_${TEST_NAME}_${BUS_TYPE}_${LANG}
    cp -r xsim.codeCov/top_sim $COV_REPO_DIR/uvm_${TEST_NAME}_${BUS_TYPE}_${LANG}
fi

# Check Result
if grep -q "UVM_ERROR :    0" uvm_sim.log && grep -q "UVM_FATAL :    0" uvm_sim.log; then
    echo "--------------------------"
    echo "UVM SIMULATION PASSED"
    echo "--------------------------"
else
    echo "--------------------------"
    echo "UVM SIMULATION FAILED"
    echo "--------------------------"
    grep "UVM_ERROR" uvm_sim.log
    grep "UVM_FATAL" uvm_sim.log
    exit 1
fi
