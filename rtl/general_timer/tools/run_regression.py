#!/usr/bin/env python3
#-------------------------------------------------------------------------------
# File: run_regression.py
# Description: Centralized regression script for General Timer IP.
#
# How it operates:
# This script executes all available simulation flows (Cocotb, Xilinx, ModelSim, etc.)
# across various configurations and summarizes the results.
#
# Author: Gemini-3 AI
# License: MIT
#-------------------------------------------------------------------------------

import os
import subprocess
import sys
import time
from datetime import datetime
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
        # Environment check and setup.sh path
        if "GEMINI_IP_ROOT" not in os.environ:
            print("[ERROR  ] GEMINI_IP_ROOT is not set. Please source setup.sh")
            return False
            
        gemini_ip_root = os.environ["GEMINI_IP_ROOT"]
        setup_script = os.path.join(gemini_ip_root, "setup.sh")
        
        # Wrap command in bash to source setup.sh
        # bash -c 'source setup_script && exec "$@"' -- cmd args...
        wrapped_command = ["bash", "-c", f"source {setup_script} && exec \"$@\"", "--"] + job.command

        # Run command and capture output
        # Logs are saved in the same directory as the script
        tools_dir = os.path.dirname(os.path.abspath(__file__))
        log_dir = tools_dir
        log_file = os.path.join(log_dir, f"regression_{job.name.lower()}.log")
        
        with open(log_file, "w") as f:
            result = subprocess.run(
                wrapped_command,
                cwd=job.cwd,
                stdout=f,
                stderr=subprocess.STDOUT,
                text=True,
                check=False
            )
        
        duration = time.time() - start_time
        
        if result.returncode == 0:
            print(f"[PASSED ] {job.name} ({duration:.2f}s)")
            return True
        else:
            print(f"[FAILED ] {job.name} ({duration:.2f}s)")
            # Dump last 5 lines for context
            try:
                with open(log_file, "r") as f:
                    lines = f.readlines()
                    print("--- LAST 5 LINES OF LOG ---")
                    for line in lines[-5:]:
                        print(line.strip())
                    print("---------------------------")
            except:
                pass
            return False
            
    except Exception as e:
        print(f"[ERROR  ] {job.name}: {str(e)}")
        return False

def main():
    # Setup Paths
    tools_dir = os.path.dirname(os.path.abspath(__file__))
    ip_root = os.path.dirname(tools_dir)
    sim_dir = os.path.join(ip_root, "sim")
    verif_dir = os.path.join(ip_root, "verif")
    cocotb_dir = os.path.join(verif_dir, "cocotb")

    print("==================================================")
    print(f"General Timer Regression Run: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("==================================================")
    
    # Remove existing report if it exists
    report_path = os.path.join(ip_root, "timer_regression_results.md")
    if os.path.exists(report_path):
        os.remove(report_path)

    jobs = []

    # 1. SystemVerilog Cocotb Tests
    for bus in ["AXI", "APB", "WB"]:
        jobs.append(TestJob(
            name=f"SV_Cocotb_{bus}",
            cwd=cocotb_dir,
            command=["make", "SIM=verilator", f"BUS_TYPE={bus}", "TOPLEVEL_LANG=verilog"],
            description=f"SystemVerilog {bus} Cocotb via Verilator"
        ))

    # 2. VHDL Cocotb Tests
    for bus in ["AXI", "APB", "WB"]:
        jobs.append(TestJob(
            name=f"VHDL_Cocotb_{bus}",
            cwd=cocotb_dir,
            command=["make", "SIM=ghdl", f"BUS_TYPE={bus}", "TOPLEVEL_LANG=vhdl"],
            description=f"VHDL {bus} Cocotb via GHDL"
        ))

    # 3. Native ModelSim Tests
    jobs.append(TestJob(
        name="ModelSim_SV",
        cwd=os.path.join(sim_dir, "modelsim"),
        command=["./run_modelsim.sh"],
        description="ModelSim SystemVerilog Native TB"
    ))
    jobs.append(TestJob(
        name="ModelSim_VHDL",
        cwd=os.path.join(sim_dir, "modelsim"),
        command=["./run_modelsim_vhdl.sh"],
        description="ModelSim VHDL Native TB"
    ))

    # 4. Native Xilinx Tests
    jobs.append(TestJob(
        name="Xilinx_SV",
        cwd=os.path.join(sim_dir, "xilinx"),
        command=["./run_xsim.sh"],
        description="Xilinx xsim SystemVerilog Native TB"
    ))
    jobs.append(TestJob(
        name="Xilinx_VHDL",
        cwd=os.path.join(sim_dir, "xilinx"),
        command=["./run_xsim_vhdl.sh"],
        description="Xilinx xsim VHDL Native TB"
    ))

    # 5. Icarus Verilog
    jobs.append(TestJob(
        name="Icarus_Verilog",
        cwd=os.path.join(sim_dir, "iverilog"),
        command=["./run_iverilog.sh"],
        description="Icarus Verilog Native TB"
    ))

    # 6. GHDL
    jobs.append(TestJob(
        name="GHDL_Native",
        cwd=os.path.join(sim_dir, "ghdl"),
        command=["./run_ghdl.sh"],
        description="GHDL VHDL Native TB"
    ))

    # 7. Linting & CDC
    jobs.append(TestJob(
        name="Linting",
        cwd=tools_dir,
        command=["./run_lint.sh"],
        description="Verilator & GHDL Linting"
    ))
    jobs.append(TestJob(
        name="CDC_Analysis",
        cwd=tools_dir,
        command=["./run_cdc.sh"],
        description="Verilator CDC/Structural Check"
    ))

    # 8. Formal Verification
    formal_dir = os.path.join(verif_dir, "formal")
    for lang in ["sv", "vhdl"]:
        for bus in ["axi", "apb", "wb"]:
            jobs.append(TestJob(
                name=f"Formal_{bus.upper()}_{lang.upper()}",
                cwd=formal_dir,
                command=["./run_formal.sh", bus, lang],
                description=f"Formal Verification ({bus.upper()} {lang.upper()}) via SymbiYosys"
            ))

    # 9. UVM Verification
    uvm_dir = os.path.join(verif_dir, "uvm")
    # Register/Count tests for all configs
    for lang in ["verilog", "vhdl"]:
        for bus in ["axi", "apb", "wb"]:
            for test in ["timer_reg_test", "timer_count_test"]:
                jobs.append(TestJob(
                    name=f"UVM_{lang.upper()}_{bus.upper()}_{test}",
                    cwd=uvm_dir,
                    command=["./run_uvm.sh", bus, lang, test],
                    description=f"UVM {test} ({lang.upper()} {bus.upper()}) via Xilinx xsim"
                ))
    
    # Specialized tests (AXI only for performance/sweep)
    for test in ["timer_pwm_perf_test", "timer_capture_stress_test", "timer_prescaler_sweep_test"]:
        jobs.append(TestJob(
            name=f"UVM_AXI_SV_{test}",
            cwd=uvm_dir,
            command=["./run_uvm.sh", "axi", "verilog", test],
            description=f"Specialized {test} (AXI SV) via Xilinx xsim"
        ))
        
    # Specialized Full Mode Test
    jobs.append(TestJob(
        name="UVM_AXI_SV_timer_full_mode_test",
        cwd=uvm_dir,
        command=["./run_uvm.sh", "axi", "verilog", "timer_full_mode_test"],
        description="Specialized timer_full_mode_test (AXI SV) via Xilinx xsim"
    ))

    # Execute Jobs
    results = []
    for job in jobs:
        passed = run_job(job)
        results.append((job, passed))

    # Print Summary
    print("\n==================================================")
    print("REGRESSION SUMMARY")
    print("==================================================")
    passed_count = sum(1 for _, p in results if p)
    total_count = len(results)
    
    print(f"{'TEST NAME':<25} | {'STATUS':<10} | {'DESCRIPTION'}")
    print("-" * 75)
    for job, passed in results:
        status = "PASS" if passed else "FAIL"
        print(f"{job.name:<25} | {status:<10} | {job.description}")
    
    print("-" * 75)
    print(f"TOTAL: {passed_count}/{total_count} PASSED")
    print("==================================================")

    # Generate Markdown Report
    report_path = os.path.join(ip_root, "timer_regression_results.md")
    with open(report_path, "w") as f:
        f.write("# General Timer Regression Results\n\n")
        f.write(f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write(f"**Overall Status: {'PASSED' if passed_count == total_count else 'FAILED'}**\n")
        f.write(f"**Passed: {passed_count} / {total_count}**\n\n")
        f.write("| Test Name | Status | Description |\n")
        f.write("| :--- | :---: | :--- |\n")
        for job, passed in results:
            status = "✅ PASS" if passed else "❌ FAIL"
            f.write(f"| {job.name} | {status} | {job.description} |\n")

    if passed_count != total_count:
        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()
