#!/bin/bash
# ==============================================================================
# IDENTIFIER:  rclone_20260714_1240p_metadata.sh
# AUTHOR:      fekerr & Gemini
# TIMESTAMP:   20260714_1245
# DESCRIPTION: Backward-compatible archival snapshot wrapper script
# ==============================================================================
set -euo pipefail

# Default operational flags
DRY_RUN=""
VERBOSE="-v"

# Parse optional arguments for verbose, debug, and dry-run control
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN="--dry-run"
            shift
            ;;
        --debug)
            VERBOSE="-vv"
            shift
            ;;
        -q|--quiet)
            VERBOSE=""
            shift
            ;;
    esac
done

# Resolve rclone command and configuration path (supporting Win11 rclone)
WIN11_CONF="/mnt/c/Users/feker/AppData/Roaming/rclone/rclone.conf"
RCLONE_CMD=("rclone")

if [ -f "$WIN11_CONF" ]; then
    RCLONE_CMD+=("--config" "$WIN11_CONF")
fi

echo "[*] Initiating IrisLime Source Snapshot Migration..."

"${RCLONE_CMD[@]}" copy /home/fekerr/src/irislime \
    gdrive:2026LaptopsArchive/irislime/20260714_irislime_ubuntu26_core12 \
    --exclude-from .gitignore \
    --exclude ".venv/**" \
    --exclude "scratch/**" \
    --exclude "build/**" \
    --exclude ".git/**" \
    $VERBOSE \
    $DRY_RUN \
    -P

echo "[+] Snapshot operation sequence completed."

