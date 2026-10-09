#!/usr/bin/env python3
import os
import re
import sys

def parse_coverage(report_path):
    if not os.path.exists(report_path):
        print(f"Error: Report file {report_path} not found.")
        sys.exit(1)

    with open(report_path, 'r') as f:
        content = f.read()

    # Regex to find all table data values
    # The structure puts values in the row after headers
    # We find all <td class='dashTable'>VALUE</td> matches
    matches = re.findall(r"<td class='dashTable'>\s*([\d\.]+)\s*</td>", content)
    
    # Based on the known structure: Files, Modules, Instances, Branch, Condition
    # We expect at least 5 values. The last two are Branch and Condition.
    
    if len(matches) >= 2:
        branch_cov = matches[-2]
        cond_cov = matches[-1]
    else:
        print("Warning: Could not isolate coverage scores. Dumping matches:")
        print(matches)
        branch_cov = "0.0"
        cond_cov = "0.0"

    print(f"Global Branch Coverage: {branch_cov}%")
    print(f"Global Condition Coverage: {cond_cov}%")
    
    # Parse modules.html for specific modules
    modules_report_path = report_path.replace("dashboard.html", "modules.html")
    if os.path.exists(modules_report_path):
        with open(modules_report_path, 'r') as f:
            mod_content = f.read()
        
        # Regex to find row with Module Name and then subsequent values
        # Row format: <td>ID</td><td>NAME</td>...<td>Branch</td><td>Cond</td>
        # We look for "timer_core" etc.
        
        targets = ["timer_core", "timer_regs", "timer_axi", "timer_apb", "timer_wb"]
        print("\n--- Module Coverage ---")
        
        for target in targets:
            # Regex:
            # 1. Name cell: ...>target</a></td>
            # 2. Instance count cell: <td...>...</td>
            # 3. Instance list cell: <td...>...</td>
            # 4. Branch Score: <td...>SCORE</td>
            # 5. Cond Score: <td...>SCORE</td>
            
            # We match the name inside an anchor tag
            pattern = r">" + target + r"</a>\s*</td>"
            pattern += r"\s*<td[^>]*>.*?</td>" # Skip Count
            pattern += r"\s*<td[^>]*>.*?</td>" # Skip Instance List
            pattern += r"\s*<td[^>]*>\s*([\d\.]+)\s*</td>" # Branch
            pattern += r"\s*<td[^>]*>\s*([\d\.]+)\s*</td>" # Cond
            
            match = re.search(pattern, mod_content, re.DOTALL)
            if match:
                print(f"{target}: Branch={match.group(1)}% Condition={match.group(2)}%")
            else:
                print(f"{target}: Not Found (Regex match failed)")

    if branch_cov != "N/A":
        return float(branch_cov)
    return 0.0

if __name__ == "__main__":
    if "GEMINI_IP_ROOT" not in os.environ:
        print("Error: GEMINI_IP_ROOT is not set. Please source setup.sh")
        sys.exit(1)
        
    gemini_ip_root = os.environ["GEMINI_IP_ROOT"]
    report_file = os.path.join(gemini_ip_root, "IP/common/general_timer/joined_code_cov_report/dashboard.html")
    parse_coverage(report_file)
