echo "[+] Recording complete."
echo "--------------------------------------------------------"
echo "Log file saved to: $LOG_FILE"
echo "You can review it with: cat $LOG_FILE"
echo "--------------------------------------------------------"#!/bin/bash
# 20260620 fekerr
# Tool: record.sh
# Purpose: Generic wrapper to log output from any project tool with forensic metadata.
# Dependency: None (requires script path as argument)

if [ -z "$1" ]; then
    echo "[!] Usage: ./record.sh <path_to_script>"
    exit 1
fi

SCRIPT_PATH="$1"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/docs/$(basename "${SCRIPT_PATH%.*}")_$(date +%Y%m%d_%H%M%S).log"

# Forensics Header
{
    echo "=== FORENSIC LOG HEADER ==="
    echo "Timestamp: $(date)"
    echo "Git Hash:  $(git rev-parse HEAD)"
    echo "Command:   $1"
    echo "==========================="
    echo ""
} > "$LOG_FILE"

echo "[+] Recording output of $SCRIPT_PATH to: $LOG_FILE"
"$SCRIPT_PATH" 2>&1 | tee -a "$LOG_FILE"
echo "[+] Recording complete."
