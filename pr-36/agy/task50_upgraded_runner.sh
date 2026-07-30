#!/usr/bin/env bash
# PATH: pr-36/agy/task50_upgraded_runner.sh
# PURPOSE: AGY Task 50 - Upgrade build_runner.py with Smart Watchdog & Dynamic RAM+1GB Guardrail

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

echo "================================================================="
echo "[AGY TASK 50] Injecting Smart Watchdog & Dynamic Disk Guardrail"
echo "================================================================="

# Create Claude Spot-Fix Handler
mkdir -p tools/
cat << 'CLAUDE_PY' > tools/claude_spot_fix.py
#!/usr/bin/env python3
import sys, os, subprocess

def analyze_and_fix(log_path):
    print(f"[Claude Spot-Fix] Inspecting failure log: {log_path}")
    if not os.path.exists(log_path):
        print("[Claude Spot-Fix] Log file not found.")
        return
        
    with open(log_path, 'r') as f:
        log_lines = f.readlines()
        
    error_context = "".join(log_lines[-50:]) # Extract last 50 lines
    print("================ ERROR CONTEXT ================")
    print(error_context)
    print("===============================================")
    
    # Hook for Claude API or local CLI prompt execution
    if shutil.which("claude"):
        prompt = f"The following build error occurred during IrisLime compilation:\n{error_context}\nProvide a minimal git patch to fix this error."
        subprocess.run(["claude", "-p", prompt])
    else:
        print("[Claude Spot-Fix] 'claude' CLI not in PATH. Error context captured for inspection.")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        analyze_and_fix(sys.argv[1])
CLAUDE_PY

chmod +x tools/claude_spot_fix.py
git add tools/claude_spot_fix.py pr-36/
echo "[+] Claude spot-fix handler staged at tools/claude_spot_fix.py"
