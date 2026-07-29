#!/usr/bin/env bash
# ==============================================================================
# Filename:     tools/tail_all_logs.sh
# Purpose:      Real-time Multi-Log Stream Telemetry Tail Utility (POSIX/WSL)
# Target OS:    Ubuntu 26.04 LTS / WSL2
# Lineage:      IrisLime Infrastructure
# Usage:        ./tools/tail_all_logs.sh
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=========================================================="
echo "   IrisLime Real-Time Multi-Log Stream Telemetry Tail    "
echo "=========================================================="
echo "[*] Workspace Root: ${ROOT_DIR}"
echo "[*] Log Directory : ${ROOT_DIR}/logs"
echo "----------------------------------------------------------"

LOG_FILES=$(find "${ROOT_DIR}/logs" /tmp -name "*.log" -o -name "*.csv" 2>> /tmp/tail_audit.log || true)

if [ -z "${LOG_FILES}" ]; then
    echo "[!] No active log files found under logs/ or /tmp."
    exit 1
fi

echo "[+] Streaming live log feeds (Press Ctrl+C to stop)..."
echo "----------------------------------------------------------"

# Use tail -f across all discovered log and csv files
tail -n 10 -f ${LOG_FILES}
