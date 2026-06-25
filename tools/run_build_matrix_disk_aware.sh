#!/bin/bash
# tools/run_build_matrix_disk_aware.sh
# Build multiple TARGETs while enforcing free-space threshold.
# Usage:
#   ./tools/run_build_matrix_disk_aware.sh [min_free_gb] [validate]
# Example:
#   ./tools/run_build_matrix_disk_aware.sh 40 0

set -euo pipefail

MIN_FREE_GB="${1:-40}"
VALIDATE="${2:-0}"
DISK_GUARD_PATH="${3:-/mnt/c}"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ -z "${IRISLIME_READY:-}" ]]; then
    echo "[!] ERROR: IRISLIME_READY is not set. Run: source config_env"
    exit 1
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="logs/build/matrix_${TIMESTAMP}"
mkdir -p "$RUN_DIR"
CSV="$RUN_DIR/build_matrix_results.csv"

TARGETS=(
  cpu_release
  sycl_release
  sycl_relwithdebinfo
    cpu_debug
)

echo "timestamp,target,status,exit_code,free_gb_before,free_gb_after,build_dir_size,log_file" > "$CSV"

echo "[+] Build matrix start: $TIMESTAMP"
echo "[+] Min free space: ${MIN_FREE_GB} GB"
echo "[+] Validate step: ${VALIDATE}"
echo "[+] Disk guard path: ${DISK_GUARD_PATH}"
echo "[+] Output directory: $RUN_DIR"

disk_free_gb() {
    local path="$DISK_GUARD_PATH"
    if [[ ! -d "$path" ]]; then
        path="."
    fi
    df -BG "$path" | awk 'NR==2 { gsub("G", "", $4); print $4 }'
}

for target in "${TARGETS[@]}"; do
    free_before="$(disk_free_gb)"

    if [[ "$free_before" -lt "$MIN_FREE_GB" ]]; then
        echo "[!] BREAK: free space ${free_before} GB is below threshold ${MIN_FREE_GB} GB"
        echo "[!] Please clean disk space, then rerun from target: $target"
        echo "$(date -Iseconds),$target,BREAK,0,$free_before,$free_before,NA,NA" >> "$CSV"
        exit 10
    fi

    log_file="$RUN_DIR/${target}.log"
    echo "[+] Building $target (free before: ${free_before} GB)"
    echo "[+] Logging to: $log_file"

    set +e
    make build TARGET="$target" MIN_FREE_GB="$MIN_FREE_GB" VALIDATE="$VALIDATE" DISK_GUARD_PATH="$DISK_GUARD_PATH" 2>&1 | tee "$log_file"
    ec=$?
    set -e

    if [[ -d "build/$target" ]]; then
        build_size="$(du -sh "build/$target" | awk '{print $1}')"
    else
        build_size="NA"
    fi

    free_after="$(disk_free_gb)"

    if [[ "$ec" -eq 0 ]]; then
        status="PASS"
        echo "[+] PASS $target (free after: ${free_after} GB, size: $build_size)"
    else
        status="FAIL"
        echo "[!] FAIL $target (exit=$ec, free after: ${free_after} GB)"
    fi

    echo "$(date -Iseconds),$target,$status,$ec,$free_before,$free_after,$build_size,$log_file" >> "$CSV"
done

echo "[+] Build matrix complete"
echo "[+] Summary CSV: $CSV"
cat "$CSV"
