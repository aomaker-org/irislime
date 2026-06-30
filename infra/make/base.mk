# ==============================================================================
# Filename:    infra/make/base.mk
# Timestamp:   20260630_0015
# Attribution: fekerr @ gemini (flash 3.5 + extended)
# Purpose:     RAM-Aware Topology Parsing & Safe Stream Filters
# ==============================================================================

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

# Forensic Memory Check (Throttles parallelism to prevent OOM swap-thrashing on templates)
TOTAL_RAM_KB  := $(shell grep MemTotal /proc/meminfo | awk '{print $$2}')
TOTAL_RAM_GB  := $(shell echo $$(( $(TOTAL_RAM_KB) / 1024 / 1024 )))
RAM_SAFE_JOBS := $(shell echo $$(( $(TOTAL_RAM_GB) / 4 )))

ifeq ($(NUM_P_THREADS),0)
  CPU_BUILD_JOBS := $(TOTAL_THREADS)
  NUM_INF_THREADS := $(shell echo $$(( $(TOTAL_THREADS) / 2 )))
else
  CPU_BUILD_JOBS := $(shell echo $$(( $(NUM_P_THREADS) + ($(NUM_E_THREADS) / 2) )))
  NUM_INF_THREADS := $(shell echo $$(( $(NUM_P_THREADS) / 2 )))
endif

# Ensure RAM constraints take precedence if memory is tight
NUM_BUILD_JOBS := $(shell if [ $(RAM_SAFE_JOBS) -lt $(CPU_BUILD_JOBS) ] && [ $(RAM_SAFE_JOBS) -gt 0 ]; then echo $(RAM_SAFE_JOBS); else echo $(CPU_BUILD_JOBS); fi)
# Enforce a hard baseline floor of at least 2 jobs to guarantee execution
ifeq ($(NUM_BUILD_JOBS),0)
  NUM_BUILD_JOBS := 2
endif

# --- SHARED CONFIGURATION MATRIX ---
ENGINE_DIR      := llama.cpp
MODELS_DIR      := models
BUILD_ROOT      := build
TIMESTAMP       := $(shell date +%Y%m%d_%H%M%S)
METRICS_FILE    := telemetry_builds.csv

ifeq ($(QUIET),1)
  INIT_STREAM   = > $(1) 2>&1
  APPEND_STREAM = >> $(1) 2>&1
else
  INIT_STREAM   = 2>&1 | tee $(1)
  APPEND_STREAM = 2>&1 | tee -a $(1)
endif

define log_telemetry
	echo "$(TIMESTAMP),$(1),$(2),$(3)" >> $(METRICS_FILE)
endef

.PHONY: verify-infra setup-venv track-workspace show-topology

show-topology:
	@echo "=================================================================="
	@echo "IrisLime Hardware & Memory Telemetry Report"
	@echo "=================================================================="
	@echo "  Total System Memory Detected       : $(TOTAL_RAM_GB) GB"
	@echo "  Memory-Safe Max Parallel Jobs      : $(RAM_SAFE_JOBS)"
	@echo "  Detected Total Logical Processors  : $(TOTAL_THREADS)"
	@echo "  Performance Core Threads Detected  : $(NUM_P_THREADS) (Physical P-Cores: $(NUM_INF_THREADS))"
	@echo "  Efficient Core Threads Detected    : $(NUM_E_THREADS)"
	@echo "------------------------------------------------------------------"
	@echo "  CALIBRATED BUILD CONCURRENCY (-j)  : $(NUM_BUILD_JOBS)"
	@echo "  CALIBRATED INFERENCE THREADS (-t)  : $(NUM_INF_THREADS)"
	@echo "=================================================================="

verify-infra:
	@if [ ! -d "infra/make" ]; then \
		echo "[!] Critical Error: Modular build directory structure missing at infra/make"; \
		exit 1; \
	fi

setup-venv: venv/.installed

venv/.installed: requirements.txt
	@echo "[+] Verifying localized python runtime environment..."
	@if [ ! -d "venv" ]; then python3 -m venv venv; fi
	@./venv/bin/pip install --upgrade pip > /dev/null
	@./venv/bin/pip install -r requirements.txt > /dev/null
	@touch venv/.installed

track-workspace:
	@echo ""
	@echo "[+] Mapping current IrisLime compilation and telemetry tree structures:"
	@if command -v tree &> /dev/null; then \
		tree -f $(BUILD_ROOT); \
	else \
		find $(BUILD_ROOT) -type f -name "*.log" -o -name "llama-cli"; \
	fi

# end of infra/make/base.mk
