#!/usr/bin/env bash
# scratch/run_test000.sh
# Runs Test 000: OpenCL GPU Discovery and handles logging safely.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

LOG_MD="./scratch/run_test_000.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
BACKUP_DIR="./.security_scrub"

# 1. Clipboard Privacy Guard
# Securely back up whatever is currently in your Windows clipboard before we edit it
mkdir -p "$BACKUP_DIR"
powershell.exe -Command "Get-Clipboard" > "$BACKUP_DIR/clipboard_incoming_bak.txt" 2>/dev/null

# 2. Auto-create the markdown log file if it doesn't exist yet
if [ ! -f "$LOG_MD" ]; then
    echo "# Test 000: OpenCL GPU Device Discovery" > "$LOG_MD"
    echo "" >> "$LOG_MD"
    echo "## Objective" >> "$LOG_MD"
    echo "Verify that the SYCL compiler toolchain can safely see the Intel Iris Xe GPU via OpenCL." >> "$LOG_MD"
    echo "" >> "$LOG_MD"
    echo "## History Ledger" >> "$LOG_MD"
    echo "| Date/Time (PDT) | Status | Exit Code | Notes |" >> "$LOG_MD"
    echo "| :--- | :--- | :--- | :--- |" >> "$LOG_MD"
fi

echo "=== Running Test 000: OpenCL GPU Discovery ==="

# Force the OpenCL backend bypass inside our GDB wrapper
export ONEAPI_DEVICE_SELECTOR=opencl:gpu
./scratch/run_gdb.sh ./build/bin/llama-ls-sycl-device
RUN_STATUS=$?

echo "----------------------------------------------"
if [ $RUN_STATUS -eq 0 ]; then
    RESULT_LINE="| $TIMESTAMP | PASS | 0 | Automated run cleared cleanly. |"
    echo "[PASS] Intel GPU discovered successfully via OpenCL."
else
    RESULT_LINE="| $TIMESTAMP | FAIL | $RUN_STATUS | Execution encountered a fault. |"
    echo "[FAIL] Test failed or core-dumped with code: $RUN_STATUS"
fi

# Append row to the permanent Markdown log file
echo "$RESULT_LINE" >> "$LOG_MD"
echo "=============================================="

# 3. Post-Execution Screen and Clipboard Sync
echo ""
echo "--- Current Test Ledger State ($LOG_MD) ---"
cat "$LOG_MD"
echo "----------------------------------------------"

# Load the single target test row into the Windows clipboard
echo "$RESULT_LINE" | clip.exe
echo "[+] Metrics row pushed to clipboard. Previous clipboard saved to $BACKUP_DIR/"

# EPILOG: Expected filename on drive: scratch/run_test000.sh
