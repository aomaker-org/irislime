#!/usr/bin/env bash
# scratch/run_test003.sh
# Runs Test 003: Deep Dual-Repository Forensic Audit & Stash Verification

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

LOG_MD="./scratch/run_test_003.md"
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
CONSOLE_LOG="./scratch/run_test_003_console_${DATE_PREFIX}_${SEQ_PAD}.log"

# Secure incoming Windows clipboard to private blackbox storage
echo "[+] Securing incoming clipboard state..."
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

# 3. Core Forensic Audit Routing Block
run_audit() {
    # Initialize the Markdown Log Document if it doesn't exist
    if [ ! -f "$LOG_MD" ]; then
        echo "# Test 003: Workspace & Engine Delta Forensic Audit Report" > "$LOG_MD"
        echo "" >> "$LOG_MD"
        echo "## Hardware Profiler Target Baseline" >> "$LOG_MD"
        echo "- **Host Machine CPU:** $MACHINE_STATS" >> "$LOG_MD"
        echo "- **Objective:** Map exact structural alignment, branch positions, and patch points for dual repositories before porting Direct3D/Smoke features." >> "$LOG_MD"
        echo "" >> "$LOG_MD"
        echo "## System Discovered Audit Ledgers" >> "$LOG_MD"
        echo "| Execution Date/Time | Target Machine Configuration | Audit Status | Log File Target |" >> "$LOG_MD"
        echo "| :--- | :--- | :--- | :--- |" >> "$LOG_MD"
    fi

    echo "=========================================================================="
    echo "IRISLIME FORENSIC REPOSITORY AUDIT: INITIALIZING WORKSPACE CAPTURE"
    echo "Timestamp: $TIMESTAMP"
    echo "Machine Baseline: $MACHINE_STATS"
    echo "=========================================================================="
    echo ""

    echo "--------------------------------------------------------------------------"
    echo "[LAYER 1/4] AUDITING CURRENT ACTIVE ENVIRONMENT WORKSPACE (irislime)"
    echo "--------------------------------------------------------------------------"
    echo "Current Working Path: $PROJECT_ROOT"
    echo ""
    echo ">> [git status]"
    git status
    echo ""
    echo ">> [git branch -a]"
    git branch -a
    echo ""
    echo ">> [git log -3 --oneline]"
    git log -3 --oneline
    echo ""

    echo "--------------------------------------------------------------------------"
    echo "[LAYER 2/4] AUDITING SIBLING UPSTREAM INFERENCE ENGINE (llama.cpp)"
    echo "--------------------------------------------------------------------------"
    
    # Safely navigate to sibling directory path
    local SIBLING_ENGINE="../llama.cpp"
    if [ -d "$SIBLING_ENGINE" ]; then
        cd "$SIBLING_ENGINE"
        echo "Engine Fork Path: $(pwd)"
        echo ""
        echo ">> [git status]"
        git status
        echo ""
        echo ">> [git branch -a]"
        git branch -a
        echo ""
        echo ">> [git log -3 --oneline]"
        git log -3 --oneline
        echo ""
        echo ">> [git diff -U2]"
        git diff -U2
        cd "$PROJECT_ROOT"
    else
        echo "[!] CRITICAL DEVIATION: Sibling engine fork missing at expected path: $SIBLING_ENGINE"
    fi

    echo "--------------------------------------------------------------------------"
    echo "[LAYER 3/4] TELEMETRY DISCOVERY & STASHED ASSET MISSING STATUS CHECK"
    echo "--------------------------------------------------------------------------"
    echo "[+] Investigating workspace paths for historical smoke test modules..."
    
    local MISSED_FILES_COUNT=0
    for INDEX_SMOKE in {1..8}; do
        if [ ! -f "tools/smoke00${INDEX_SMOKE}.py" ]; then
            echo "  -> [MISSING] tools/smoke00${INDEX_SMOKE}.py is absent from the active layout."
            MISSED_FILES_COUNT=$((MISSED_FILES_COUNT + 1))
        else
            echo "  -> [FOUND] tools/smoke00${INDEX_SMOKE}.py exists on drive."
        fi
    done
    echo ""
    echo "[Audit Note] Total stashed smoke testing targets marked for future recovery: $MISSED_FILES_COUNT/8"
    echo ""

    echo "--------------------------------------------------------------------------"
    echo "[LAYER 4/4] RECORDING TRANSACTION METRICS"
    echo "--------------------------------------------------------------------------"
    
    local RESULT_ROW="| $TIMESTAMP | $MACHINE_STATS | COMPLETED | ${CONSOLE_LOG#$PROJECT_ROOT/} |"
    echo "$RESULT_ROW" >> "$LOG_MD"
    
    echo "[+] Structural state appended to historical results tracking: $LOG_MD"
    echo "=========================================================================="
}

# 4. Pipe everything live to the console and catch it in the unbuffered mirror log
run_audit 2>&1 | tee "$CONSOLE_LOG"

# 5. Lock the complete run context onto the Windows Clipboard
cat "$CONSOLE_LOG" | clip.exe

echo ""
echo "[+] Forensic record captured. The ENTIRE console output block is sitting on your clipboard."
echo "[+] Mirror log saved to disk: $CONSOLE_LOG"

# EPILOG: Expected filename on drive: scratch/run_test003.sh
