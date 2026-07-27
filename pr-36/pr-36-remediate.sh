#!/usr/bin/env bash
# PATH: pr-36/pr-36-remediate.sh
# PURPOSE: Executes iterative path remediation & drift cleanup for PR #36.
# GUARD:   Outputs directly to terminal (NEVER PIPES TO NULL).

set -euo pipefail

# 1. Dynamically resolve script location and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PR_DIR="${PROJECT_ROOT}/pr-36"
mkdir -p "${PR_DIR}"

# 2. Resolve unique execution log path
TIMESTAMP=$(date +"%y%m%d_%H%M")
COUNTER=10

while true; do
    NNN=$(printf "%03d" "${COUNTER}")
    REMEDIATION_LOG="${PR_DIR}/remediation_${TIMESTAMP}_${NNN}.log"

    if [ ! -e "${REMEDIATION_LOG}" ]; then
        break
    fi
    chmod 444 "${REMEDIATION_LOG}" 2>/dev/null || true
    COUNTER=$((COUNTER + 10))
done

cd "${PROJECT_ROOT}"

echo "[+] Writing remediation log to: ${REMEDIATION_LOG}"

{
    echo "================================================================="
    echo "PR #36 Remediation Pass: provision.sh Path Leak Patch"
    echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "Root Path: ${PROJECT_ROOT}"
    echo "================================================================="
    echo ""

    # -----------------------------------------------------------------
    # Task 1: Patch Hardcoded Paths in tools/provision.sh
    # -----------------------------------------------------------------
    echo "--- Task 1: Refactoring Hardcoded Aliases in tools/provision.sh ---"
    if [ -f "tools/provision.sh" ]; then
        sed -i 's|/home/fekerr/src/irislime|\"${IRISLIME_ROOT:-\$HOME/src/irislime}\"|g' tools/provision.sh
        echo "[+] Successfully parameterized IRISLIME_ROOT references in tools/provision.sh."
    else
        echo "[!] Error: tools/provision.sh not found."
    fi
    echo ""

    # -----------------------------------------------------------------
    # Task 2: Self-Staging Review Artifacts
    # -----------------------------------------------------------------
    echo "--- Task 2: Self-Staging Modified Files ---"
    git add tools/provision.sh
    git add pr-36/
    echo "[+] Staged tools/provision.sh and pr-36/ assets."
    echo ""

    echo "================================================================="
    echo "Current Repository Working Tree Status:"
    echo "================================================================="
    git status
    echo ""
    echo "================================================================="
    echo "End of Remediation Log"
    echo "================================================================="
} | tee "${REMEDIATION_LOG}"

# 3. Lock remediation log as read-only
chmod 444 "${REMEDIATION_LOG}"

# Self-stage review artifacts and script
git add pr-36/

REL_REMEDIATION_LOG="pr-36/remediation_${TIMESTAMP}_${NNN}.log"

echo ""
echo "[+] Remediation log written and locked (chmod 444)."
echo "[+] Triple-clickable inspection commands:"
echo "less ${REL_REMEDIATION_LOG}"
echo "cat ${REL_REMEDIATION_LOG}"
echo ""

# End of file: pr-36/pr-36-remediate.sh
