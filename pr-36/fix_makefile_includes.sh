#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

echo "[+] Correcting Makefile include paths across infra/make/..."

# Fix sycl.mk
if [ -f "infra/make/sycl.mk" ]; then
    sed -i '/base.mk/d' infra/make/sycl.mk
    sed -i '1s|^|include infra/make/base.mk\n|' infra/make/sycl.mk
fi

# Fix openvino.mk
if [ -f "infra/make/openvino.mk" ]; then
    sed -i '/base.mk/d' infra/make/openvino.mk
    sed -i '1s|^|include infra/make/base.mk\n|' infra/make/openvino.mk
fi

git add infra/make/sycl.mk infra/make/openvino.mk
echo "[+] Makefile includes updated with strict resolution."
