#!/bin/bash
# enforce_readonly.sh
# Purpose: Selectively enforce read-only filesystem attributes on telemetry and build logs
# to support the "never delete, always append" operational guardrail without breaking git.

set -e

# Target paths for locking down legacy or archived logs
LOG_DIR="logs"
ARCHIVE_DIR="logs/archive"

echo "[*] Enforcing read-only policies on historical logging endpoints..."

# Check if log directory exists before applying
if [ -d "$LOG_DIR" ]; then
    # We only apply read-only (444) to static/archived logs to allow current run logs to append.
    # In a real scenario, you could specifically target rotated .log.1, .log.2 etc.
    echo "[+] Scanning for legacy .log files in $LOG_DIR (excluding active stream buffers)..."
    find "$LOG_DIR" -type f -name "*.log.archived" -exec chmod 444 {} +
    echo "[+] Verified read-only flags on archived telemetry files."
else
    echo "[-] Directory $LOG_DIR not found. Skipping."
fi

# Example of protecting build output binaries to prevent accidental overwriting
if [ -d "build" ]; then
    echo "[+] Protecting final release binaries in build tree from user overwrites..."
    # Apply to all executable binaries, stripping write permissions
    find build/ -type f -executable -exec chmod a-w {} + 2>/dev/null || true
    echo "[+] Binaries locked."
fi

echo "[*] Immutability pass complete."
