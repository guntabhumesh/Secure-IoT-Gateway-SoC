# Description: Run Coverage flow (One compile, multiple tests, merge)

if [ -z "$GEMINI_IP_ROOT" ]; then
    echo "Error: GEMINI_IP_ROOT is not set."
    echo "Please source the project setup script:"
    echo "  source <path_to_gemini_ip>/setup.sh"
    exit 1
fi

# 1. Compile, Elab, and Run First Test
# This establishes the snapshot and runs the first test.
./run_uvm.sh axi verilog timer_count_test

# 2. Run other tests using the SAME snapshot
# Move into work dir where the snapshot exists
cd work_axi_timer_count_test_verilog

# Rename first test coverage
if [ -d "xsim.codeCov/top_sim" ]; then
    rm -rf xsim.codeCov/timer_count_test_axi_verilog
    mv xsim.codeCov/top_sim xsim.codeCov/timer_count_test_axi_verilog
fi

echo "--------------------------------------------------"
echo "Running Additional Tests for Coverage..."
echo "--------------------------------------------------"

for TEST in timer_pwm_perf_test timer_capture_stress_test timer_prescaler_sweep_test; do
    echo "--- Running $TEST ---"
    # Run simulation
    # Ensure clean state for default coverage export
    rm -rf xsim.codeCov/top_sim

    # Run simulation (defaults to xsim.codeCov/top_sim)
    xsim top_sim -runall -testplusarg UVM_TESTNAME=$TEST -testplusarg BUS_TYPE=AXI -log uvm_sim_$TEST.log
    
    ls -R xsim.codeCov

    # Rename code coverage DB to preserve it
    # Default location: xsim.codeCov/top_sim
    # Target location: xsim.codeCov/${TEST}_axi_verilog
    if [ -d "xsim.codeCov/top_sim" ]; then
        rm -rf xsim.codeCov/${TEST}_axi_verilog
        mv xsim.codeCov/top_sim xsim.codeCov/${TEST}_axi_verilog
    else
         echo "ERROR: xsim.codeCov/top_sim not found for test $TEST"
    fi
done

# 3. Merge Coverage
echo "--------------------------------------------------"
echo "Merging Code Coverage..."
echo "--------------------------------------------------"

# Note: The first test (timer_count_test) run by run_uvm.sh also saved to xsim.codeCov/top_sim
# We should have renamed it too. 
# But run_uvm.sh was unmodified to rename.
# Let's fix the first test handling.

xcrg -merge_cc -cc_dir ./xsim.codeCov \
    -cc_db timer_count_test_axi_verilog \
    -cc_db timer_pwm_perf_test_axi_verilog \
    -cc_db timer_capture_stress_test_axi_verilog \
    -cc_db timer_prescaler_sweep_test_axi_verilog \
    -cc_report code_cov_report

echo "--------------------------------------------------"
echo "Done. Report in work/code_cov_report/index.html"
echo "Text summary:"
grep -r "Score" code_cov_report
echo "--------------------------------------------------"
