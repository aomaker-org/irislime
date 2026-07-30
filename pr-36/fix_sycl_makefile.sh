#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

# Inject include guard for base.mk into infra/make/sycl.mk if missing
if ! grep -q "base.mk" infra/make/sycl.mk 2>/dev/null; then
    echo "[+] Injecting base.mk inclusion into infra/make/sycl.mk"
    sed -i '1s|^|-include infra/make/base.mk\n|' infra/make/sycl.mk
fi

git add infra/make/sycl.mk
echo "[+] SYCL Makefile dependency resolved."
