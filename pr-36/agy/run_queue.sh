#!/usr/bin/env bash
# PATH: pr-36/agy/run_queue.sh
# PURPOSE: Master queue executor for AGY tasks.
# RULE:    NEVER PIPE TO NULL. ALL STREAMS VISIBLE AND LOGGED.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

echo "================================================================="
echo "Launching AGY Automated Queue Processor"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "================================================================="

# Execute TASK_20 if task script exists
if [ -f "pr-36/agy/task20_litert_cache.sh" ]; then
    bash pr-36/agy/run_agy_task.sh TASK_20 bash pr-36/agy/task20_litert_cache.sh
fi

# Execute TASK_30 if task script exists
if [ -f "pr-36/agy/task30_submodules_all.sh" ]; then
    bash pr-36/agy/run_agy_task.sh TASK_30 bash pr-36/agy/task30_submodules_all.sh
fi

# Execute TASK_40 if task script exists
if [ -f "pr-36/agy/task40_verify_build.sh" ]; then
    bash pr-36/agy/run_agy_task.sh TASK_40 bash pr-36/agy/task40_verify_build.sh
fi

git add pr-36/
echo "[+] AGY Queue Processing Complete."
