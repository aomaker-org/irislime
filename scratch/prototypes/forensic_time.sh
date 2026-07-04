#!/usr/bin/env bash
# scratch/forensic_time.sh
# Reconstructs build duration from file modification metadata and logs to ledger.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$PROJECT_ROOT/build/bin/llama-cli"
CACHE_ANCHOR="$PROJECT_ROOT/build/CMakeCache.txt"
LEDGER="$PROJECT_ROOT/scratch/build_perf_ledger.md"

# 1. Validation Guard
if [[ ! -f "$BIN" ]]; then
    echo "[!] Error: Compiled binary missing at $BIN"
    exit 1
fi

# 2. Establish Start Time Anchor (Log File vs CMake Cache Fallback)
LOG_FILE=$(ls -t "${PROJECT_ROOT}"/build_*.log 2>/dev/null | head -n 1)

if [[ -f "$LOG_FILE" ]]; then
    START_SEC=$(stat -c %Y "$LOG_FILE")
    ANCHOR_NAME=$(basename "$LOG_FILE")
elif [[ -f "$CACHE_ANCHOR" ]]; then
    START_SEC=$(stat -c %Y "$CACHE_ANCHOR")
    ANCHOR_NAME="build/CMakeCache.txt (Fallback)"
else
    echo "[!] Error: Cannot calculate duration. Missing both build_*.log and $CACHE_ANCHOR"
    exit 1
fi

# 3. Extract Target Timestamps
END_SEC=$(stat -c %Y "$BIN")
ELAPSED=$((END_SEC - START_SEC))

# Handle edge cases where clock modifications report negative deltas
if [ $ELAPSED -lt 0 ]; then ELAPSED=0; fi

# 4. Format Metrics
START_HUMAN=$(date -d @"$START_SEC" '+%Y-%m-%d %H:%M:%S')
END_HUMAN=$(date -d @"$END_SEC" '+%Y-%m-%d %H:%M:%S')
BUILD_SIZE=$(du -sh "$PROJECT_ROOT/build" | awk '{print $1}')

# 5. Generate Console Output
echo "========================================"
echo "Forensic Build Summary Recovered:"
echo "  Anchor Ref: $ANCHOR_NAME"
echo "  Start Time: $START_HUMAN"
echo "  End Time:   $END_HUMAN"
echo "  Build Size: $BUILD_SIZE"
echo "  Duration:   $((ELAPSED / 60))m $((ELAPSED % 60))s ($ELAPSED seconds)"
echo "========================================"

# 6. Initialize Ledger if Missing
if [ ! -f "$LEDGER" ]; then
    echo "# IrisLime Compilation Performance Ledger" > "$LEDGER"
    echo "" >> "$LEDGER"
    echo "| Date/Time | Anchor Source | Duration | Build Size |" >> "$LEDGER"
    echo "| :--- | :--- | :--- | :--- |" >> "$LEDGER"
fi

# 7. Append to Ledger
echo "| $END_HUMAN | $ANCHOR_NAME | $((ELAPSED / 60))m $((ELAPSED % 60))s | $BUILD_SIZE |" >> "$LEDGER"
echo "[+] Metrics securely recorded in scratch/build_perf_ledger.md"

# EPILOG: Expected filename on drive: scratch/forensic_time.sh
