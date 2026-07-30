#!/usr/bin/env bash
# PATH: pr-36/agy/task60_build_debug_matrix.sh
# PURPOSE: AGY Task 60 - Trigger full debug compilation pass via build runner.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

echo "================================================================="
echo "[AGY TASK 60] Launching IrisLime Compilation Pass"
echo "================================================================="
echo ""

# Executes the build pipeline (triggers build_runner.py / Makefile target)
make build

echo ""
echo "================================================================="
echo "[AGY TASK 60] Build pass finished. Checking status..."
echo "================================================================="
