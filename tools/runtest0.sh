#!/bin/bash
# tools/runtest.sh - Robust forensic wrapper

FULL_PATH=$1
if [ -z "$FULL_PATH" ]; then
    echo "Usage: ./tools/runtest.sh <path-to-binary>"
    exit 1
fi

# Extract the base name for the log file
BIN_NAME=$(basename "$FULL_PATH")
mkdir -p logs/test

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="./logs/test/${BIN_NAME}_${TIMESTAMP}.log"

echo "[+] Target: $FULL_PATH"
echo "[+] Logging to: $LOG_FILE"

# Execute directly using the provided path
{
    "$FULL_PATH" 2>&1
} | tee "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -ne 0 ]; then
    echo "[!] [CRASH DETECTED] Exit Code: $EXIT_CODE"
else
    echo "[+] [SUCCESS] Test completed normally."
fi
