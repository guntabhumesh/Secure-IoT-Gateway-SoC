#-------------------------------------------------------------------------------
# File: test_gpio.py
# Description: Cocotb-based directed tests for Professional-Grade GPIO IP.
#
# How it operates:
# This verification suite uses Cocotb to exercise the GPIO IP across different
# bus interfaces (AXI, APB, WB) and bit widths. It verifies basic I/O,
# atomic bitwise operations, interrupt generation (edge/level), debouncing,
# inversion, and PWM functionality.
#
# Author: Gemini-3 AI
# License: MIT
#-------------------------------------------------------------------------------

import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge, ReadOnly
from cocotb.clock import Clock
import random
import sys
import os

# Add common lib to path using environment variable
if "GEMINI_IP_ROOT" not in os.environ:
    raise EnvironmentError("GEMINI_IP_ROOT is not set. Please source setup.sh")

GEMINI_IP_ROOT = os.environ["GEMINI_IP_ROOT"]
sys.path.append(os.path.join(GEMINI_IP_ROOT, "IP", "common", "lib", "verif", "cocotb"))
from gemini_cocotb_utils import GeminiTester, safe_to_int

# Common Register Addresses
REG_DATA_I   = 0x00
REG_DATA_O   = 0x04
REG_DIR      = 0x08
REG_INT_EN   = 0x0C
REG_INT_TYP  = 0x10
REG_INT_POL  = 0x14
REG_INT_ANY  = 0x18
REG_INT_STS  = 0x1C
REG_SET_O    = 0x20
REG_CLR_O    = 0x24
REG_TGL_O    = 0x28
REG_DEB_TH   = 0x2C
REG_DEB_EN   = 0x30
REG_INV_IN   = 0x34
REG_INV_OUT  = 0x38
REG_OD_EN    = 0x3C
REG_WR_MASK  = 0x40
REG_PU_EN    = 0x44
REG_PD_EN    = 0x48
REG_PWM_EN   = 0x4C
REG_PWM_CFG  = 0x50

def get_pwm_duty_reg(bit_idx):
    return 0x54 + (bit_idx * 4)

class GPIOTester(GeminiTester):
    def __init__(self, dut, bus_type="AXI"):
        super().__init__(dut, bus_type)
        try:
            self.num_bits = int(dut.NUM_BITS.value)
        except:
            # GHDL might not expose generics directly in some modes
            self.num_bits = 32 # Default fallback

    async def reset(self):
        if hasattr(self.dut, "s_axi_aresetn"):
            self.dut.s_axi_aresetn.value = 0
        elif hasattr(self.dut, "presetn"):
            self.dut.presetn.value = 0
        elif hasattr(self.dut, "wb_rst_i"):
            self.dut.wb_rst_i.value = 1
        
        await Timer(100, unit="ns")
        
        if hasattr(self.dut, "s_axi_aresetn"):
            self.dut.s_axi_aresetn.value = 1
        elif hasattr(self.dut, "presetn"):
            self.dut.presetn.value = 1
        elif hasattr(self.dut, "wb_rst_i"):
            self.dut.wb_rst_i.value = 0
        
        await Timer(20, unit="ns")
        clk_signal = "s_axi_aclk" if self.bus_type == "AXI" else ("pclk" if self.bus_type == "APB" else "wb_clk_i")
        await RisingEdge(getattr(self.dut, clk_signal))

@cocotb.test()
async def test_gpio_basic(dut):
    """Test basic R/W and DIR control"""
    tester = GPIOTester(dut, bus_type=cocotb.plusargs.get("BUS_TYPE", "AXI"))
    clk_signal = "s_axi_aclk" if tester.bus_type == "AXI" else ("pclk" if tester.bus_type == "APB" else "wb_clk_i")
    clock = Clock(getattr(dut, clk_signal), 10, unit="ns")
    cocotb.start_soon(clock.start())
    await tester.reset()

    mask = (1 << tester.num_bits) - 1
    await tester.write_reg(REG_DIR, mask)
    val_dir = await tester.read_reg(REG_DIR)
    assert int(val_dir) == mask, f"DIR mismatch: expected {hex(mask)}, got {hex(int(val_dir))}"

    test_data = 0xAAAA5555 & mask
    await tester.write_reg(REG_DATA_O, test_data)
    
    await Timer(150, unit="ns")
    val_o = await tester.read_reg(REG_DATA_O)
    val_i = await tester.read_reg(REG_DATA_I)
    
    tester.log.info(f"DATA_O: {hex(val_o)}, DATA_I: {hex(val_i)}")
    assert int(val_o) == test_data, f"DATA_O mismatch: expected {hex(test_data)}, got {hex(int(val_o))}"
    assert int(val_i) == test_data, f"DATA_I mismatch: expected {hex(test_data)}, got {hex(int(val_i))}"

@cocotb.test()
async def test_atomic_ops(dut):
    """Test Set/Clear/Toggle registers"""
    tester = GPIOTester(dut, bus_type=cocotb.plusargs.get("BUS_TYPE", "AXI"))
    clk_signal = "s_axi_aclk" if tester.bus_type == "AXI" else ("pclk" if tester.bus_type == "APB" else "wb_clk_i")
    clock = Clock(getattr(dut, clk_signal), 10, unit="ns")
    cocotb.start_soon(clock.start())
    await tester.reset()

    await tester.write_reg(REG_DATA_O, 0)
    await tester.write_reg(REG_SET_O, 0x5)
    val = await tester.read_reg(REG_DATA_O)
    assert (val & 0x5) == 0x5, "Set operation failed"

    await tester.write_reg(REG_TGL_O, 0x3)
    val = await tester.read_reg(REG_DATA_O)
    assert (val & 0x7) == 0x6, f"Toggle operation failed, got {hex(val)}"

    await tester.write_reg(REG_CLR_O, 0x4)
    val = await tester.read_reg(REG_DATA_O)
    assert (val & 0x7) == 0x2, "Clear operation failed"

@cocotb.test()
async def test_interrupts(dut):
    """Test Level and Edge Interrupts using loopback"""
    tester = GPIOTester(dut, bus_type=cocotb.plusargs.get("BUS_TYPE", "AXI"))
    clk_signal = "s_axi_aclk" if tester.bus_type == "AXI" else ("pclk" if tester.bus_type == "APB" else "wb_clk_i")
    clock = Clock(getattr(dut, clk_signal), 10, unit="ns")
    cocotb.start_soon(clock.start())
    await tester.reset()

    # Configure Bit 0 as Output for loopback, Level High Sensitive
    await tester.write_reg(REG_DIR, 0x1)
    await tester.write_reg(REG_INT_TYP, 0) # Level
    await tester.write_reg(REG_INT_POL, 1) # High
    await tester.write_reg(REG_INT_EN, 1)

    # Set Data Output High
    await tester.write_reg(REG_DATA_O, 0x1)
    await Timer(150, unit="ns")
    assert safe_to_int(dut.intr) == 1, "Level High interrupt failed to trigger via loopback"

    # Set Data Output Low
    await tester.write_reg(REG_DATA_O, 0x0)
    await Timer(150, unit="ns")
    assert safe_to_int(dut.intr) == 0, "Level High interrupt failed to de-assert via loopback"

    # Edge Interrupts on Bit 1
    await tester.write_reg(REG_DIR, 0x3) # Bit 0 and 1 as output
    await tester.write_reg(REG_INT_EN, 0x2)
    await tester.write_reg(REG_INT_TYP, 0x2) # Edge
    await tester.write_reg(REG_INT_POL, 0x0) # Falling
    
    await tester.write_reg(REG_DATA_O, 0x2) # Bit 1 High
    await Timer(100, unit="ns")
    await tester.write_reg(REG_INT_STS, 0x2) # Clear status
    
    await tester.write_reg(REG_DATA_O, 0x0) # Bit 1 Fall
    await Timer(150, unit="ns")
    
    val = await tester.read_reg(REG_INT_STS)
    assert (val & 0x2), "Falling edge interrupt failed to capture via loopback"
    assert safe_to_int(dut.intr) == 1, "Edge interrupt failed to trigger global intr"

@cocotb.test()
async def test_debouncing(dut):
    """Test Input Debouncing using loopback"""
    tester = GPIOTester(dut, bus_type=cocotb.plusargs.get("BUS_TYPE", "AXI"))
    clk_signal = "s_axi_aclk" if tester.bus_type == "AXI" else ("pclk" if tester.bus_type == "APB" else "wb_clk_i")
    clock = Clock(getattr(dut, clk_signal), 10, unit="ns")
    cocotb.start_soon(clock.start())
    await tester.reset()

    await tester.write_reg(REG_DEB_TH, 10)
    await tester.write_reg(REG_DEB_EN, 0x1)
    await tester.write_reg(REG_DIR, 0x1) # Output for loopback

    tester.log.info("Testing Glitch suppression via loopback")
    await tester.write_reg(REG_DATA_O, 0x1)
    await RisingEdge(getattr(dut, clk_signal))
    await RisingEdge(getattr(dut, clk_signal))
    await tester.write_reg(REG_DATA_O, 0x0)
    await Timer(200, unit="ns")
    val = await tester.read_reg(REG_DATA_I)
    assert (val & 0x1) == 0, "Debouncer failed to filter glitch"

    tester.log.info("Testing Stable signal propagation via loopback")
    await tester.write_reg(REG_DATA_O, 0x1)
    await Timer(300, unit="ns")
    val = await tester.read_reg(REG_DATA_I)
    assert (val & 0x1) == 1, f"Debouncer failed to pass stable signal. DATA_I={hex(val)}"

@cocotb.test()
async def test_inversion(dut):
    """Test Input & Output Inversion using loopback"""
    tester = GPIOTester(dut, bus_type=cocotb.plusargs.get("BUS_TYPE", "AXI"))
    clk_signal = "s_axi_aclk" if tester.bus_type == "AXI" else ("pclk" if tester.bus_type == "APB" else "wb_clk_i")
    clock = Clock(getattr(dut, clk_signal), 10, unit="ns")
    cocotb.start_soon(clock.start())
    await tester.reset()

    # Output Inversion
    await tester.write_reg(REG_DIR, 0x1)
    await tester.write_reg(REG_DATA_O, 0x1)
    await tester.write_reg(REG_INV_OUT, 0x1)
    await Timer(150, unit="ns")
    assert (safe_to_int(dut.io) & 0x1) == 0, "Output inversion failed"

    # Input Inversion
    await tester.write_reg(REG_INV_OUT, 0x0)
    await tester.write_reg(REG_DATA_O, 0x1)
    await tester.write_reg(REG_INV_IN, 0x1)
    await Timer(250, unit="ns")
    val = await tester.read_reg(REG_DATA_I)
    assert (val & 0x1) == 0, f"Input inversion failed. DATA_I={hex(val)}"

@cocotb.test()
async def test_pwm(dut):
    """Test PWM generation"""
    tester = GPIOTester(dut, bus_type=cocotb.plusargs.get("BUS_TYPE", "AXI"))
    clk_signal = "s_axi_aclk" if tester.bus_type == "AXI" else ("pclk" if tester.bus_type == "APB" else "wb_clk_i")
    clock = Clock(getattr(dut, clk_signal), 10, unit="ns")
    cocotb.start_soon(clock.start())
    await tester.reset()

    await tester.write_reg(REG_PWM_CFG, 0x000A0000)
    await tester.write_reg(get_pwm_duty_reg(0), 5)
    await tester.write_reg(REG_PWM_EN, 0x1)
    await tester.write_reg(REG_DIR, 0x1)

    await Timer(200, unit="ns")
    transitions = 0
    last_val = safe_to_int(dut.io) & 0x1
    for _ in range(100):
        await RisingEdge(getattr(dut, clk_signal))
        current_val = safe_to_int(dut.io) & 0x1
        if current_val != last_val:
            transitions += 1
            last_val = current_val
    assert transitions > 5, "PWM signal not toggling"
