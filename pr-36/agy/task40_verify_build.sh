#!/usr/bin/env bash
# PATH: pr-36/agy/task40_verify_build.sh
# PURPOSE: AGY Task 40 - Verify dynamic check-and-fetch guard during make build pass.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

echo "[AGY TASK 40] Auditing initial submodule state..."
git submodule status llama.cpp || true

echo ""
echo "[AGY TASK 40] Executing 'make build' with on-demand hydration guard active..."
make build

echo ""
echo "[AGY TASK 40] Post-build submodule hydration check:"
git submodule status llama.cpp
