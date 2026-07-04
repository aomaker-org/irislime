#!/usr/bin/env bash
# scratch/run_test002.sh
# Runs Test 002: OpenCL GPU Discovery, captures full console mirror, tracks machine specs, logs entirely to clipboard.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

LOG_MD="./scratch/run_test_002.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
BACKUP_DIR="./.security_scrub"
DATE_PREFIX=$(date '+%y%m%d_%H%M')

# 1. Suffix Sequence Engine (Shared across Clipboard & Raw Console Logs)
mkdir -p "$BACKUP_DIR"
COUNTER=1
while [ -f "$BACKUP_DIR/clipboard_${DATE_PREFIX}_$(printf "%03d" $COUNTER).txt" ]; do
    COUNTER=$((COUNTER + 1))
done
SEQ_PAD=$(printf "%03d" $COUNTER)

BACKUP_FILE="$BACKUP_DIR/clipboard_${DATE_PREFIX}_${SEQ_PAD}.txt"
CONSOLE_LOG="./scratch/run_test_002_console_${DATE_PREFIX}_${SEQ_PAD}.log"

# Secure incoming Windows clipboard to private blackbox storage (No dev/null redirections)
echo "[+] Capturing incoming clipboard state..."
powershell.exe -Command "Get-Clipboard" > "$BACKUP_FILE"
chmod 400 "$BACKUP_FILE"

# 2. Automated Hardware Spec Detection
if [ -f /proc/cpuinfo ]; then
    CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^\s*//')
    CORE_COUNT=$(grep -c "processor" /proc/cpuinfo)
    MACHINE_STATS="${CPU_MODEL} (${CORE_COUNT} Threads)"
else
    MACHINE_STATS="$(uname -srm)"
fi

# 3. Execution Pipeline Function
run_pipeline() {
    if [ ! -f "$LOG_MD" ]; then
        echo "# Test 002: OpenCL GPU Device Discovery Baseline" > "$LOG_MD"
        echo "" >> "$LOG_MD"
        echo "## Hardware Architecture Profile Baseline" >> "$LOG_MD"
        echo "- Probed Host CPU: $MACHINE_STATS" >> "$LOG_MD"
        echo "- Objective: Document OpenCL backend mapping behavior across platform generations." >> "$LOG_MD"
        echo "" >> "$LOG_MD"
        echo "## History Results Ledger" >> "$LOG_MD"
        echo "| Date/Time (PDT) | Machine Signature Profile | Status | Exit Code | Notes |" >> "$LOG_MD"
        echo "| :--- | :--- | :--- | :--- | :--- |" >> "$LOG_MD"
    fi

    echo "=== Running Test 002: OpenCL GPU Discovery ==="
    echo "[+] Machine Signature Detected: $MACHINE_STATS"
    echo "----------------------------------------------"

    # Force the OpenCL backend bypass inside our GDB wrapper
    export ONEAPI_DEVICE_SELECTOR=opencl:gpu
    bash ./scratch/run_gdb.sh ./build/bin/llama-ls-sycl-device
    RUN_STATUS=$?

    echo "----------------------------------------------"
    if [ $RUN_STATUS -eq 0 ]; then
        RESULT_LINE="| $TIMESTAMP | $MACHINE_STATS | PASS | 0 | OpenCL platform discovery cleared cleanly. |"
        echo "[PASS] Intel GPU discovered successfully via OpenCL."
    else
        RESULT_LINE="| $TIMESTAMP | $MACHINE_STATS | FAIL | $RUN_STATUS | Execution encountered a fault. |"
        echo "[FAIL] Test failed or core-dumped with code: $RUN_STATUS"
    fi

    # Append metrics row to the clean results markdown ledger
    echo "$RESULT_LINE" >> "$LOG_MD"
    echo "=============================================="
    echo ""
    echo "--- Separate Results Ledger State ($LOG_MD) ---"
    cat "$LOG_MD"
    echo "----------------------------------------------"
}

# 4. Stream and Intercept Everything Going to the Console into the permanent log
run_pipeline 2>&1 | tee "$CONSOLE_LOG"

# 5. Load the ENTIRE capture of the run info into the Windows clipboard
cat "$CONSOLE_LOG" | clip.exe

echo ""
echo "[+] Full run information safely locked inside Windows clipboard."
echo "[+] Full raw console mirror saved to: $CONSOLE_LOG"
echo "[+] Previous clipboard secured read-only: $BACKUP_FILE"

# EPILOG: Expected filename on drive: scratch/run_test002.sh
