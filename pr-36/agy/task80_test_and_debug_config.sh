#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

echo "================================================================="
echo "[AGY TASK 80] Executing Test Sweep & Configuring Debug Matrix"
echo "================================================================="

# 1. Run tests across existing build directories
run_build_tests() {
    local target_dir="$1"
    local name="$2"

    echo "-----------------------------------------------------------------"
    echo "[AGY TASK 80] Running Test Suite inside: ${target_dir} (${name})"
    echo "-----------------------------------------------------------------"

    if [ -d "${target_dir}" ]; then
        cd "${target_dir}"
        if [ -f "CTestTestfile.cmake" ] || [ -f "Makefile" ]; then
            ctest --output-on-failure --parallel 4 || echo "[!] Test failures encountered in ${name} (captured for report)."
        else
            echo "[i] No test definitions (CTestTestfile.cmake) found in ${target_dir}. Skipping binary tests."
        fi
        cd "${PROJECT_ROOT}"
    else
        echo "[!] Directory ${target_dir} does not exist."
    fi
}

run_build_tests "build/vulkan_debug" "Vulkan Debug"
run_build_tests "build/sycl_relwithdebinfo" "SYCL RelWithDebInfo"
run_build_tests "build/openvino_relwithdebinfo" "OpenVINO RelWithDebInfo"

# 2. Stage new debug build flags configuration script for upcoming tasks
echo "-----------------------------------------------------------------"
echo "[AGY TASK 80] Staging Strict Debug/Warning matrix rules for next build..."
echo "-----------------------------------------------------------------"

cat << 'MATRIX_CFG' > pr-36/strict_debug_env.sh
export CMAKE_BUILD_TYPE=Debug
export EXTRA_CFLAGS="-Wall -Wextra -Wpedantic"
export EXTRA_CXXFLAGS="-Wall -Wextra -Wpedantic"
export ENABLE_TELEMETRY=ON
MATRIX_CFG

chmod +x pr-36/strict_debug_env.sh
git add pr-36/strict_debug_env.sh

echo "[+] Task 80 execution complete. Existing builds preserved."
