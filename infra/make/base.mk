# ==============================================================================
# Filename:    infra/make/base.mk
# Purpose:     RAM-Aware Topology Parsing & Safe Toolchain Pre-flight Sanity Check
# Type:        Makefile Component Include
# Attribution: fekerr & Gemini (20260702_0915 / flash 3.5 extended)
# ==============================================================================

# Strict Environment Guard Interlock
ifndef IRISLIME_READY
  $(error [!] IrisLime environment context not detected! Run 'source config_env')
endif

# --- GLOBAL SHELL CONFIGURATION ---
SHELL        := /usr/bin/env bash
.SHELLFLAGS  := -euo pipefail -c

QUIET ?= 0

# --- HARDWARE TOPOLOGY & MEMORY PARSER ---
TOTAL_THREADS := $(shell nproc)
NUM_P_THREADS := $(shell grep -l ',' /sys/devices/system/cpu/cpu*/topology/thread_siblings_list 2>/dev/null | wc -l)
NUM_E_THREADS := $(shell grep -L ',' /sys/devices/system/cpu/cpu*/topology/thread_siblings_list 2>/dev/null | wc -l)

# Forensic Memory Check (Throttles parallelism to prevent OOM swap-thrashing)
TOTAL_RAM_KB  := $(shell grep MemTotal /proc/meminfo | awk '{print $$2}')
TOTAL_RAM_GB  := $(shell echo $$(( $(TOTAL_RAM_KB) / 1024 / 1024 )))
RAM_SAFE_JOBS := $(shell echo $$(( $(TOTAL_RAM_GB) / 4 )))

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
	@echo "  Memory-Safe Max Parallel Jobs      : $(RAM_SAFE_JOBS)"
	@echo "  Detected Total Logical Processors  : $(TOTAL_THREADS)"
	@echo "  Performance Core Threads Detected  : $(NUM_P_THREADS) (Physical P-Cores: $(NUM_INF_THREADS))"
	@echo "  Efficient Core Threads Detected    : $(NUM_E_THREADS)"
	@echo "------------------------------------------------------------------"
	@echo "  CALIBRATED CONCURRENCY CAPACITY   : $(CALIBRATED_BUILD_JOBS)"
	@echo "  ACTIVE RUNNER CONCURRENCY VALUE    : $(NUM_BUILD_JOBS)"
	@echo "  CALIBRATED INFERENCE THREADS (-t)  : $(NUM_INF_THREADS)"
	@echo "=================================================================="

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
	@if command -v tree &> /dev/null; then \
		tree -f $(BUILD_DIR); \
	else \
		find $(BUILD_DIR) -type f -name "*.log" -o -name "llama-cli"; \
	fi
