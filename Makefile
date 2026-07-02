# ==============================================================================
# Filename:    Makefile
# Purpose:     Top-Level Stateless Router for IrisLime Project Matrices
# Attribution: fekerr @ gemini (20260701_1038 flash 3.5 + extended)
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

.PHONY: all help clean distclean

all: help

help:
	@echo "IrisLime Master Matrix Automation Interface"
	@echo "Usage:"
	@echo "  make build-<backend> [BUILD_DIR=path] [NUM_BUILD_JOBS=N] [CMAKE_BUILD_TYPE=type]"
	@echo "Targets:"
	@echo "  build-openvino  - Compile OpenVINO acceleration target"
	@echo "  build-sycl      - Compile Intel oneAPI SYCL target"
	@echo "  build-vulkan    - Compile Mesa Vulkan compute target"
	@echo "  clean           - Purge assets within designated BUILD_DIR target"
	@echo "  distclean       - Run deep toolchain purge sequence via tools script"

# 3. Pull in the dynamic backend build recipes natively
include infra/make/openvino.mk
include infra/make/sycl.mk
include infra/make/vulkan.mk

# 4. Global Maintenance Redirections
clean:
	@echo "[Clean] Clearing target: $(BUILD_DIR)"
	rm -rf $(BUILD_DIR)

distclean:
	@if [ -f "tools/distclean.py" ]; then \
		python3 tools/distclean.py; \
	else \
		echo "[!] Fallback: Cleaning workspace build roots manually..."; \
		rm -rf build/* logs/builds/*; \
	fi

# end of Makefile
