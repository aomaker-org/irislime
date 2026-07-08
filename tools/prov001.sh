#!/usr/bin/env bash
# ==============================================================================
# Filename:    tools/prov001.sh
# Purpose:     Hardened Intel oneAPI MKL Developer Asset Provisioning
# Trigger:     set -euo pipefail with strict IFS isolation
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

echo "==> [START] Verifying Intel oneAPI MKL Developer Assets..."

# 1. Audit what Intel development packages are currently missing
echo "[*] Querying local package manager status..."
dpkg -l | grep "intel-oneapi-mkl" || true

echo -e "\n[*] Attempting to fetch explicit Intel MKL developer component..."
# This package delivers the missing MKLConfig.cmake files to the tree
sudo apt-get update
sudo apt-get install -y intel-oneapi-mkl-devel

echo "[+] Provisioning sequence complete. Re-running asset discovery..."
if find /opt/intel/oneapi -name "MKLConfig.cmake" -print -quit | grep -q .; then
    echo "[PASS] MKLConfig.cmake successfully established in oneAPI tree."
else
    echo "[FAIL] Assets still absent. Manual archive verification required."
    exit 1
fi
