#!/usr/bin/env bash
# Shell entry point for Top-Down Log Archiver & Rclone Cloud Streamer
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

export PYTHONPATH="${WORKSPACE_ROOT}:${PYTHONPATH}"

python3 "${SCRIPT_DIR}/archive_logs_rclone.py" "$@"
