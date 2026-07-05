# ==============================================================================
# Filename:     Makefile
# Purpose:      Top-Level Stateless Router for IrisLime Project Matrices
# Attribution:  fekerr & Gemini (20260704_1705 / Optimization Pass)
# ==============================================================================

# 1. Enforce Core Environment Guard Rails and Hardware Topologies
include infra/make/base.mk

# 2. Workspace Execution Parameter Defaults
BUILD_DIR        ?= build/openvino_relwithdebinfo
NUM_BUILD_JOBS   ?= 1
CMAKE_BUILD_TYPE ?= RelWithDebInfo
ENGINE_DIR       := llama.cpp
LOG_FILE_PATH    ?= $(CURDIR)/$(BUILD_DIR)/logs/build_default.log

export ENGINE_DIR NUM_BUILD_JOBS CMAKE_BUILD_TYPE LOG_FILE_PATH

.PHONY: all help clean distclean build test

all: help

build: ## Run Python-driven isolated hardware compilation matrices automatically (uv proxy)
	uv run tools/build_runner.py

test: ## Execute localized Small Language Model verification loops across active hardware
	uv run tools/test_runner.py

help: ## Parse and display all available interface targets dynamically from modules
	@echo "=================================================================="
	@echo " IrisLime Master Matrix Build & Automation Interface"
	@echo "=================================================================="
	@echo ""
	@echo "Unified Proxy Targets (Preferred Cross-Platform Control):"
	@echo "  \033[36mmake build\033[0m            -> Shunts execution to uv run tools/build_runner.py"
	@echo "  \033[36mmake test\033[0m             -> Shunts execution to uv run tools/test_runner.py"
	@echo ""
	@echo "Legacy / Direct Subsystem Makefile Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@echo "=================================================================="

# 3. Pull in the dynamic backend build recipes natively
include infra/make/openvino.mk
include infra/make/sycl.mk
include infra/make/vulkan.mk
include infra/make/litert.mk

# 4. Global Maintenance Redirections
clean: ## Purge assets within designated active BUILD_DIR target space
	@echo "[Clean] Clearing target: $(BUILD_DIR)"
	rm -rf $(BUILD_DIR)

distclean: ## Run deep sandbox toolchain environment purge sequence via python
	@if [ -f "tools/distclean.py" ]; then \
		uv run tools/distclean.py; \
	else \
		echo "[!] Fallback: Cleaning workspace build roots manually..."; \
		rm -rf build/* logs/builds/*; \
	fi

# end of Makefile
