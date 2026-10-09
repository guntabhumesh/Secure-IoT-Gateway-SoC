#!/bin/bash
# Description: Merge all Code Coverage databases in coverage_repo

if [ -z "$GEMINI_IP_ROOT" ]; then
    echo "Error: GEMINI_IP_ROOT is not set."
    echo "Please source the project setup script:"
    echo "  source <path_to_gemini_ip>/setup.sh"
    exit 1
fi

# Source Setup
IP_DIR="$GEMINI_IP_ROOT/IP/common/general_timer"

COV_REPO_DIR="$IP_DIR/coverage_repo"
REPORT_DIR="$IP_DIR/joined_code_cov_report"

echo "=================================================="
echo "Merging Code Coverage from $COV_REPO_DIR"
echo "=================================================="

# Restructure coverage_repo to contain xsim.codeCov if not already present
CODE_COV_DIR="$COV_REPO_DIR/xsim.codeCov"
mkdir -p "$CODE_COV_DIR"

echo "Restructuring coverage_repo..."
# Move all simulation coverage directories into xsim.codeCov
# find directories starting with xsim_ or uvm_ in COV_REPO_DIR (but not inside xsim.codeCov)
find "$COV_REPO_DIR" -maxdepth 1 -type d \( -name "xsim_*" -o -name "uvm_*" \) -exec mv {} "$CODE_COV_DIR/" \;

# Iterate over directories in xsim.codeCov
CC_DBS=""
count=0
for d in "$CODE_COV_DIR"/*; do
    if [ -d "$d" ]; then
        db_name=$(basename "$d")
        CC_DBS="$CC_DBS -cc_db $db_name"
        ((count++))
    fi
done

if [ $count -eq 0 ]; then
    echo "No coverage databases found in $CODE_COV_DIR."
    exit 1
fi

echo "Found $count databases."

# Run merge
# Now we can use -cc_dir pointing to COV_REPO_DIR (which contains xsim.codeCov)
# And -cc_db with just the name
cmd="xcrg -merge_cc -cc_dir $COV_REPO_DIR $CC_DBS -cc_report $REPORT_DIR -report_format html"
echo "Executing: $cmd"
eval $cmd

echo "=================================================="
echo "Merge Complete."
echo "Report: $REPORT_DIR/dashboard.html"
echo "=================================================="
