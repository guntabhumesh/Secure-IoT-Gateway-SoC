#-------------------------------------------------------------------------------
# File: Makefile
# Description: Cocotb simulation Makefile for GPIO IP.
#
# How it operates:
# This Makefile manages the compilation and execution of Cocotb tests.
# It supports Verilator (SV) and GHDL (VHDL) simulators. User can select
# BUS_TYPE (AXI/APB/WB) and TOPLEVEL_LANG (verilog/vhdl).
#
# Usage: make BUS_TYPE=AXI SIM=verilator
# For VHDL: make BUS_TYPE=AXI SIM=ghdl TOPLEVEL_LANG=vhdl
#
# Author: Gemini-3 AI
# License: MIT
#-------------------------------------------------------------------------------

SIM ?= verilator
TOPLEVEL_LANG ?= verilog
BUS_TYPE ?= AXI
NUM_BITS ?= 32

ifndef GEMINI_IP_ROOT
$(error GEMINI_IP_ROOT is not set. Please source setup.sh)
endif

IP_ROOT = $(GEMINI_IP_ROOT)/IP/interface/GPIO
SHARED_RTL_DIR = $(GEMINI_IP_ROOT)/IP/common/lib/rtl

ifeq ($(TOPLEVEL_LANG),verilog)
    ifeq ($(BUS_TYPE),AXI)
        VERILOG_SOURCES = $(SHARED_RTL_DIR)/axi4lite_slave_adapter.sv \
                          $(IP_ROOT)/rtl/verilog/gpio_axi.sv \
                          $(IP_ROOT)/rtl/verilog/gpio_regs.sv \
                          $(IP_ROOT)/rtl/verilog/gpio_wrapper.sv \
                          $(IP_ROOT)/rtl/verilog/gpio_bit.sv
        TOPLEVEL = gpio_axi
    else ifeq ($(BUS_TYPE),APB)
        VERILOG_SOURCES = $(SHARED_RTL_DIR)/apb_slave_adapter.sv \
                          $(IP_ROOT)/rtl/verilog/gpio_apb.sv \
                          $(IP_ROOT)/rtl/verilog/gpio_regs.sv \
                          $(IP_ROOT)/rtl/verilog/gpio_wrapper.sv \
                          $(IP_ROOT)/rtl/verilog/gpio_bit.sv
        TOPLEVEL = gpio_apb
    else ifeq ($(BUS_TYPE),WB)
        VERILOG_SOURCES = $(SHARED_RTL_DIR)/wb_slave_adapter.sv \
                          $(IP_ROOT)/rtl/verilog/gpio_wb.sv \
                          $(IP_ROOT)/rtl/verilog/gpio_regs.sv \
                          $(IP_ROOT)/rtl/verilog/gpio_wrapper.sv \
                          $(IP_ROOT)/rtl/verilog/gpio_bit.sv
        TOPLEVEL = gpio_wb
    endif
else
    # VHDL Path
    VHDL_SOURCES = $(IP_ROOT)/rtl/vhdl/gpio_regs.vhd \
                   $(IP_ROOT)/rtl/vhdl/gpio_bit.vhd \
                   $(IP_ROOT)/rtl/vhdl/gpio_wrapper.vhd
    ifeq ($(BUS_TYPE),AXI)
        VHDL_SOURCES += $(SHARED_RTL_DIR)/axi4lite_slave_adapter.vhd \
                        $(IP_ROOT)/rtl/vhdl/gpio_axi.vhd
        TOPLEVEL = gpio_axi
    else ifeq ($(BUS_TYPE),APB)
        VHDL_SOURCES += $(SHARED_RTL_DIR)/apb_slave_adapter.vhd \
                        $(IP_ROOT)/rtl/vhdl/gpio_apb.vhd
        TOPLEVEL = gpio_apb
    else ifeq ($(BUS_TYPE),WB)
        VHDL_SOURCES += $(SHARED_RTL_DIR)/wb_slave_adapter.vhd \
                        $(IP_ROOT)/rtl/vhdl/gpio_wb.vhd
        TOPLEVEL = gpio_wb
    endif
    
    ifeq ($(SIM),ghdl)
        EXTRA_ARGS += --std=08
    endif
endif

MODULE = test_gpio

# Cocotb 2.x uses PLUSARGS for command line arguments
PLUSARGS += +BUS_TYPE=$(BUS_TYPE)

# Simulation-specific generics/parameters
ifeq ($(TOPLEVEL_LANG),verilog)
    COMPILE_ARGS += -GNUM_BITS=$(NUM_BITS) +incdir+$(SHARED_RTL_DIR)/../verif
else
    # GHDL generic setting
    SIM_ARGS += -gNUM_BITS=$(NUM_BITS)
endif

SIM_BUILD = sim_build_$(TOPLEVEL_LANG)_$(BUS_TYPE)_$(NUM_BITS)
include $(shell cocotb-config --makefiles)/Makefile.sim
