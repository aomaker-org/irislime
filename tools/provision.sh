#!/usr/bin/env bash
# ==============================================================================
# IrisLime Engineering Subsystem Script
# Filename:    tools/provision.sh
# Purpose:     Unified, idempotent system provisioner handling mixed-generation
#              compute runtimes (10th Gen UHD / 11th Gen+ Iris Xe), static
#              checksum-controlled toolchain boots, and submodule auditing.
# Type:        Executable Script (Run via ./ or bash)
# Context:     Requires local repository root execution context with sudo
# Attribution: fekerr & Gemini (20260708_1720 / Production Integration)
# Timestamp:   20260708_1720
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

echo "==> [START] Launching Unified IrisLime Provisioning Sequence..."

# ------------------------------------------------------------------------------
# STEP 1: Core System Prerequisite Assembly
# ------------------------------------------------------------------------------
echo "[*] Synchronizing base system repositories and deploying utilities..."
sudo apt-get update
sudo apt-get install -y gpg gpg-agent wget curl build-essential cmake git \
    clinfo libtbb-dev ocl-icd-opencl-dev opencl-headers libssl-dev ccache

# ------------------------------------------------------------------------------
# STEP 2: Register Intel Cryptographic Gates
# ------------------------------------------------------------------------------
echo "[*] Registering official Intel Software Product GPG keys..."
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null

# ------------------------------------------------------------------------------
# STEP 3: Bind Architecture Channels (Unified 2026 + OpenVINO Layout)
# ------------------------------------------------------------------------------
echo "[*] Injecting verified Intel oneAPI and OpenVINO APT manifests..."
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | \
    sudo tee /etc/apt/sources.list.d/oneAPI.list > /dev/null

# Note: Explicit fallback to ubuntu24 channel for Ubuntu 26.04 compatibility
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/openvino/2026 ubuntu24 main" | \
    sudo tee /etc/apt/sources.list.d/intel-openvino.list > /dev/null

# ------------------------------------------------------------------------------
# STEP 4: Adaptive Hardware Runtime Provisioning
# ------------------------------------------------------------------------------
echo "[*] Auditing host graphics processor generation..."

# Base packages required across both legacy and modern testing platforms
CORE_PACKAGES=(
    "intel-oneapi-compiler-dpcpp-cpp"
    "intel-oneapi-mkl-devel"
    "intel-opencl-icd"
    "openvino"
)

# Call the host win11 CIM engine across the boundary to isolate processor name
HOST_CPU=$(powershell.exe -NoProfile -Command "(Get-CimInstance Win32_Processor).Name" 2>/dev/null || echo "Unknown")
echo "[+] Host processor identified: ${HOST_CPU}"

if echo "${HOST_CPU}" | grep -qE "i[0-9]-10"; then
    echo "[!] Target identified as 10th Gen Intel Core Hardware (UHD Graphics)."
    echo "    --> Enforcing legacy OpenCL compute profile. Bypassing Level Zero."
    
    sudo apt-get update
    sudo apt-get install -y "${CORE_PACKAGES[@]}"
else
    echo "[+] Target identified as 11th Gen+ Intel Hardware (Iris Xe / Discrete)."
    echo "    --> Injecting high-performance Level Zero direct-to-metal stack."
    
    sudo apt-get update
    sudo apt-get install -y \
        "${CORE_PACKAGES[@]}" \
        intel-level-zero-gpu \
        level-zero
fi

# ------------------------------------------------------------------------------
# STEP 4.5: Post-Install Hardware & Compilation Validation Loops
# ------------------------------------------------------------------------------
echo -e "\n=== [POST-INSTALL VERIFICATION] ==="

echo "[*] Auditing CMake compilation anchors..."
if find /opt/intel/oneapi -name "MKLConfig.cmake" -print -quit | grep -q .; then
    echo "[PASS] MKLConfig.cmake successfully established in oneAPI tree."
else
    echo "[FAIL] Development assets absent. Manual verification required."
    exit 1
fi

echo -e "\n[*] Evaluating OpenCL device platform slots..."
clinfo | grep -E "Platform Name|Device Name" || true

# ------------------------------------------------------------------------------
# STEP 5: Secure Static Bootstrapping with Variable Checksum Control
# ------------------------------------------------------------------------------
echo -e "\n[*] Provisioning standalone uv toolchain manager..."
mkdir -p "$HOME/.local/bin"

# 1. Establish the pinned target version and its known cryptographic footprint
PINNED_UV_VERSION="0.11.26"
# NOTE: Replace this mock verification literal with the absolute hash from 
# the upstream uv release registry when locking down your secure production baseline.
KNOWN_UV_SHA256="7ac89e1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f"

# 2. Evaluate the control environment variable, defaulting to STRICT enforcement
IRISLIME_PROV_CK="${IRISLIME_PROV_CK:-STRICT}"

if ! command -v uv &> /dev/null; then
    if [ "$IRISLIME_PROV_CK" = "STRICT" ]; then
        echo "[*] Security Gate: IRISLIME_PROV_CK=STRICT. Enforcing pinned validation."
        TARGET_URL="https://github.com/astral-sh/uv/releases/download/${PINNED_UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz"
    else
        echo "[!] Security Gate: IRISLIME_PROV_CK=${IRISLIME_PROV_CK}. Floating latest branch tracking enabled."
        TARGET_URL="https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-unknown-linux-gnu.tar.gz"
    fi

    # 3. Passive file capture to isolated temp partition
    echo "[*] Downloading toolchain binary package..."
    wget -qO /tmp/uv.tar.gz "$TARGET_URL"

    # 4. Conditional Cryptographic Assertions Loop
    if [ "$IRISLIME_PROV_CK" = "STRICT" ]; then
        echo "[*] Running SHA256 cryptographic verification..."
        COMPUTED_SHA256=$(sha256sum /tmp/uv.tar.gz | awk '{print $1}')
        
        if [ "$COMPUTED_SHA256" != "$KNOWN_UV_SHA256" ]; then
            echo "[X] SUPPLY CHAIN FAULT: Cryptographic checksum validation failed!"
            echo "    Expected: ${KNOWN_UV_SHA256}"
            echo "    Computed: ${COMPUTED_SHA256}"
            rm -f /tmp/uv.tar.gz
            exit 1
        fi
        echo "[PASS] Binary integrity verified successfully."
    fi

    # 5. Extract target compiled executable node cleanly
    tar -xzf /tmp/uv.tar.gz -C "$HOME/.local/bin" \
        --strip-components=1 uv-x86_64-unknown-linux-gnu/uv
    rm -f /tmp/uv.tar.gz
    
    export PATH="$HOME/.local/bin:$PATH"
    echo "[+] uv binary successfully extracted and bound to user space."
else
    echo "[+] uv engine already resident on host partition. Skipping download."
fi

# ------------------------------------------------------------------------------
# STEP 5.5: Idempotent User-Space NVM Provisioning Pass
# ------------------------------------------------------------------------------
echo "[*] Auditing Node Version Manager (NVM) user-space configurations..."
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "[!] ALERT: NVM workspace missing. Bootstrapping Git mirror..."
    git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    cd "$NVM_DIR" && git checkout v0.40.1 && cd - > /dev/null
    echo "[+] NVM runtime framework successfully anchored."
else
    echo "[+] Idempotency Check Passed: NVM configuration confirmed active."
fi

# ------------------------------------------------------------------------------
# STEP 6: Submodule Forensic Audit & Realignment Loop
# ------------------------------------------------------------------------------
echo "[*] Auditing Git submodule configuration status variables..."
if git submodule status 2>/dev/null | grep -q "^-"; then
    echo "[!] ALERT: Uninitialized Git submodules detected in workspace!"
    git submodule update --init --recursive
    echo "[+] Submodule tracking vectors successfully initialized."
else
    echo "[+] Idempotency Check Passed: All submodules are configured."
fi

# ------------------------------------------------------------------------------
# STEP 7: Synchronize Pinned Workspace Dependencies
# ------------------------------------------------------------------------------
echo "[*] Triggering uv workspace sync tracking loops..."
UV_BIN="$HOME/.local/bin/uv"
if [ -f "pyproject.toml" ] && [ -f "$UV_BIN" ]; then
    "$UV_BIN" sync
else
    echo "[!] Warning: pyproject.toml missing or uv binary absent. Skipping."
fi

# ------------------------------------------------------------------------------
# STEP 8: SYCL Target Infrastructure Audit
# ------------------------------------------------------------------------------
echo -e "\n[*] Verifying live SYCL hardware compute topography..."
if [ -f /opt/intel/oneapi/setvars.sh ]; then
    source /opt/intel/oneapi/setvars.sh --force > /dev/null 2>&1 || true
fi

if command -v sycl-ls &> /dev/null; then
    echo "=== [SYCL Device Inventory] ==="
    sycl-ls --ignore-device-selectors
else
    echo "[!] Error: sycl-ls tool absent from running session path layout."
fi

echo "==> [SUCCESS] Infrastructure provisioning sequence verified complete."
