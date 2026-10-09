#!/bin/bash
# Description: Run Formal Verification (SymbiYosys) for General Timer IP

if [ -z "$GEMINI_IP_ROOT" ]; then
    echo "Error: GEMINI_IP_ROOT is not set."
    echo "Please source the project setup script:"
    echo "  source <path_to_gemini_ip>/setup.sh"
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

echo "=================================================="
echo "Running Formal Verification: General Timer"
echo "=================================================="

FAILED=0

# Usage: ./run_formal.sh [bus] [lang (sv|vhdl)]

BUS=${1:-all}
LANG=${2:-sv}

run_sby() {
    BUS_TYPE=$1
    LANGUAGE=$2
    if [ "$LANGUAGE" == "vhdl" ]; then
        TASK="${BUS_TYPE}_vhdl"
    else
        TASK="$BUS_TYPE"
    fi
    
    echo "--- Running $TASK ---"
    sby -f $TASK.sby
    if [ $? -eq 0 ]; then
        echo "PASS: $TASK"
    else
        echo "FAIL: $TASK"
        FAILED=1
    fi
}

if [ "$BUS" == "all" ]; then
    for b in axi apb wb; do
        run_sby $b $LANG
    done
else
    run_sby $BUS $LANG
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
