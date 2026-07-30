#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

echo "[+] Restoring clean infra/make/base.mk from git index..."
git checkout HEAD -- infra/make/base.mk

# Ensure check-engine-submodule target exists in base.mk
if ! grep -q "check-engine-submodule:" infra/make/base.mk; then
    echo "[+] Injecting check-engine-submodule target into base.mk..."
    cat << 'SUBMOD' >> infra/make/base.mk

.PHONY: check-engine-submodule

ENGINE_DIR ?= llama.cpp

check-engine-submodule: ## Dynamically check and fetch engine submodule if uninitialized
	@if [ ! -f "$(ENGINE_DIR)/CMakeLists.txt" ]; then \
		echo "[irislime] Missing engine submodule detected at '$(ENGINE_DIR)'."; \
		echo "[irislime] Hydrating submodule on-demand via git..."; \
		git submodule update --init --recursive $(ENGINE_DIR); \
	fi
SUBMOD
fi

git add infra/make/base.mk
echo "[+] base.mk cleanly restored and verified."
