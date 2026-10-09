#!/bin/bash
# Description: Run CDC and structural linting using Verilator

if [ -z "$GEMINI_IP_ROOT" ]; then
    echo "Error: GEMINI_IP_ROOT is not set."
    echo "Please source the project setup script:"
    echo "  source <path_to_gemini_ip>/setup.sh"
    exit 1
fi

# Paths
IP_DIR="$GEMINI_IP_ROOT/IP/common/general_timer"
SV_RTL_DIR="$IP_DIR/rtl/verilog"

echo "=================================================="
echo "Running CDC and structural linting with Verilator"
echo "=================================================="

# Run Verilator Lint
SHARED_RTL_DIR="$GEMINI_IP_ROOT/IP/common/lib/rtl"
SHARED_VERIF_DIR="$GEMINI_IP_ROOT/IP/common/lib/verif"
verilator --lint-only -Wall -Wno-DECLFILENAME \
    -I$SV_RTL_DIR -I$SHARED_RTL_DIR -I$SHARED_VERIF_DIR \
    $SHARED_RTL_DIR/axi4lite_slave_adapter.sv \
    $SHARED_RTL_DIR/apb_slave_adapter.sv \
    $SHARED_RTL_DIR/wb_slave_adapter.sv \
    $SV_RTL_DIR/timer_core.sv \
    $SV_RTL_DIR/timer_regs.sv \
    $SV_RTL_DIR/timer_apb.sv \
    $SV_RTL_DIR/timer_axi.sv \
    $SV_RTL_DIR/timer_wb.sv \
    --top-module timer_axi

if [ $? -eq 0 ]; then
    echo "--------------------------"
    echo "VERILATOR LINT PASSED"
    echo "--------------------------"
else
    echo "--------------------------"
    echo "VERILATOR LINT FAILED"
    echo "--------------------------"
    exit 1
fi
