#!/usr/bin/env bash
# ==============================================================================
# Filename:    tools/prov002.sh
# Purpose:     Provision Gen11 Intel OpenCL Compute Runtimes for UHD G1 iGPU
# Trigger:     Strict mode execution compliant (No Level Zero Overhead)
# Aligned:     Strictly to the 80-column visual safety horizon
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

echo "==> [START] Provisioning Intel Gen11 User-Space OpenCL Drivers..."

# Install the verified open-source Intel Compute Runtime for OpenCL
sudo apt-get update
sudo apt-get install -y intel-opencl-icd clinfo

echo "[+] Compute packages deployed. Evaluating raw OpenCL platform slots..."
if command -v clinfo &> /dev/null; then
    clinfo | grep -E "Platform Name|Device Name" || true
else
    echo "[!] clinfo utility not found in system paths."
fi

echo -e "\n[+] Evaluating updated SYCL target infrastructure..."
sycl-ls --ignore-device-selectors
