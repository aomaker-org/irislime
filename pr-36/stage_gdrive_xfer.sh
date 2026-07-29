#!/usr/bin/env bash
# PATH: pr-36/stage_gdrive_xfer.sh
# PURPOSE: Smart transfer manager with monotonic naming, commit deduplication, and LAN peer discovery.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

TARGET_GDRIVE="gdrive:transfer/260727_core12_core11_xfer"
PEER_HOSTS=("core11.local" "CORE11-LAPTOP" "192.168.1.150")

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT=$(git rev-parse HEAD)
SHORT_COMMIT=$(git rev-parse --short HEAD)
DATE_STAMP=$(date +%y%m%d)

echo "================================================================="
echo "[XferManager] Smart Peer & Drive Transfer Manager"
echo "================================================================="
echo "[+] Local Branch : ${CURRENT_BRANCH}"
echo "[+] Local Commit : ${CURRENT_COMMIT} (${SHORT_COMMIT})"

# 1. Read remote manifest directly via rclone cat
echo "[+] Checking staging state on Google Drive..."
REMOTE_MANIFEST_RAW=$(rclone cat "${TARGET_GDRIVE}/transfer_manifest.json" 2>/dev/null || echo "")

if [ -n "${REMOTE_MANIFEST_RAW}" ]; then
    REMOTE_COMMIT=$(echo "${REMOTE_MANIFEST_RAW}" | grep '"head_commit"' | cut -d'"' -f4 || echo "")
    LAST_SEQ=$(echo "${REMOTE_MANIFEST_RAW}" | grep '"seq_num"' | cut -d':' -f2 | tr -d ' ",' || echo "0")
    
    if [ "${REMOTE_COMMIT}" = "${CURRENT_COMMIT}" ]; then
        echo "-----------------------------------------------------------------"
        echo "[i] NO-OP: Remote Google Drive stage is ALREADY up to date!"
        echo "    Commit ${SHORT_COMMIT} is already published in transfer slot."
        echo "================================================================="
        exit 0
    fi
else
    LAST_SEQ=0
fi

# Increment monotonic sequence number
NEXT_SEQ=$(printf "%03d" $((10#${LAST_SEQ:-0} + 1)))
BUNDLE_NAME="${DATE_STAMP}_${NEXT_SEQ}_${SHORT_COMMIT}_${CURRENT_BRANCH}.bundle"
MANIFEST_NAME="transfer_manifest.json"

echo "[+] Staging update required. Monotonic sequence: ${NEXT_SEQ}"

# 2. Check for active LAN peers
DISCOVERED_PEER=""
echo "[+] Probing local network for peer hosts..."
for peer in "${PEER_HOSTS[@]}"; do
    if ping -c 1 -W 1 "${peer}" >/dev/null 2>&1; then
        DISCOVERED_PEER="${peer}"
        echo "[+] Discovered active LAN peer host: ${DISCOVERED_PEER}"
        break
    fi
done

# 3. Create bundle in isolated temp directory
STAGE_DIR=$(mktemp -d /tmp/xfer_stage_XXXXXX)
trap 'rm -rf "${STAGE_DIR}"' EXIT

echo "[+] Generating Git bundle: ${BUNDLE_NAME}..."
git bundle create "${STAGE_DIR}/${BUNDLE_NAME}" HEAD

cat << MANIFEST > "${STAGE_DIR}/${MANIFEST_NAME}"
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "seq_num": ${NEXT_SEQ},
  "source_host": "$(hostname)",
  "source_branch": "${CURRENT_BRANCH}",
  "head_commit": "${CURRENT_COMMIT}",
  "short_commit": "${SHORT_COMMIT}",
  "bundle_file": "${BUNDLE_NAME}"
}
MANIFEST

# 4. Direct peer sync or GDrive upload
if [ -n "${DISCOVERED_PEER}" ]; then
    echo "[+] Attempting direct peer transfer to ${DISCOVERED_PEER}..."
    if rsync -avz "${STAGE_DIR}/" "${DISCOVERED_PEER}:~/xfer_stage/" 2>/dev/null; then
        echo "[+] Direct peer transfer successful!"
    else
        echo "[!] Peer reachable via ping, but SSH/rsync failed. Uploading to GDrive..."
        rclone copy "${STAGE_DIR}/" "${TARGET_GDRIVE}/" --progress
    fi
else
    echo "[+] Staging to Google Drive via rclone..."
    rclone copy "${STAGE_DIR}/" "${TARGET_GDRIVE}/" --progress
fi

echo ""
echo "================================================================="
echo "[XferManager] Transfer Staging Complete!"
echo "Published Bundle: ${BUNDLE_NAME}"
echo "================================================================="
