#!/usr/bin/env bash
# PATH: pr-36/watch_active_log.sh
# PURPOSE: Low-impact, low-CPU active log monitor with dual timestamps for IrisLime builds.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

START_TIME=$(date +%s)
CURRENT_LOG=""
LAST_MOD=0

format_elapsed() {
    local now=$(date +%s)
    local diff=$((now - START_TIME))
    local hours=$((diff / 3600))
    local mins=$(((diff % 3600) / 60))
    local secs=$((diff % 60))
    printf "+%02d:%02d:%02d" "${hours}" "${mins}" "${secs}"
}

iso_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

get_newest_log() {
    # Find newest .log file across build/ and logs/ with minimal subshells
    find build/ logs/ -type f -name "*.log" -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2-
}

echo "================================================================="
echo "[Watchdog] Low-Impact Active Log Tailer Started"
echo "Timestamp: $(iso_timestamp) | Elapsed: $(format_elapsed)"
echo "================================================================="

while true; do
    NEWEST_LOG=$(get_newest_log)

    if [ -z "${NEWEST_LOG}" ]; then
        echo "[$(format_elapsed) | $(iso_timestamp)] [Watchdog] Waiting for build logs to be created..."
        sleep 5
        continue
    fi

    # If log target changed, announce and switch streams
    if [ "${NEWEST_LOG}" != "${CURRENT_LOG}" ]; then
        CURRENT_LOG="${NEWEST_LOG}"
        echo ""
        echo "-----------------------------------------------------------------"
        echo "[$(format_elapsed) | $(iso_timestamp)] [Watchdog] Tracking active log target:"
        echo " -> ${CURRENT_LOG}"
        echo "-----------------------------------------------------------------"
        # Stream the last 15 lines initially, then track
        tail -n 15 "${CURRENT_LOG}" 2>/dev/null || true
    fi

    # Low-impact tail poll: sleep 2s during active compilation
    sleep 2

    # Check if file stopped updating (idle backoff)
    if [ -f "${CURRENT_LOG}" ]; then
        MOD_TIME=$(stat -c %Y "${CURRENT_LOG}" 2>/dev/null || echo 0)
        NOW=$(date +%s)
        if [ $((NOW - MOD_TIME)) -gt 10 ]; then
            # Log hasn't been written to in >10s, yield CPU and sleep longer
            sleep 3
        fi
    fi
done
