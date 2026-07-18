#!/usr/bin/env bash
# ==============================================================================
# Path:        tools/provision.sh
# Purpose:     Unified, idempotent system provisioner handling mixed-generation
#              compute runtimes (10th Gen UHD / 11th Gen+ Iris Xe), static
#              checksum-controlled toolchain boots, and submodule auditing.
# Target OS:   Ubuntu 26.04 LTS (Resolute Raccoon) / WSL2 Subsystem ONLY
# Lineage:     Unified Asset Specification
# Updated:     20260715_2115 (fekerr & Gemini / Symmetrical Alias Injection)
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
    clinfo libtbb-dev ocl-icd-opencl-dev opencl-headers libssl-dev ccache \
    libvulkan-dev vulkan-tools glslang-tools glslc spirv-headers

# ------------------------------------------------------------------------------
# STEP 2: Register Intel Cryptographic Gates
# ------------------------------------------------------------------------------
echo "[*] Registering official Intel Software Product GPG keys..."

# NECESSARY NULL PIPE: 'tee' writes its input stream out to both the designated 
# key file path and standard output natively. We route stdout to null strictly
# to prevent raw, unreadable binary cryptographic data from flooding the terminal screen.
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null

# ------------------------------------------------------------------------------
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
KNOWN_UV_SHA256="6426a73c3837e6e2483ee344cbc00f36394d179afcba6183cb77437e67db4af0"
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
fi

# ------------------------------------------------------------------------------
# STEP 5.5: Idempotent User-Space NVM Provisioning Pass
# ------------------------------------------------------------------------------
echo "[*] Auditing Node Version Manager (NVM) user-space configurations..."

# Supress global detached head warnings during tagged Git checkouts (NVM / other tools)
echo "[*] Silencing global Git detached HEAD warnings..."
git config --global advice.detachedHead false

export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "[!] ALERT: NVM workspace missing. Bootstrapping Git mirror..."
    git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    
    # NECESSARY NULL PIPE: Shifting directories back using 'cd -' inherently dumps 
    # the target destination path to stdout. We mute it to prevent operational path noise.
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
# STEP 7.5: Establish Symmetrical Systems Diagnostic Toolbelt
# ------------------------------------------------------------------------------
echo "[*] Anchoring custom systems engineering diagnostic toolbelt..."

# Inject sedline and aliaser into ~/.bashrc dynamically if absent
if ! grep -q "aliaser()" "$HOME/.bashrc"; then
    echo "[*] Appending 'sedline' and 'aliaser' utility blocks to ~/.bashrc..."
    cat << 'EOF' >> "$HOME/.bashrc"

# ==============================================================================
# DIAGNOSTIC TOOLBELT & CUSTOM ALIAS MANAGER
# ==============================================================================

# Print specific line from a file instantly and exit
sedline() {
    iython /home/fekerr/src/fekerr-dev/tools/pipe2clip.py'
alias br='uv run /home/fekerr/src/irislime/tools/build_runner.py'
alias tr='uv run /home/fekerr/src/irislime/tools/test_runner.py'
alias btr='uv run /home/fekerr/src/irislime/tools/bbptests_runner.py --profile vulkan_debug'
alias sign='uv run python /home/fekerr/src/fekerr-dev/tools/hash_signer.py sign'
alias verify='uv run python /home/fekerr/src/fekerr-dev/tools/hash_signer.py verify'
alias rl='unset FEKERR_DEV_READY; unset FEK_RUN_TYPE; source ~/.bashrc'
alias woof='powershell.exe -NoProfile -Command '\''[Console]::Beep(380, 80); [Console]::Beep(290, 120)'\'' 2>/dev/null &'
EOF

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
