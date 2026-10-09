#!/bin/bash
# Description: Run Formal Verification (SymbiYosys)

# Ensure environment is set up
if [ -z "$GEMINI_IP_ROOT" ]; then
    echo "Error: GEMINI_IP_ROOT is not set."
    echo "Please source the project setup script:"
    echo "  source <path_to_gemini_ip>/setup.sh"
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

echo "=================================================="
echo "Running Formal Verification"
echo "=================================================="

FAILED=0

run_sby() {
    TASK=$1
    echo "--- Running $TASK ---"
    sby -f $TASK.sby
    if [ $? -eq 0 ]; then
        echo "PASS: $TASK"
    else
        echo "FAIL: $TASK"
        FAILED=1
    fi
}

if [ -n "$1" ]; then
    run_sby $1
else
    run_sby apb
    run_sby wb
    run_sby axi
fi

if [ $FAILED -eq 1 ]; then
    echo "--------------------------"
    echo "FORMAL VERIFICATION FAILED"
    echo "--------------------------"
    exit 1
else
    echo "--------------------------"
    echo "FORMAL VERIFICATION PASSED"
    echo "--------------------------"
    exit 0
fi
