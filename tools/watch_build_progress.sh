#!/bin/bash
# tools/watch_build_progress.sh
# Show build matrix progress with signs-of-life output.
# Usage:
#   ./tools/watch_build_progress.sh [matrix_dir] [interval_sec]
# Example:
#   ./tools/watch_build_progress.sh logs/build/matrix_20260622_130200 5

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

MATRIX_DIR="${1:-}"
INTERVAL="${2:-5}"

if [[ -z "$MATRIX_DIR" ]]; then
    MATRIX_DIR="$(ls -dt logs/build/matrix_* 2>/dev/null | head -1 || true)"
fi

if [[ -z "$MATRIX_DIR" || ! -d "$MATRIX_DIR" ]]; then
    echo "[!] Matrix directory not found. Provide one explicitly."
    echo "[*] Example: ./tools/watch_build_progress.sh logs/build/matrix_YYYYMMDD_HHMMSS"
    exit 1
fi

CSV="$MATRIX_DIR/build_matrix_results.csv"

echo "[+] Watching build progress"
echo "[+] Matrix dir: $MATRIX_DIR"
echo "[+] Refresh interval: ${INTERVAL}s"
echo "[+] Press Ctrl+C to stop"

while true; do
    clear
    echo "=== Build Matrix Live View ==="
    echo "Time: $(date -Iseconds)"
    echo "Matrix: $MATRIX_DIR"
    echo ""

    FREE_GB="$(df -BG . | awk 'NR==2 {print $4}')"
    echo "Free disk: $FREE_GB (policy minimum: 40G)"
    echo ""

    if [[ -f "$CSV" ]]; then
        echo "--- Completed Targets ---"
        cat "$CSV"
    else
        echo "[!] No CSV yet: $CSV"
    fi
    echo ""

    ACTIVE_LOG="$(ls -t "$MATRIX_DIR"/*.log 2>/dev/null | head -1 || true)"
    if [[ -n "$ACTIVE_LOG" ]]; then
        echo "--- Signs of life (tail: $(basename "$ACTIVE_LOG")) ---"
        tail -n 25 "$ACTIVE_LOG"
    else
        echo "[!] No log files found yet in $MATRIX_DIR"
    fi

    sleep "$INTERVAL"
done
