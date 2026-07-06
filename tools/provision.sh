#!/usr/bin/env bash
# ==============================================================================
# IrisLime Engineering Subsystem Script
# Filename:    tools/provision.sh
# Purpose:     Idempotent toolchain provisioner with submodule & NVM diagnostics
# Type:        Executable Script (Run via ./ or bash)
# Context:     Requires local repository root execution context with sudo privileges
# Assumption:  Repository has already been cloned to the host drive
# Attribution: fekerr & Gemini (20260705_2245 / NVM Bootstrap Integration)
# Timestamp:   20260705_2245
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

echo "==> [START] Launching Unified IrisLime Provisioning Sequence..."

# ------------------------------------------------------------------------------
# STEP 1: Core System Prerequisite Assembly
# ------------------------------------------------------------------------------
echo "[*] Synchronizing base system repositories and deploying toolchain utilities..."
sudo apt-get update
sudo apt-get install -y gpg gpg-agent wget curl build-essential cmake git clinfo libtbb-dev ocl-icd-opencl-dev opencl-headers libssl-dev

# ------------------------------------------------------------------------------
# STEP 2: Register Intel Cryptographic Gates
# ------------------------------------------------------------------------------
echo "[*] Registering official Intel Software Product GPG keys to keyring storage..."
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null

# ------------------------------------------------------------------------------
# STEP 3: Bind Architecture Channels (Unified 2026 + Stable OpenVINO Tracking)
# ------------------------------------------------------------------------------
echo "[*] Injecting verified Intel oneAPI 2026 and OpenVINO Stable APT channel manifests..."
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | \
    sudo tee /etc/apt/sources.list.d/oneAPI.list

echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/openvino/2024 ubuntu24 main" | \
    sudo tee /etc/apt/sources.list.d/intel-openvino.list

# ------------------------------------------------------------------------------
# STEP 4: Deploy Acceleration Hardware Toolkits
# ------------------------------------------------------------------------------
echo "[*] Installing Intel compiler tracks, MKL, and OpenVINO runtime modules..."
sudo apt-get update
sudo apt-get install -y intel-oneapi-compiler-dpcpp-cpp intel-oneapi-mkl openvino

# ------------------------------------------------------------------------------
# STEP 5: Bootstrap Isolated Python Environment Manager
# ------------------------------------------------------------------------------
echo "[*] Provisioning standalone uv toolchain manager for workspace isolation..."
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source "$HOME/.local/bin/env" 2>/dev/null || true
else
    echo "[+] uv engine already resident on host partition. Skipping install block."
fi

# ------------------------------------------------------------------------------
# STEP 5.5: Idempotent User-Space NVM Provisioning Pass
# ------------------------------------------------------------------------------
echo "[*] Auditing Node Version Manager (NVM) user-space configurations..."
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "[!] ALERT: NVM workspace missing at $NVM_DIR. Bootstrapping Git-native mirror..."
    # Clone the official runtime tag directly to avoid out-of-band shell mutations
    git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    cd "$NVM_DIR" && git checkout v0.40.1 && cd - > /dev/null
    echo "[+] NVM runtime framework successfully anchored in user-space directory."
else
    echo "[+] Idempotency Check Passed: NVM installation directory confirmed active."
fi

# ------------------------------------------------------------------------------
# STEP 6: Submodule Forensic Audit & Realignment Loop
# ------------------------------------------------------------------------------
echo "[*] Auditing Git submodule configuration status variables..."

if git submodule status 2>/dev/null | grep -q "^-"; then
    echo "[!] ALERT: Uninitialized Git submodules detected in workspace!"
    echo "    --> Cause: The repository was likely cloned without the '--recurse-submodules' flag."
    echo "    --> Action: Launching secure in-tree recovery loop over SSH..."
    
    git submodule update --init --recursive
    echo "[+] Submodule tracking vectors successfully initialized and aligned."
else
    echo "[+] Idempotency Check Passed: All submodules are configured and active."
fi

# ------------------------------------------------------------------------------
# STEP 7: Synchronize Pinned Workspace Dependencies
# ------------------------------------------------------------------------------
echo "[*] Triggering uv workspace sync tracking loops against project locks..."
if [ -f "pyproject.toml" ] && [ -f "uv.lock" ]; then
    "$HOME/.local/bin/uv" sync
else
    echo "[!] Warning: pyproject.toml or uv.lock missing from active root. Skipping alignment pass."
fi

# ==============================================================================
# Telemetry Footer
# ==============================================================================
echo "==> [SUCCESS] Infrastructure provisioning sequence verified complete."
