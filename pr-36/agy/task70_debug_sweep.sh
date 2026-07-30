#!/usr/bin/env bash
# PATH: pr-36/agy/task70_debug_sweep.sh
# PURPOSE: AGY Task 70 - Sweep debug targets with live error tailing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

echo "================================================================="
echo "[AGY TASK 70] Launching Full Debug Build Sweep"
echo "================================================================="

# Valid Makefile targets
DEBUG_TARGETS=("build-vulkan" "build-sycl" "build-openvino")

for target in "${DEBUG_TARGETS[@]}"; do
    echo ""
    echo "-----------------------------------------------------------------"
    echo "[AGY TASK 70] Triggering target: ${target}"
    echo "-----------------------------------------------------------------"
    
    # Capture stderr to a target-specific transient log for instant tailing
    ERR_LOG="logs/builds/${target}_last_err.log"
    mkdir -p logs/builds/

    if make "${target}" 2> >(tee "${ERR_LOG}" >&2); then
        echo "[+] Target ${target} compiled successfully."
    else
        echo "[!] Target ${target} failed!"
        echo "=================== ERROR TAILER OUTPUT ==================="
        tail -n 25 "${ERR_LOG}" || true
        echo "==========================================================="
        python3 tools/claude_spot_fix.py "${ERR_LOG}"
    fi
done

echo ""
echo "================================================================="
echo "[AGY TASK 70] Full Debug Sweep Completed."
echo "================================================================="
