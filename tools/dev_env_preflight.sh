#!/bin/bash
# tools/dev_env_preflight.sh
# Preflight checks for local dev workflow reliability (storage + mounts + rclone).
# Usage:
#   ./tools/dev_env_preflight.sh [min_free_gb] [disk_guard_path]

set -euo pipefail

MIN_FREE_GB="${1:-40}"
DISK_GUARD_PATH="${2:-/mnt/c}"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== Dev Environment Preflight ==="
echo "timestamp: $(date -Iseconds)"
echo "project_root: $PROJECT_ROOT"
echo "min_free_gb: $MIN_FREE_GB"
echo "disk_guard_path: $DISK_GUARD_PATH"

if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    echo "runtime_context: WSL (${WSL_DISTRO_NAME})"
else
    echo "runtime_context: non-WSL"
fi

if [[ ! -d "$DISK_GUARD_PATH" ]]; then
    echo "[!] Guard path not found: $DISK_GUARD_PATH"
    exit 2
fi

FREE_GB=$(df -BG "$DISK_GUARD_PATH" | awk 'NR==2 {gsub("G", "", $4); print $4}')
echo "free_gb_guard_path: $FREE_GB"

if [[ "$FREE_GB" -lt "$MIN_FREE_GB" ]]; then
    echo "[!] FAIL: free space below threshold (${FREE_GB} < ${MIN_FREE_GB})"
    exit 3
fi

echo "[+] PASS: free-space guard"

echo ""
echo "--- Mounts ---"
for p in /mnt/g /mnt/h; do
    if [[ -d "$p" ]]; then
        echo "[+] present: $p"
    else
        echo "[!] missing: $p"
    fi
done

echo ""
echo "--- rclone ---"
if command -v rclone >/dev/null 2>&1; then
    echo "[+] rclone installed: $(command -v rclone)"
    echo "[+] remotes:"
    rclone listremotes 2>/dev/null || true
else
    echo "[!] rclone missing"
fi

echo ""
echo "--- Policy Hint ---"
echo "preferred_storage_mode: windows_host_managed"
echo "fallback_storage_mode: wsl_mount_managed"
echo "primary_bulk_remote: gaom:"
echo "secondary_compact_remote: onedrive:/onedrive0:"
echo "local_stage_root: /mnt/g/irislime_cold"
echo "local_mirror_root: /mnt/h/irislime_mirror (if mounted)"

if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    echo ""
    echo "[!] Advisory: run heavy archive/sync jobs from Windows host when possible."
fi

echo ""
echo "[+] Preflight complete"
