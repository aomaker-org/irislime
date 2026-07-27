#!/usr/bin/env bash
# PATH: tools/allocate_audit_log.sh
# PURPOSE: Resolves collision-safe audit log paths with read-only collision guards.

set -euo pipefail

PR_DIR="${HOME}/src/irislime/pr-36"
mkdir -p "${PR_DIR}"

TIMESTAMP=$(date +"%y%m%d_%H%M")
COUNTER=10

while true; do
    NNN=$(printf "%03d" "${COUNTER}")
    LOG_FILE="${PR_DIR}/audit_${TIMESTAMP}_${NNN}.log"

    if [ ! -e "${LOG_FILE}" ]; then
        echo "${LOG_FILE}"
        exit 0
    else
        # Force existing collision target read-only to trigger error on write attempts
        chmod 444 "${LOG_FILE}" 2>/dev/null || true
        COUNTER=$((COUNTER + 10))
    fi
done
