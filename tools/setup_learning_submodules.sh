#!/usr/bin/env bash
# ==============================================================================
# Path:        tools/setup_learning_submodules.sh
# Purpose:     Automated Org Forking (aomaker-org) and Submodule Provisioner
# Target OS:   Ubuntu 26.04 LTS / WSL2 Subsystem (Core12 Workstation Platform)
# Lineage:     Unified Asset Specification / Infrastructure Tools
# Author:      IrisLime Core Engine Integration
# Updated:     20260710_0805 (Fixed gh-fork flag signatures & scroll-safe tracing)
# ==============================================================================

set -eo pipefail

REPOS=(
    "harvard-edge/cs249r_book"
    "minitorch/minitorch"
    "karpathy/build-nanogpt"
    "karpathy/micrograd"
)

TARGET_ORG="aomaker-org"
DEPS_DIR="deps/learning"

echo "=================================================================="
echo "[+] INITIALIZING ORGANIZATIONAL SUBMODULE INGESTION ENGINE"
echo "=================================================================="
echo "  [*] Target Org:       ${TARGET_ORG}"
echo "  [*] Submodule Path:   ${DEPS_DIR}/"
echo "==================================================================\n"

if ! gh auth status &>/dev/null; then
    echo "[!] Error: GitHub CLI is unauthenticated. Run 'gh auth login' first."
    exit 1
fi

mkdir -p "${DEPS_DIR}"

for src_repo in "${REPOS[@]}"; do
    repo_name=$(basename "${src_repo}")
    target_path="${DEPS_DIR}/${repo_name}"
    
    echo "------------------------------------------------------------------"
    echo "[*] Ingesting: ${src_repo}"
    echo "------------------------------------------------------------------"
    
    if [ -d "${target_path}/.git" ] || grep -q "${target_path}" .gitmodules 2>/dev/null; then
        echo "  [-] Local submodule tracking loop already established for ${repo_name}. Skipping."
        continue
    fi
    
    echo "  [+] Requesting remote fork into organization: ${TARGET_ORG}..."
    # --clone=false forces a clean background API fork execution with zero interactive prompts
    gh repo fork "${src_repo}" --org "${TARGET_ORG}" --clone=false 2>/dev/null || true
    
    echo "  [+] Resolving organizational repository metadata endpoints..."
    # Query the definitive URL target from your newly minted organizational fork asset
    if fork_url=$(gh repo view "${TARGET_ORG}/${repo_name}" --json url --template '{{.url}}' 2>/dev/null); then
        echo "  [+] Target URL Found: ${fork_url}"
        echo "  [+] Injecting and version-locking workspace submodule configuration..."
        git submodule add "${fork_url}" "${target_path}"
    else
        echo "  [!] Error: Failed to resolve organizational asset mapping for ${TARGET_ORG}/${repo_name}."
    fi
done

echo -e "\n=================================================================="
echo "[+] Initializing and fetching target dependency components..."
echo "=================================================================="
git submodule update --init --recursive

echo -e "\n[+] Success. Educational sandboxes are locked into your organizational dependencies."
echo "    Review changes using: git status"
echo "=================================================================="

# end of file: tools/setup_learning_submodules.sh
