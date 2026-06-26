#!/usr/bin/env bash
# scratch/run_gdb.sh
# Non-interactive batch wrapper to run binaries inside GDB and capture segfault backtraces.
# Propagates true execution status anomalies back to the calling process shell.

if [ $# -lt 1 ]; then
    echo "Usage: ./scratch/run_gdb.sh <path_to_binary> [arguments...]"
    exit 1
fi

TARGET_BIN="$1"
if [ ! -f "$TARGET_BIN" ]; then
    echo "[!] Error: Target binary not found at $TARGET_BIN"
    exit 1
fi

# Create a temporary file descriptor to evaluate runtime logs
TMP_GDB_LOG=$(mktemp)

echo "[+] Executing target within automated GDB session..."
echo "--------------------------------------------------------"

# Stream execution output live while duplicating logs into our temporary descriptor
gdb -batch \
    -ex "run" \
    -ex "backtrace" \
    --args "$@" 2>&1 | tee "$TMP_GDB_LOG"

echo "--------------------------------------------------------"

# Inspect the captured log vector for active hardware memory faults
if grep -E -q "Segmentation fault|Program received signal SIGSEGV" "$TMP_GDB_LOG"; then
    echo "[!] Forensic Interceptor: Severe Memory Violation (SIGSEGV) detected inside GDB stream."
    rm -f "$TMP_GDB_LOG"
    exit 139 # Standard POSIX structural exit code for unhandled segmentation faults
fi

rm -f "$TMP_GDB_LOG"
exit 0
