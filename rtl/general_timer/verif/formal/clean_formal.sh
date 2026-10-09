#!/bin/bash
# Description: Cleans up Formal verification artifacts for General Timer IP

if [ -z "$GEMINI_IP_ROOT" ]; then
    echo "Error: GEMINI_IP_ROOT is not set."
    echo "Please source the project setup script:"
    echo "  source <path_to_gemini_ip>/setup.sh"
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo "Cleaning Formal artifacts..."

# Remove SBY directories (axi, apb, wb)
rm -rf "$SCRIPT_DIR/axi"
rm -rf "$SCRIPT_DIR/apb"
rm -rf "$SCRIPT_DIR/wb"

# Remove log files
rm -f "$SCRIPT_DIR"/*.log

echo "Done."
