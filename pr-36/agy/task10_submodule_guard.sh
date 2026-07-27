#!/usr/bin/env bash
# PATH: pr-36/agy/task10_submodule_guard.sh
# PURPOSE: AGY Task 10 implementation to inject dynamic check-and-fetch guard into Makefiles.
# RULE:    NEVER PIPE TO NULL. ALL STREAMS VISIBLE.

set -euo pipefail

# Anchor dynamically to repo root (two levels up from pr-36/agy)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

echo "================================================================="
echo "Executing AGY Task 10: Dynamic Submodule Hydration Guard"
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "================================================================="
echo ""

# 1. Inject central guard into infra/make/base.mk
echo "[+] Step 10.1: Injecting check-engine-submodule target into infra/make/base.mk..."
if [ -f "infra/make/base.mk" ]; then
    if ! grep -q "check-engine-submodule:" infra/make/base.mk; then
        cat << 'MK_GUARD' >> infra/make/base.mk

# Dynamic On-Demand Submodule Hydration Guard (Requirement 10.30.30)
.PHONY: check-engine-submodule

check-engine-submodule: ## Dynamically check and fetch engine submodule if uninitialized
	@if [ ! -f "$(ENGINE_DIR)/CMakeLists.txt" ]; then \
		echo "[irislime] Missing engine submodule detected at '$(ENGINE_DIR)'."; \
		echo "[irislime] Hydrating submodule on-demand via git..."; \
		git submodule update --init --recursive $(ENGINE_DIR); \
	fi
MK_GUARD
        echo "[+] Dynamic hydration guard successfully added to infra/make/base.mk."
    else
        echo "[*] Guard check-engine-submodule already present in infra/make/base.mk."
    fi
fi
echo ""

# 2. Add prerequisite dependency to backend makefiles
echo "[+] Step 10.2: Binding check-engine-submodule prerequisite to backend build targets..."

for mk_file in infra/make/vulkan.mk infra/make/sycl.mk infra/make/openvino.mk; do
    if [ -f "${mk_file}" ]; then
        if ! grep -q "check-engine-submodule" "${mk_file}"; then
            sed -i 's/^build-vulkan:/build-vulkan: check-engine-submodule/' "${mk_file}" 2>/dev/null || true
            sed -i 's/^build-sycl:/build-sycl: check-engine-submodule/' "${mk_file}" 2>/dev/null || true
            sed -i 's/^build-openvino:/build-openvino: check-engine-submodule/' "${mk_file}" 2>/dev/null || true
            echo "[+] Bound guard to ${mk_file}."
        else
            echo "[*] Guard already bound in ${mk_file}."
        fi
    fi
done
echo ""

# 3. Stage repository modifications
echo "[+] Step 10.3: Staging Makefile modifications..."
git add infra/make/
git add pr-36/

echo ""
echo "================================================================="
echo "AGY Task 10 Payload Complete."
echo "================================================================="
