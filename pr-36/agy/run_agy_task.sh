#!/usr/bin/env bash
# PATH: pr-36/agy/run_agy_task.sh
# PURPOSE: Generic AGY task execution wrapper with full stream visibility.
# RULE:    NEVER PIPE TO NULL. ALL STREAMS VISIBLE AND LOGGED.

set -euo pipefail

TASK_ID="${1:-TASK_GENERIC}"
shift 1 2>/dev/null || true

# Anchor dynamically: SCRIPT_DIR is pr-36/agy -> PROJECT_ROOT is two levels up
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

AGY_LOG_DIR="${SCRIPT_DIR}/logs"
mkdir -p "${AGY_LOG_DIR}"

TIMESTAMP=$(date +"%y%m%d_%H%M")
COUNTER=10

while true; do
    NNN=$(printf "%03d" "${COUNTER}")
    LOGFILE="${AGY_LOG_DIR}/agy_${TASK_ID}_${TIMESTAMP}_${NNN}.log"
    if [ ! -e "${LOGFILE}" ]; then break; fi
    chmod 444 "${LOGFILE}" 2>/dev/null || true
    COUNTER=$((COUNTER + 10))
done

cd "${PROJECT_ROOT}"

{
    echo "--- BEGIN AGY TASK: ${TASK_ID} | Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ") ---"
    echo "Root Path: ${PROJECT_ROOT}"
    echo "Command Executed: $@"
    echo "================================================================="
    echo ""

    if [ $# -gt 0 ]; then
        "$@"
    else
        echo "[!] Warning: No execution command passed to run_agy_task.sh."
    fi

    echo ""
    echo "================================================================="
    echo "Git Delta Post-Task:"
    git status --short
    echo "================================================================="
    echo "--- END AGY TASK: ${TASK_ID} ---"
} 2>&1 | tee "${LOGFILE}"

# Lock log file read-only and self-stage review workspace
chmod 444 "${LOGFILE}"
git add pr-36/

REL_LOGFILE="pr-36/agy/logs/$(basename "${LOGFILE}")"
echo ""
echo "[+] AGY Task ${TASK_ID} execution complete."
echo "[+] Log locked & staged at: ${REL_LOGFILE}"

# End of file: pr-36/agy/run_agy_task.sh
