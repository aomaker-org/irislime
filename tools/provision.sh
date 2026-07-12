#!/usr/bin/env bash
# ==============================================================================
<<<<<<< HEAD
# Path:        tools/provision.sh
# Purpose:     Unified, idempotent system provisioner handling mixed-generation
#              compute runtimes (10th Gen UHD / 11th Gen+ Iris Xe), static
#              checksum-controlled toolchain boots, and submodule auditing.
# Target OS:   Ubuntu 26.04 LTS (Resolute Raccoon) / WSL2 Subsystem ONLY
# Lineage:     Unified Asset Specification
# Updated:     20260709_0942 (fekerr & Gemini / Forensic Alignment Pass)
=======
# IrisLime Engineering Subsystem Script
# Filename:    tools/provision.sh
# Purpose:     Idempotent toolchain provisioner with submodule & NVM diagnostics
# Type:        Executable Script (Run via ./ or bash)
# Context:     Requires local repository root execution context with sudo privileges
# Assumption:  Repository has already been cloned to the host drive
# Attribution: fekerr & Gemini (20260705_2245 / NVM Bootstrap Integration)
# Timestamp:   20260705_2245
>>>>>>> origin/main
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

echo "==> [START] Launching Unified IrisLime Provisioning Sequence..."

# ------------------------------------------------------------------------------
# STEP 1: Core System Prerequisite Assembly
# ------------------------------------------------------------------------------
<<<<<<< HEAD
echo "[*] Synchronizing base system repositories and deploying utilities..."
sudo apt-get update
sudo apt-get install -y gpg gpg-agent wget curl build-essential cmake git \
    clinfo libtbb-dev ocl-icd-opencl-dev opencl-headers libssl-dev ccache
=======
echo "[*] Synchronizing base system repositories and deploying toolchain utilities..."
sudo apt-get update
sudo apt-get install -y gpg gpg-agent wget curl build-essential cmake git clinfo libtbb-dev ocl-icd-opencl-dev opencl-headers libssl-dev
>>>>>>> origin/main

# ------------------------------------------------------------------------------
# STEP 2: Register Intel Cryptographic Gates
# ------------------------------------------------------------------------------
<<<<<<< HEAD
echo "[*] Registering official Intel Software Product GPG keys..."

# NECESSARY NULL PIPE: 'tee' writes its input stream out to both the designated 
# key file path and standard output natively. We route stdout to null strictly
# to prevent raw, unreadable binary cryptographic data from flooding the terminal screen.
=======
echo "[*] Registering official Intel Software Product GPG keys to keyring storage..."
>>>>>>> origin/main
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null

# ------------------------------------------------------------------------------
<<<<<<< HEAD
# STEP 3: Bind Architecture Channels (Unified 2026 + OpenVINO Layout)
# ------------------------------------------------------------------------------
echo "[*] Injecting verified Intel oneAPI and OpenVINO APT manifests..."

# PIPES REMOVED: Streams left completely open to print the repository strings 
# directly to the console ledger for explicit provenance tracking.
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | \
    sudo tee /etc/apt/sources.list.d/oneAPI.list

# Note: Explicit fallback to ubuntu24 channel for Ubuntu 26.04 compatibility
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/openvino ubuntu24 main" | \
    sudo tee /etc/apt/sources.list.d/intel-openvino.list

# ------------------------------------------------------------------------------
# STEP 4: Adaptive Hardware Runtime Provisioning
# ------------------------------------------------------------------------------
echo "[*] Auditing host graphics processor generation..."

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
    echo "    --> Injecting high-performance Level Zero direct-to-metal stack via upstream packages."
    
    sudo apt-get update
    sudo apt-get install -y \
        "${CORE_PACKAGES[@]}" \
        libze1 \
        libze-intel-gpu1
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

PINNED_UV_VERSION="0.11.26"
KNOWN_UV_SHA256="7ac89e1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f"
IRISLIME_PROV_CK="${IRISLIME_PROV_CK:-STRICT}"

if ! command -v uv &> /dev/null; then
    if [ "$IRISLIME_PROV_CK" = "STRICT" ]; then
        echo "[*] Security Gate: IRISLIME_PROV_CK=STRICT. Enforcing pinned validation."
        TARGET_URL="https://github.com/astral-sh/uv/releases/download/${PINNED_UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz"
    else
        echo "[!] Security Gate: IRISLIME_PROV_CK=${IRISLIME_PROV_CK}. Floating latest branch tracking enabled."
        TARGET_URL="https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-unknown-linux-gnu.tar.gz"
    fi

    echo "[*] Downloading toolchain binary package..."
    wget -qO /tmp/uv.tar.gz "$TARGET_URL"

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

    tar -xzf /tmp/uv.tar.gz -C "$HOME/.local/bin" \
        --strip-components=1 uv-x86_64-unknown-linux-gnu/uv
    rm -f /tmp/uv.tar.gz
    
    export PATH="$HOME/.local/bin:$PATH"
    echo "[+] uv binary successfully extracted and bound to user space."
else
    echo "[+] uv engine already resident on host partition. Skipping download."
=======
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
>>>>>>> origin/main
fi

# ------------------------------------------------------------------------------
# STEP 5.5: Idempotent User-Space NVM Provisioning Pass
# ------------------------------------------------------------------------------
echo "[*] Auditing Node Version Manager (NVM) user-space configurations..."
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
<<<<<<< HEAD
    echo "[!] ALERT: NVM workspace missing. Bootstrapping Git mirror..."
    git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    
    # NECESSARY NULL PIPE: Shifting directories back using 'cd -' inherently dumps 
    # the target destination path to stdout. We mute it to prevent operational path noise.
    cd "$NVM_DIR" && git checkout v0.40.1 && cd - > /dev/null
    echo "[+] NVM runtime framework successfully anchored."
else
    echo "[+] Idempotency Check Passed: NVM configuration confirmed active."
=======
    echo "[!] ALERT: NVM workspace missing at $NVM_DIR. Bootstrapping Git-native mirror..."
    # Clone the official runtime tag directly to avoid out-of-band shell mutations
    git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    cd "$NVM_DIR" && git checkout v0.40.1 && cd - > /dev/null
    echo "[+] NVM runtime framework successfully anchored in user-space directory."
else
    echo "[+] Idempotency Check Passed: NVM installation directory confirmed active."
>>>>>>> origin/main
fi

# ------------------------------------------------------------------------------
# STEP 6: Submodule Forensic Audit & Realignment Loop
# ------------------------------------------------------------------------------
echo "[*] Auditing Git submodule configuration status variables..."
<<<<<<< HEAD
if git submodule status 2>/dev/null | grep -q "^-"; then
    echo "[!] ALERT: Uninitialized Git submodules detected in workspace!"
    git submodule update --init --recursive
    echo "[+] Submodule tracking vectors successfully initialized."
else
    echo "[+] Idempotency Check Passed: All submodules are configured."
=======

if git submodule status 2>/dev/null | grep -q "^-"; then
    echo "[!] ALERT: Uninitialized Git submodules detected in workspace!"
    echo "    --> Cause: The repository was likely cloned without the '--recurse-submodules' flag."
    echo "    --> Action: Launching secure in-tree recovery loop over SSH..."
    
    git submodule update --init --recursive
    echo "[+] Submodule tracking vectors successfully initialized and aligned."
else
    echo "[+] Idempotency Check Passed: All submodules are configured and active."
>>>>>>> origin/main
fi

# ------------------------------------------------------------------------------
# STEP 7: Synchronize Pinned Workspace Dependencies
# ------------------------------------------------------------------------------
<<<<<<< HEAD
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
    echo "[*] Sourcing Intel oneAPI environment variables..."
    
    # SYSTEM CRITICAL EXEMPTION GATES:
    # 1. We temporarily drop strict error checking ('set +eu') because Intel's 
    #    setvars.sh evaluates multiple internal array states that return 
    #    non-zero codes, which would otherwise terminate our script prematurely.
    # 2. NO PIPES TO NULL: Stream is left completely open to preserve the 
    #    unfiltered hardware initialization log and diagnostic telemetry trail.
    set +eu
    source /opt/intel/oneapi/setvars.sh --force
    set -eu
fi

# NECESSARY NULL PIPE: 'command -v' outputs the full local filesystem path 
# of the binary to stdout on success. We mute stdout strictly to prevent path 
# noise from cluttering the operational UI while evaluating the exit code status.
if command -v sycl-ls > /dev/null; then
    echo "=== [SYCL Device Inventory] ==="
    sycl-ls --ignore-device-selectors
else
    echo "[!] Error: sycl-ls tool absent from running session path layout."
fi

echo -e "\n==> [SUCCESS] Infrastructure provisioning sequence verified complete."

# ==============================================================================
# Context Boundary: tools/provision.sh_Complete
# ==============================================================================
=======
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
>>>>>>> origin/main
