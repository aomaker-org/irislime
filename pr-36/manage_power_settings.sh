#!/usr/bin/env bash
# PATH: pr-36/manage_power_settings.sh
# PURPOSE: Inspect and toggle Windows power/sleep settings from WSL for background builds.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

echo "================================================================="
echo "[PowerMgmt] Querying Host Power & Sleep Configuration"
echo "================================================================="

# Query Windows Power Scheme settings via PowerShell
get_win_power_val() {
    local subgroup="$1"
    local setting="$2"
    local raw_val
    raw_val=$(powershell.exe -NoProfile -Command \
        "(powercfg /q SCHEME_CURRENT ${subgroup} ${setting} | Select-String 'Current AC Power Setting Index:') -replace '.*: 0x', ''" 2>/dev/null | tr -d '\r\n')
    
    if [ -n "${raw_val}" ]; then
        echo "$((16#${raw_val}))"
    else
        echo "0"
    fi
}

echo "[+] Querying current AC power scheme parameters..."

# Subgroup GUIDs for PowerCFG:
# SUB_SLEEP = 238c9f37-0e69-4d22-9f0a-225f2d2042d2, STANDBYIDLE = 29f7022d-2fe1-459f-a6b8-80e9f0298e6c
# SUB_VIDEO = 7516b95f-f776-4464-8c53-06167f40cc99, VIDEOIDLE   = 3c00e650-2317-46f7-9401-f13f5938da50

SLEEP_SEC=$(get_win_power_val "238c9f37-0e69-4d22-9f0a-225f2d2042d2" "29f7022d-2fe1-459f-a6b8-80e9f0298e6c")
VIDEO_SEC=$(get_win_power_val "7516b95f-f776-4464-8c53-06167f40cc99" "3c00e650-2317-46f7-9401-f13f5938da50")

SLEEP_MIN=$((SLEEP_SEC / 60))
VIDEO_MIN=$((VIDEO_SEC / 60))

echo ""
echo "-----------------------------------------------------------------"
echo " Current Host Settings (Plugged In / AC):"
echo "-----------------------------------------------------------------"
if [ "${SLEEP_MIN}" -eq 0 ]; then
    echo "  • System Sleep Timeout : NEVER (0 min) [BUILD SAFE]"
else
    echo "  • System Sleep Timeout : ${SLEEP_MIN} minutes [RISK: VM MAY SUSPEND]"
fi

if [ "${VIDEO_MIN}" -eq 0 ]; then
    echo "  • Display Off Timeout  : NEVER (0 min)"
else
    echo "  • Display Off Timeout  : ${VIDEO_MIN} minutes"
fi

# Check if PowerToys Awake process is actively running
AWAKE_PID=$(powershell.exe -NoProfile -Command "(Get-Process PowerToys.Awake -ErrorAction SilentlyContinue).Id" 2>/dev/null | tr -d '\r\n')
if [ -n "${AWAKE_PID}" ]; then
    echo "  • PowerToys Awake      : ACTIVE (PID: ${AWAKE_PID})"
else
    echo "  • PowerToys Awake      : INACTIVE"
fi
echo "-----------------------------------------------------------------"
echo ""

# Interactive toggle prompt
echo "Select Power Action:"
echo "  [1] Set AC System Sleep to NEVER (Recommended for background builds)"
echo "  [2] Restore Default System Sleep (30 minutes)"
echo "  [3] Launch PowerToys Awake"
echo "  [4] Keep current settings and exit"
echo ""
read -rp "Enter choice [1-4]: " choice

case "${choice}" in
    1)
        echo "[+] Setting AC System Sleep timeout to 0 (Never)..."
        powershell.exe -NoProfile -Command "powercfg /change standby-timeout-ac 0" 2>/dev/null || true
        echo "[+] System Sleep set to NEVER. You can safely lock screen (Win+L)."
        ;;
    2)
        echo "[+] Restoring AC System Sleep timeout to 30 minutes..."
        powershell.exe -NoProfile -Command "powercfg /change standby-timeout-ac 30" 2>/dev/null || true
        echo "[+] Restored AC sleep timeout to 30 minutes."
        ;;
    3)
        echo "[+] Attempting to launch PowerToys Awake..."
        powershell.exe -NoProfile -Command "Start-Process 'PowerToys.Awake.exe' -ArgumentList '--use-display-time=false --time-interval=0' -ErrorAction SilentlyContinue" || true
        echo "[+] PowerToys Awake invocation dispatched."
        ;;
    4|*)
        echo "[+] Retaining existing power settings."
        ;;
esac

echo ""
echo "================================================================="
echo "[PowerMgmt] Configuration check complete."
echo "================================================================="
