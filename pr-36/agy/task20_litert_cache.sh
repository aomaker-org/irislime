#!/usr/bin/env bash
# PATH: pr-36/agy/task20_litert_cache.sh
# PURPOSE: AGY Task 20 - Parameterize Bazel cache output base in infra/make/litert.mk

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

echo "[AGY TASK 20] Parameterizing Bazel output_base in infra/make/litert.mk..."

if [ -f "infra/make/litert.mk" ]; then
    sed -i 's|--output_base="$(HOME)/.cache/bazel_irislime"|--output_base="${IRISLIME_CACHE_DIR:-$(HOME)/.cache/bazel_irislime}"|g' infra/make/litert.mk
    echo "[+] Successfully parameterized Bazel cache output base in infra/make/litert.mk."
else
    echo "[!] Error: infra/make/litert.mk not found."
fi

git add infra/make/litert.mk
