#!/usr/bin/env bash
# ==============================================================================
# Filename:     tools/tail_all_logs_win.sh
# Purpose:      WSL Bash Wrapper to Invoke Windows PowerShell 7 Log Tail Utility
# Target OS:    Ubuntu 26.04 LTS / WSL2 -> Windows 11 Host Interop
# Lineage:      IrisLime Infrastructure
# Usage:        ./tools/tail_all_logs_win.sh [optional_target_file.ps1]
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PS1="${1:-${SCRIPT_DIR}/tail_all_logs.ps1}"

# Convert WSL POSIX path to Windows path for pwsh.exe compatibility
if command -v wslpath >/dev/null 2>&1; then
    WIN_PS1="$(wslpath -w "${TARGET_PS1}")"
else
    WIN_PS1="${TARGET_PS1}"
fi

# Locate PowerShell 7 executable (pwsh.exe)
PWSH_EXE=""
if command -v pwsh.exe >/dev/null 2>&1; then
    PWSH_EXE="pwsh.exe"
elif [ -f "/mnt/c/Program Files/PowerShell/7/pwsh.exe" ]; then
    PWSH_EXE="/mnt/c/Program Files/PowerShell/7/pwsh.exe"
else
    echo "[!] Error: pwsh.exe not detected in Windows PATH or /mnt/c/Program Files/PowerShell/7/." >&2
    exit 1
fi

echo "[+] Invoking Host PowerShell 7 with One-Time ExecutionPolicy Bypass:"
echo "    Executable: ${PWSH_EXE}"
echo "    Script Target: ${WIN_PS1}"
echo "----------------------------------------------------------"

"${PWSH_EXE}" -NoProfile -ExecutionPolicy Bypass -File "${WIN_PS1}"
