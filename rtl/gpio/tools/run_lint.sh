#!/bin/bash
#-------------------------------------------------------------------------------
# File: run_lint.sh
# Description: Linting script for GPIO IP.
#
# How it operates:
# This script uses Verilator for SystemVerilog linting and GHDL for VHDL
# syntax/semantic checking.
#
# Author: Gemini-3 AI
# License: MIT
#-------------------------------------------------------------------------------

set -e

# Ensure environment is set up
if [ -z "$GEMINI_IP_ROOT" ]; then
    echo "Error: GEMINI_IP_ROOT is not set."
    echo "Please source the project setup script:"
    echo "  source <path_to_gemini_ip>/setup.sh"
    exit 1
fi

# Project Paths
SCRIPT_DIR=$(dirname "$0")
IP_DIR="$SCRIPT_DIR/.."
RTL_DIR_SV="$IP_DIR/rtl/verilog"
RTL_DIR_VHDL="$IP_DIR/rtl/vhdl"
SHARED_RTL="$IP_DIR/../../common/lib/rtl"

echo "--- Linting SystemVerilog (Verilator) ---"
# Lint all source files
for file in $RTL_DIR_SV/*.sv; do
    echo "Linting $file..."
    verilator --lint-only -Wall -I$RTL_DIR_SV -I$SHARED_RTL $file
done

echo "--- Checking VHDL (GHDL) ---"
mkdir -p lint_vhdl
# Analyze shared adapters first
for file in $SHARED_RTL/axi4lite_slave_adapter.vhd $SHARED_RTL/apb_slave_adapter.vhd $SHARED_RTL/wb_slave_adapter.vhd; do
    echo "Checking $file..."
    ghdl -a --std=08 --workdir=lint_vhdl $file
done

# Analyze in dependency order
for file in $RTL_DIR_VHDL/gpio_regs.vhd $RTL_DIR_VHDL/gpio_bit.vhd $RTL_DIR_VHDL/gpio_wrapper.vhd \
            $RTL_DIR_VHDL/gpio_axi.vhd $RTL_DIR_VHDL/gpio_apb.vhd $RTL_DIR_VHDL/gpio_wb.vhd; do
    echo "Checking $file..."
    ghdl -a --std=08 --workdir=lint_vhdl $file
done
rm -rf lint_vhdl

echo "--------------------------"
echo "LINTING PASSED"
echo "--------------------------"
