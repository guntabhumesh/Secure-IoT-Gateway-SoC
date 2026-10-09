#!/usr/bin/env python3
#-------------------------------------------------------------------------------
# File: run_regression.py
# Description: Centralized regression script for Gemini_IP GPIO.
#
# How it operates:
# This script executes all available simulation flows (Cocotb, Xilinx, ModelSim)
# across various configurations and summarizes the results.
#
# Author: Gemini-3 AI
# License: MIT
#-------------------------------------------------------------------------------

import os
import subprocess
import sys
import time
from dataclasses import dataclass
from typing import List

@dataclass
class TestJob:
    name: str
    cwd: str
    command: List[str]
    description: str

def run_job(job: TestJob) -> bool:
    print(f"[RUNNING] {job.name} - {job.description}")
    start_time = time.time()
    
    try:
        # Run command and capture output
        result = subprocess.run(
            job.command,
            cwd=job.cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )
        duration = time.time() - start_time
        
        if result.returncode == 0:
            print(f"[PASSED ] {job.name} ({duration:.2f}s)")
            return True
        else:
            print(f"[FAILED ] {job.name} ({duration:.2f}s)")
            # Optionally dump some failure output
            print("--- FAILURE OUTPUT ---")
            print("\n".join(result.stdout.splitlines()[-10:]))
            print("----------------------")
            return False
            
    except Exception as e:
        print(f"[ERROR  ] {job.name}: {str(e)}")
        return False

def main():
    root_dir = os.environ.get("GEMINI_IP_ROOT")
    if not root_dir:
        print("Error: GEMINI_IP_ROOT not set. Please source setup.sh")
        sys.exit(1)

    cocotb_dir = os.path.join(root_dir, "IP/interface/GPIO/verif/cocotb")
    xilinx_dir = os.path.join(root_dir, "IP/interface/GPIO/sim/xilinx")
    modelsim_dir = os.path.join(root_dir, "IP/interface/GPIO/sim/modelsim")

    jobs = []

    # 1. SystemVerilog Cocotb Tests
    for bus in ["AXI", "APB", "WB"]:
        for bits in [8, 16, 32]:
            jobs.append(TestJob(
                name=f"SV_{bus}_{bits}",
                cwd=cocotb_dir,
                command=["make", "SIM=verilator", f"BUS_TYPE={bus}", f"NUM_BITS={bits}"],
                description=f"SystemVerilog {bus} {bits}-bit via Verilator"
            ))

    # 2. VHDL Cocotb Tests
    for bus in ["AXI", "APB", "WB"]:
        for bits in [8, 16, 32]:
            jobs.append(TestJob(
                name=f"VHDL_{bus}_{bits}",
                cwd=cocotb_dir,
                command=["make", "SIM=ghdl", "TOPLEVEL_LANG=vhdl", f"BUS_TYPE={bus}", f"NUM_BITS={bits}"],
                description=f"VHDL {bus} {bits}-bit via GHDL"
            ))

    # 3. Native Xilinx Test
    jobs.append(TestJob(
        name="Xilinx_Native",
        cwd=xilinx_dir,
        command=["./run_xsim.sh"],
        description="Xilinx xsim native directed test"
    ))

    # 4. Native ModelSim Test
    jobs.append(TestJob(
        name="ModelSim_Native",
        cwd=modelsim_dir,
        command=["./run_modelsim.sh"],
        description="ModelSim vsim native directed test"
    ))

    # 5. Native Icarus Test
    iverilog_dir = os.path.join(root_dir, "IP/interface/GPIO/sim/iverilog")
    jobs.append(TestJob(
        name="Icarus_Native",
        cwd=iverilog_dir,
        command=["./run_iverilog.sh"],
        description="Icarus iverilog native directed test"
    ))

    # 6. Native GHDL Test
    ghdl_dir = os.path.join(root_dir, "IP/interface/GPIO/sim/ghdl")
    jobs.append(TestJob(
        name="GHDL_Native",
        cwd=ghdl_dir,
        command=["./run_ghdl.sh"],
        description="GHDL native directed test"
    ))

    # 7. UVM Test
    uvm_dir = os.path.join(root_dir, "IP/interface/GPIO/verif/uvm")
    jobs.append(TestJob(
        name="UVM_APB_Test",
        cwd=uvm_dir,
        command=["./run_uvm.sh", "apb"],
        description="UVM APB Verification (Xilinx)"
    ))

    jobs.append(TestJob(
        name="UVM_AXI_Test",
        cwd=uvm_dir,
        command=["./run_uvm.sh", "axi"],
        description="UVM AXI Verification (Xilinx)"
    ))

    jobs.append(TestJob(
        name="UVM_WB_Test",
        cwd=uvm_dir,
        command=["./run_uvm.sh", "wb"],
        description="UVM Wishbone Verification (Xilinx)"
    ))

    jobs.append(TestJob(
        name="UVM_APB_Random_Test",
        cwd=uvm_dir,
        command=["./run_uvm.sh", "apb", "gpio_random_test"],
        description="UVM APB Random Verification"
    ))
    # Override TEST_NAME for random test via environment or arg if script supports it.
    # The script uses BUS_TYPE to set TEST_NAME. We need to update run_uvm.sh or pass arg.

    jobs.append(TestJob(
        name="UVM_AXI_Random_Test",
        cwd=uvm_dir,
        command=["./run_uvm.sh", "axi", "gpio_axi_random_test"],
        description="UVM AXI Random Verification"
    ))

    jobs.append(TestJob(
        name="UVM_WB_Random_Test",
        cwd=uvm_dir,
        command=["./run_uvm.sh", "wb", "gpio_wb_random_test"],
        description="UVM WB Random Verification"
    ))

    # 8. Formal Verification
    formal_dir = os.path.join(root_dir, "IP/interface/GPIO/verif/formal")
    jobs.append(TestJob(
        name="Formal_Verification",
        cwd=formal_dir,
        command=["./run_formal.sh"],
        description="SymbiYosys Formal Verification"
    ))

    # 9. Linting
    lint_dir = os.path.join(root_dir, "IP/interface/GPIO/tools")
    jobs.append(TestJob(
        name="Linting",
        cwd=lint_dir,
        command=["./run_lint.sh"],
        description="SystemVerilog and VHDL linting"
    ))

    # Run Regression
    print("="*80)
    print(f"Starting Gemini_IP Regression at {time.ctime()}")
    print("="*80)
    
    results = []
    for job in jobs:
        passed = run_job(job)
        results.append((job, passed))

    # Summary Report
    print("\n" + "="*80)
    print("REGRESSION SUMMARY")
    print("="*80)
    
    passed_count = sum(1 for _, p in results if p)
    total_count = len(results)
    
    print(f"{'Test Name':<25} | {'Status':<10} | {'Description'}")
    print("-" * 80)
    for job, passed in results:
        status = "PASS" if passed else "FAIL"
        print(f"{job.name:<25} | {status:<10} | {job.description}")
    
    print("-" * 80)
    print(f"TOTAL: {passed_count}/{total_count} PASSED")
    print("="*80)

    # Generate Markdown Report
    # Write to IP/interface/GPIO/gpio_regression_results.md
    # We are in tools/, so report is ../gpio_regression_results.md relative to this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    report_path = os.path.join(script_dir, "../gpio_regression_results.md")
    with open(report_path, "w") as f:
        f.write("# Gemini_IP Regression Results\n\n")
        f.write(f"Generated on: {time.ctime()}\n\n")
        f.write(f"**Overall Status: {'PASSED' if passed_count == total_count else 'FAILED'}**\n")
        f.write(f"**Passed: {passed_count} / {total_count}**\n\n")
        f.write("| Test Name | Status | Description |\n")
        f.write("| :--- | :---: | :--- |\n")
        for job, passed in results:
            status = "✅ PASS" if passed else "❌ FAIL"
            f.write(f"| {job.name} | {status} | {job.description} |\n")

    if passed_count != total_count:
        sys.exit(1)

if __name__ == "__main__":
    main()
