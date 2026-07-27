#!/usr/bin/env bash
# PATH: pr-36/pr-36-review.sh
# PURPOSE: Executes static path leak audit for PR #36 and locks output.

set -euo pipefail

# 1. Dynamically resolve script location and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 2. Target output directory inside repo root
PR_DIR="${PROJECT_ROOT}/pr-36"
mkdir -p "${PR_DIR}"

# 3. Resolve unique log file path
TIMESTAMP=$(date +"%y%m%d_%H%M")
COUNTER=10

while true; do
    NNN=$(printf "%03d" "${COUNTER}")
    LOGFILE="${PR_DIR}/audit_${TIMESTAMP}_${NNN}.log"

    if [ ! -e "${LOGFILE}" ]; then
        break
    fi
    # Mark existing collisions read-only to prevent overwrite
    chmod 444 "${LOGFILE}" 2>/dev/null || true
    COUNTER=$((COUNTER + 10))
done

echo "[+] Writing PR #36 audit log to: ${LOGFILE}"

# 4. Execute audit scans from PROJECT_ROOT, explicitly excluding .git and pr-36
cd "${PROJECT_ROOT}"

{
    echo "================================================================="
    echo "PR #36 Static Path Audit Log"
    echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "Root Path: ${PROJECT_ROOT}"
    echo "================================================================="
    echo ""
    echo "--- 1. Search: irislime ---"
    grep -rn "irislime" . --exclude-dir=.git --exclude-dir=pr-36 || true
    echo ""
    echo "--- 2. Search: ~/src ---"
    grep -rn "~/src" . --exclude-dir=.git --exclude-dir=pr-36 || true
    echo ""
    echo "--- 3. Search: /home/ ---"
    grep -rn "/home/" . --exclude-dir=.git --exclude-dir=pr-36 || true
    echo ""
    echo "--- 4. Search: PROJECT_ROOT ---"
    grep -rn "PROJECT_ROOT" . --exclude-dir=.git --exclude-dir=pr-36 || true
    echo ""
    echo "================================================================="
    echo "End of Audit Log"
    echo "================================================================="
} >> "${LOGFILE}"

# 5. Lock log file as read-only
chmod 444 "${LOGFILE}"
echo "[+] Log created and locked (chmod 444): ${LOGFILE}"

# End of file: pr-36/pr-36-review.sh
