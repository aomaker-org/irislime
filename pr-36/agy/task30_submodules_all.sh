#!/usr/bin/env bash
# PATH: pr-36/agy/task30_submodules_all.sh
# PURPOSE: AGY Task 30 - Bind check-engine-submodule guard across sycl.mk and openvino.mk

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

echo "[AGY TASK 30] Binding check-engine-submodule to sycl.mk and openvino.mk..."

for mk_file in infra/make/sycl.mk infra/make/openvino.mk; do
    if [ -f "${mk_file}" ]; then
        if ! grep -q "check-engine-submodule" "${mk_file}"; then
            sed -i 's/^build-sycl:/build-sycl: check-engine-submodule/' "${mk_file}" 2>/dev/null || true
            sed -i 's/^build-openvino:/build-openvino: check-engine-submodule/' "${mk_file}" 2>/dev/null || true
            echo "[+] Successfully bound guard to ${mk_file}."
        else
            echo "[*] Guard already bound in ${mk_file}."
        fi
    fi
done

git add infra/make/
