#!/usr/bin/env bash
# ==============================================================================
# Filename:    scratch/probe_sycl.sh
# Purpose:     Isolated environment diagnostic & oneAPI MKL verification probe
# Type:        Tactical Script (Sandbox-within-a-sandbox execution compliant)
# Attribution: fekerr & Gemini (20260706_1327 / Direct Injection Pass)
# Line Width:  Strictly <= 80 Characters Alignment
# ==============================================================================

# set -x

echo "=== [ISLM PROBE] Evaluating Active System Environment ==="
echo "[*] Hostname:       $(hostname)"
echo "[*] Active User:    $USER"
echo "[*] MKLROOT State:  ${MKLROOT:-NOT_SET}"
echo "[*] ONEAPI_ROOT:    ${ONEAPI_ROOT:-NOT_SET}"

echo -e "\n=== [ISLM PROBE] Locating MKL Installation Assets ==="
MKL_CONF_FIND=$(find /opt/intel/oneapi \
    -name "MKLConfig.cmake" -print -quit 2>/dev/null)

if [ -n "$MKL_CONF_FIND" ]; then
    echo "[+] Found package anchor: $MKL_CONF_FIND"
    MKL_DIR_COORD=$(dirname "$MKL_CONF_FIND")
    echo "[+] Extracted MKL_DIR:    $MKL_DIR_COORD"
else
    echo "[X] CRITICAL: MKLConfig.cmake completely absent from oneAPI tree!"
fi

echo -e "\n=== [ISLM PROBE] Initializing Micro-Sandbox Workspace ==="
SANDBOX_DIR="scratch/test_gen"
rm -rf "$SANDBOX_DIR"
mkdir -p "$SANDBOX_DIR"

# Construct an isolated, bare-minimum project to test the find tool
cat << 'INNER_EOF' > "$SANDBOX_DIR/CMakeLists.txt"
cmake_minimum_required(VERSION 3.13)
project(MKLProbe LANGUAGES C CXX)
message(STATUS "[SANDBOX] Running direct find_package scan...")
find_package(MKL CONFIG REQUIRED PATHS $ENV{MKLROOT})
message(STATUS "[SANDBOX] Success! Imported Targets: ${MKL_IMPORTED_TARGETS}")
INNER_EOF

echo "[*] Staged isolated mock verification project in $SANDBOX_DIR"
cd "$SANDBOX_DIR" || exit 1

echo -e "\n=== [ISLM PROBE] Launching Manual Isolated Generation Sweep ==="
M_ROOT="${MKLROOT:-/opt/intel/oneapi/mkl/latest}"

# Execute a clean, direct, un-bracketed manual generation call
MKLROOT="$M_ROOT" MKL_ROOT="$M_ROOT" cmake . \
    -DCMAKE_PREFIX_PATH="$M_ROOT" \
    -DGGML_SYCL=ON

STATUS=$?
echo -e "\n======================================================="
if [ $STATUS -eq 0 ]; then
    echo "[+] PROBE SUCCESS: Isolated CMake indexed the 2026 Math Kernels."
    echo "[+] Underlying environment is sound; makefile logic is the blocker."
else
    echo "[X] PROBE REJECTION: Isolated CMake dropped an anchor in sandbox."
    echo "[*] Inspect output streams above to trace the internal failure logic."
fi
echo "======================================================="
