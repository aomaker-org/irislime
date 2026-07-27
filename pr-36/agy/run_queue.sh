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
