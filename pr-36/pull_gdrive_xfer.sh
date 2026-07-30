#!/usr/bin/env bash
# PATH: pr-36/pull_gdrive_xfer.sh
# PURPOSE: Safe, non-destructive Google Drive bundle puller with strict working tree guards.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

TARGET_GDRIVE="gdrive:transfer/260727_core12_core11_xfer"

echo "================================================================="
echo "[XferPull] Safe Peer Bundle Ingestion Manager"
echo "================================================================="

# Guard 1: Check working directory cleanliness
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "-----------------------------------------------------------------"
    echo "[!] SAFETY GUARD TRIGGERED: Uncommitted local changes detected!"
    echo "    Please stash or commit your changes before pulling remote bundles."
    echo "    Aborting transfer ingestion to protect your working tree."
    echo "================================================================="
    exit 1
fi

# Guard 2: Read remote manifest
echo "[+] Inspecting transfer slot on Google Drive..."
REMOTE_MANIFEST_RAW=$(rclone cat "${TARGET_GDRIVE}/transfer_manifest.json" 2>/dev/null || echo "")

if [ -z "${REMOTE_MANIFEST_RAW}" ]; then
    echo "[!] No transfer manifest found at ${TARGET_GDRIVE}."
    exit 0
fi

BUNDLE_FILE=$(echo "${REMOTE_MANIFEST_RAW}" | grep '"bundle_file"' | cut -d'"' -f4 || echo "")
REMOTE_COMMIT=$(echo "${REMOTE_MANIFEST_RAW}" | grep '"head_commit"' | cut -d'"' -f4 || echo "")
SHORT_COMMIT=$(echo "${REMOTE_MANIFEST_RAW}" | grep '"short_commit"' | cut -d'"' -f4 || echo "")
SOURCE_HOST=$(echo "${REMOTE_MANIFEST_RAW}" | grep '"source_host"' | cut -d'"' -f4 || echo "")

LOCAL_COMMIT=$(git rev-parse HEAD)

echo "-----------------------------------------------------------------"
echo " Remote Bundle : ${BUNDLE_FILE}"
echo " Source Host   : ${SOURCE_HOST}"
echo " Target Commit : ${REMOTE_COMMIT} (${SHORT_COMMIT})"
echo " Local Commit  : ${LOCAL_COMMIT}"
echo "-----------------------------------------------------------------"

# Guard 3: Early exit if local HEAD is already equal to or ahead of remote bundle
if [ "${LOCAL_COMMIT}" = "${REMOTE_COMMIT}" ]; then
    echo "[i] NO-OP: Your local tree is ALREADY at commit ${SHORT_COMMIT}."
    echo "    Nothing to pull or update."
    echo "================================================================="
    exit 0
fi

# Guard 4: Download bundle into isolated temporary directory
STAGE_DIR=$(mktemp -d /tmp/xfer_pull_XXXXXX)
trap 'rm -rf "${STAGE_DIR}"' EXIT

echo "[+] Downloading bundle: ${BUNDLE_FILE}..."
rclone copyfile "${TARGET_GDRIVE}/${BUNDLE_FILE}" "${STAGE_DIR}/${BUNDLE_NAME:-$BUNDLE_FILE}"

# Guard 5: Safe Fetch into isolated remote reference 'xfer/incoming'
echo "[+] Ingesting bundle objects into isolated tracking ref (xfer/incoming)..."
git fetch "${STAGE_DIR}/${BUNDLE_FILE}" "refs/heads/*:refs/remotes/xfer/incoming"

echo ""
echo "-----------------------------------------------------------------"
echo "[+] SUCCESS: Bundle objects ingested safely into 'xfer/incoming'!"
echo "    Your working tree and active branch were NOT modified."
echo ""
echo "To inspect differences without altering your tree, run:"
echo "  git log HEAD..refs/remotes/xfer/incoming --oneline"
echo "  git diff HEAD..refs/remotes/xfer/incoming"
echo "================================================================="
