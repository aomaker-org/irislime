#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

# 1. Create TASK_70 payload to iterate through all debug targets
cat << 'TASK70' > pr-36/agy/task70_debug_sweep.sh
#!/usr/bin/env bash
# PATH: pr-36/agy/task70_debug_sweep.sh
# PURPOSE: AGY Task 70 - Sweep across all debug targets (Vulkan, SYCL, OpenVINO, LiteRT)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

echo "================================================================="
echo "[AGY TASK 70] Launching Full Debug Build Sweep"
echo "================================================================="

DEBUG_TARGETS=("build-vulkan" "build-sycl" "build-openvino" "build-litert")

for target in "${DEBUG_TARGETS[@]}"; do
    echo ""
    echo "-----------------------------------------------------------------"
    echo "[AGY TASK 70] Triggering target: ${target}"
    echo "-----------------------------------------------------------------"
    if make "${target}"; then
        echo "[+] Target ${target} compiled successfully."
    else
        echo "[!] Target ${target} failed! Invoking spot-fix context capture..."
        python3 tools/claude_spot_fix.py "logs/builds/"
    fi
done

echo ""
echo "================================================================="
echo "[AGY TASK 70] Full Debug Sweep Completed."
echo "================================================================="
TASK70

chmod +x pr-36/agy/task70_debug_sweep.sh
git add pr-36/agy/task70_debug_sweep.sh

# 2. Update run_queue.sh to point to TASK_70
cat << 'QUEUE' > pr-36/agy/run_queue.sh
#!/usr/bin/env bash
# PATH: pr-36/agy/run_queue.sh
# PURPOSE: Master queue executor for AGY tasks.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

echo "================================================================="
echo "Launching AGY Automated Queue Processor"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "================================================================="

if [ -f "pr-36/agy/task70_debug_sweep.sh" ]; then
    bash pr-36/agy/run_agy_task.sh TASK_70 bash pr-36/agy/task70_debug_sweep.sh
fi

git add pr-36/
echo "[+] AGY Queue Processing Complete."
QUEUE

chmod +x pr-36/agy/run_queue.sh
git add pr-36/agy/run_queue.sh

echo "[+] TASK_70 initialized and queued."
