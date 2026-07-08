#!/usr/bin/env bash
# ==============================================================================
# Filename:    tools/prov002.sh
# Purpose:     Install User-Space Intel Compute Runtime Drivers for WSL2
# Trigger:     Strict mode execution compliant
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

echo "==> [START] Provisioning Intel User-Space Compute Drivers..."

# Install the primary Level Zero and OpenCL compute implementations
sudo apt-get update
sudo apt-get install -y \
    intel-opencl-icd \
    intel-level-zero-gpu \
    level-zero

echo "[+] Runtimes deployed. Verifying platform visibility..."
if command -v sycl-ls &> /dev/null; then
    echo "=== [SYCL Device Inventory] ==="
    sycl-ls
else
    echo "[!] Sourced environment missing sycl-ls tool tracking utility."
fi
