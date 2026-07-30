# ==============================================================================
# Filename:     infra/make/base.mk
# Purpose:      RAM-Aware Topology Parsing & Safe Toolchain Pre-flight Sanity Check
# Type:         Makefile Component Include
# Attribution:  fekerr & Gemini (20260704_1710 / Cross-Platform Pass)
# ==============================================================================

# Inclusion Guard

ifndef BASE_MK_INCLUDED
BASE_MK_INCLUDED := 1

# Strict Environment Guard Interlock
ifndef IRISLIME_READY
  $(error [!] IrisLime environment context not detected! Run 'source config_win11' or 'source config_env')
endif

# --- ANSI TERMINAL COLOR PALETTE ---
# Shared across the entire Makefile hierarchy
COLOR_RESET   := \033[0m
COLOR_BOLD    := \033[1m
COLOR_CYAN    := \033[36m
COLOR_GREEN   := \033[32m
COLOR_YELLOW  := \033[33m
COLOR_RED     := \033[31m
COLOR_BLUE    := \033[34m
COLOR_MAGENTA := \033[35m

CYAN  := $(COLOR_CYAN)
RESET := $(COLOR_RESET)

# --- GLOBAL SHELL CONFIGURATION ---
SHELL        := bash
.SHELLFLAGS  := -euo pipefail -c

QUIET ?= 0

# --- HARDWARE TOPOLOGY & MEMORY PARSER ---
TOTAL_THREADS := $(shell nproc || echo 4)
NUM_P_THREADS := $(shell grep -l ',' /sys/devices/system/cpu/cpu*/topology/thread_siblings_list | wc -l)
NUM_E_THREADS := $(shell grep -L ',' /sys/devices/system/cpu/cpu*/topology/thread_siblings_list | wc -l)

# Forensic Memory Check
TOTAL_RAM_GB  := $(shell grep MemTotal /proc/meminfo | awk '{print int($$2/1024/1024)}')
ifeq ($(TOTAL_RAM_GB),)
  TOTAL_RAM_GB := 16
endif
RAM_SAFE_JOBS := $(shell echo $$(( $(TOTAL_RAM_GB) / 4 )))

# --- WINDOWS HOST & LOCAL DISK SPACE PROBE ---
WIN_HOST_FREE_GB  := $(shell df -BG /mnt/c | awk 'NR==2 {print $$4}' | tr -d 'G')
MIN_DISK_FLOOR_GB := 10

# Calculate CPU Build Capacity and Physical Inference Cores
ifeq ($(NUM_P_THREADS),0)
  CALIBRATED_CPU_JOBS := $(TOTAL_THREADS)
  NUM_INF_THREADS     := $(shell echo $$(( $(TOTAL_THREADS) / 2 )))
else
  CALIBRATED_CPU_JOBS := $(shell echo $$(( $(NUM_P_THREADS) + ($(NUM_E_THREADS) / 2) )))
  NUM_INF_THREADS     := $(shell echo $$(( $(NUM_P_THREADS) / 2 )))
endif

# Ensure RAM constraints take precedence if memory space is tight
CALIBRATED_BUILD_JOBS := $(shell if [ $(RAM_SAFE_JOBS) -lt $(CALIBRATED_CPU_JOBS) ] && [ $(RAM_SAFE_JOBS) -gt 0 ]; then echo $(RAM_SAFE_JOBS); else echo $(CALIBRATED_CPU_JOBS); fi)

ifeq ($(CALIBRATED_BUILD_JOBS),0)
  CALIBRATED_BUILD_JOBS := 2
endif

# --- VARIABLE INTERPOLATION GATES ---
NUM_BUILD_JOBS ?= $(CALIBRATED_BUILD_JOBS)

# --- SHARED CONFIGURATION MATRIX ---
ENGINE_DIR    := llama.cpp
BUILD_ROOT    := build
TIMESTAMP     := $(shell date +%Y%m%d_%H%M%S)
METRICS_FILE  := telemetry_builds.csv

define log_telemetry
	echo "$(TIMESTAMP),$(1),$(2),$(3)" >> $(METRICS_FILE)
endef

.PHONY: verify-infra setup-venv track-workspace show-topology

show-topology: ## Audit and display host platform core topologies and memory boundaries
	@echo "=================================================================="
	@echo "IrisLime Hardware & Memory Telemetry Report"
	@echo "=================================================================="
	@echo "  Total System Memory Detected       : $(TOTAL_RAM_GB) GB"
	@if [ -n "$(WIN_HOST_FREE_GB)" ]; then \
		echo "  Windows Host Free Space (/mnt/c)   : $(WIN_HOST_FREE_GB) GB"; \
	fi
	@echo "  Memory-Safe Max Parallel Jobs      : $(RAM_SAFE_JOBS)"
	@echo "  Detected Total Logical Processors  : $(TOTAL_THREADS)"
	@echo "  Performance Core Threads Detected  : $(NUM_P_THREADS) (Physical P-Cores: $(NUM_INF_THREADS))"
	@echo "  Efficient Core Threads Detected    : $(NUM_E_THREADS)"
	@echo "------------------------------------------------------------------"
	@echo "  CALIBRATED CONCURRENCY CAPACITY    : $(CALIBRATED_BUILD_JOBS)"
	@echo "  ACTIVE RUNNER CONCURRENCY VALUE    : $(NUM_BUILD_JOBS)"
	@echo "  CALIBRATED INFERENCE THREADS (-t)  : $(NUM_INF_THREADS)"
	@echo "=================================================================="
	@if [ -n "$(WIN_HOST_FREE_GB)" ] && [ "$(WIN_HOST_FREE_GB)" -lt "$(MIN_DISK_FLOOR_GB)" ]; then \
		echo "[!] WARNING: Windows host partition (/mnt/c) has only $(WIN_HOST_FREE_GB) GB free (Floor: $(MIN_DISK_FLOOR_GB) GB)."; \
		echo "[!] Large compilation targets or submodule fetches may fail unexpectedly!"; \
	fi

verify-infra: ## Validate internal modular build folder workspace directory structures
	@if [ ! -d "infra/make" ]; then \
		echo "[!] Critical Error: Modular build directory structure missing at infra/make"; \
		exit 1; \
	fi

setup-venv: .venv/.installed ## Provision and auto-sync localized python dependencies via uv

.venv/.installed: pyproject.toml uv.lock
	@echo "[+] Aligning local python runtime dependencies via uv sync..."
	@if [ ! -d ".venv" ]; then uv venv .venv; fi
	@uv sync
	@touch .venv/.installed

track-workspace: ## List active binary assets and log configurations inside active build folders
	@echo ""
	@echo "[+] Mapping current IrisLime variant tree structure for: $(BUILD_DIR)"
	@if command -v tree; then \
		tree -f $(BUILD_DIR); \
	else \
		find $(BUILD_DIR) -type f -name "*.log" -o -name "llama-cli"; \
	fi

.PHONY: build-base clean-base

build-base: verify-infra setup-venv
	@PROFILE_VAL="$${PROFILE:-$${CMAKE_BUILD_TYPE:-Release}}"; \
	PROFILE_LOWER=$$(echo "$$PROFILE_VAL" | tr '[:upper:]' '[:lower:]'); \
	TARGET_DIR="build/base_$$PROFILE_LOWER"; \
	echo "[Make] Initializing Base CPU compilation inside: $$TARGET_DIR"; \
	mkdir -p "$$TARGET_DIR"; \
	if [ ! -f "$$TARGET_DIR/CMakeCache.txt" ]; then \
		cmake -B "$$TARGET_DIR" -S $(ENGINE_DIR) \
			-DCMAKE_BUILD_TYPE="$$PROFILE_VAL" \
			-DGGML_EXCEPTIONS=ON \
			-DLLAMA_BUILD_TESTS=ON \
			-DCMAKE_C_COMPILER_LAUNCHER=ccache \
			-DCMAKE_CXX_COMPILER_LAUNCHER=ccache; \
	fi; \
	cmake --build "$$TARGET_DIR" -j$(NUM_BUILD_JOBS)

clean-base:
	@echo "[Clean] Removing build/base_* directories"
	rm -rf build/base_*

.PHONY: check-engine-submodule

ENGINE_DIR ?= llama.cpp

check-engine-submodule: ## Dynamically check and fetch engine submodule if uninitialized
	@if [ ! -f "$(ENGINE_DIR)/CMakeLists.txt" ]; then \
		echo "[irislime] Missing engine submodule detected at '$(ENGINE_DIR)'."; \
		echo "[irislime] Hydrating submodule on-demand via git..."; \
		git submodule update --init --recursive $(ENGINE_DIR); \
	fi

endif # BASE_MK_INCLUDED

# End of base.mk
