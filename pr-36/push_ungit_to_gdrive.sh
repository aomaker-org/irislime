#!/usr/bin/env bash
set -euo pipefail

TIMESTAMP="0727_1600p_100"
ARCHIVE_NAME="pr36_ungit_${TIMESTAMP}.tar.xz"
TARGET_DIR="pr-36/local_artifacts"
REMOTE_DEST="gdrive:transfer"

echo "[*] Packaging local ungit artifacts from ${TARGET_DIR}..."
if [ ! -d "$TARGET_DIR" ]; then
    echo "[-] Error: Directory ${TARGET_DIR} not found."
    exit 1
fi

# Create high-compression xz tarball of the artifacts
tar -cJf "${ARCHIVE_NAME}" -C "${TARGET_DIR}" .
echo "[+] Created archive: ${ARCHIVE_NAME}"

echo "[*] Pushing to ${REMOTE_DEST}/${ARCHIVE_NAME} via rclone..."
rclone copyto "${ARCHIVE_NAME}" "${REMOTE_DEST}/${ARCHIVE_NAME}" --progress

echo "[+] Upload complete!"
