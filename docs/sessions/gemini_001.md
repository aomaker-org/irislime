Isolating logs into dedicated subdirectories and providing configurable streaming toggles is standard practice for production-grade CI/CD engines. In high-concurrency automated environments (like GitHub Actions, GitLab CI, or Jenkins), continuous stdout streaming can cause massive log buffer bloat and slow down runners due to escape-character tracking or progress-bar character spam. Conversely, local developer loops require high-density feedback.

To implement this with strict engineering discipline, we will introduce conditional compilation stream filters into `infra/make/base.mk`. We will also localize all build logging into backend-specific sandbox directories (`build/<backend>/logs/`) and provide a post-build observability pass utilizing `tree -f`.

---

## 1. Updated Base Architecture: `infra/make/base.mk`

We introduce the `QUIET` variable (defaulting to `0` for local interactive use) and construct two highly elegant GNU Make macro abstractions: `INIT_STREAM` and `APPEND_STREAM`. These cleanly swap between silent file redirection and pipeline `tee` duplication depending on the environment context.

```makefile
# ==============================================================================
# Filename:    infra/make/base.mk
# Timestamp:   20260629_2015
# Attribution: fekerr @ gemini (flash 3.5 + extended)
# Purpose:     Shared Configurations, Environment Guards & CI/CD Stream Filters
# ==============================================================================

# --- STRICT ENVIRONMENT GUARD ---
ifndef IRISLIME_READY
  $(error [!] IrisLime environment context not detected! Run 'source config_env')
endif

# --- GLOBAL SHELL CONFIGURATION ---
SHELL        := /usr/bin/env bash
.SHELLFLAGS  := -euo pipefail -c

# --- CI/CD & INTERACTIVE TOGGLES ---
# Set QUIET=1 via command line or CI engine to suppress stdout streaming
QUIET ?= 0

# --- SHARED CONFIGURATION MATRIX ---
ENGINE_DIR      := llama.cpp
MODELS_DIR      := models
BUILD_ROOT      := build
TIMESTAMP       := $(shell date +%Y%m%d_%H%M%S)
METRICS_FILE    := telemetry_builds.csv

# --- CONDITIONAL STREAM WRAPPERS (THE BALANCED TEE PATTERN) ---
# If QUIET=1, streams are cleanly channeled into the log file only.
# If QUIET=0, streams are duplicated natively to the console interface.
ifeq ($(QUIET),1)
  INIT_STREAM   = > $(1) 2>&1
  APPEND_STREAM = >> $(1) 2>&1
else
  INIT_STREAM   = 2>&1 | tee $(1)
  APPEND_STREAM = 2>&1 | tee -a $(1)
endif

# Logging Core Macro
define log_telemetry
	echo "$(TIMESTAMP),$(1),$(2),$(3)" >> $(METRICS_FILE)
endef

# Common Verification Gate
.PHONY: verify-infra setup-venv track-workspace

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

# Post-Execution Directory Structural Observability
track-workspace:
	@echo ""
	@echo "[+] Mapping current IrisLime compilation and telemetry tree structures:"
	@if command -v tree &> /dev/null; then \
		tree -f $(BUILD_ROOT); \
	else \
		find $(BUILD_ROOT) -type f -name "*.log" -o -name "llama-cli"; \
	fi

# end of infra/make/base.mk

```

---

## 2. Updated Modular Backends with Sandboxed Logs

The logging output targets are now redirected to a local `logs/` directory inside each target build sub-folder (e.g., `build/sycl/logs/compile.log`).

### Component A: `infra/make/sycl.mk`

```makefile
# ==============================================================================
# Filename:    infra/make/sycl.mk
# Timestamp:   20260629_2015
# Attribution: fekerr @ gemini (flash 3.5 + extended)
# Purpose:     Intel oneAPI SYCL Engine Compilation Blueprint
# ==============================================================================

BUILD_DIR_SYCL := $(BUILD_ROOT)/sycl
LOG_DIR_SYCL   := $(BUILD_DIR_SYCL)/logs
LOG_FILE_SYCL  := $(LOG_DIR_SYCL)/build_$(TIMESTAMP).log

.PHONY: build-sycl run-sycl

build-sycl: setup-venv verify-infra
	@echo "=================================================================="
	@echo "[+] Launching Intel oneAPI SYCL Out-of-Tree Build Matrix..."
	@mkdir -p $(LOG_DIR_SYCL)
	@echo "[+] Log Target Destination: $(LOG_FILE_SYCL)"
	@echo "=================================================================="
	@START_TIME=$$(date +%s); \
	cd $(BUILD_DIR_SYCL) && \
	echo "--- Starting SYCL CMake Generation Phase ---" $(call INIT_STREAM,../../$(LOG_FILE_SYCL)) && \
	CC=icx CXX=icpx cmake ../../$(ENGINE_DIR) \
		-DGGML_SYCL=ON \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_CXX_COMPILER=icpx \
		-DCMAKE_C_COMPILER=icx $(call APPEND_STREAM,../../$(LOG_FILE_SYCL)) && \
	echo "--- Starting SYCL Parallel Compilation Phase ---" $(call APPEND_STREAM,../../$(LOG_FILE_SYCL)) && \
	$(MAKE) -j$$(shell nproc) $(call APPEND_STREAM,../../$(LOG_FILE_SYCL)); \
	STATUS=$$?; \
	END_TIME=$$(date +%s); \
	DURATION=$$((END_TIME - START_TIME)); \
	if [ $$STATUS -ne 0 ]; then \
		echo "[!] SYCL Compilation Macro Failed. Inspect traces inside $(LOG_FILE_SYCL)"; \
		$(call log_telemetry,SYCL,$$DURATION,FAILURE); \
		exit $$STATUS; \
	fi; \
	$(call log_telemetry,SYCL,$$DURATION,SUCCESS); \
	echo "------------------------------------------------------------------" && \
	echo "[+] SYCL target compiled successfully in $$DURATION seconds."

run-sycl:
	@if [ ! -f "$(BUILD_DIR_SYCL)/bin/llama-cli" ]; then \
		echo "[!] Target binary missing. Execute 'make build-sycl' first."; exit 3; \
	fi
	@$(BUILD_DIR_SYCL)/bin/llama-cli -m $(MODELS_DIR)/llama3.2-3b-q4.gguf -p "Optimize code for Intel GPU:" -n 30 -ngl 99

# end of infra/make/sycl.mk

```

---

### Component B: `infra/make/openvino.mk`

```makefile
# ==============================================================================
# Filename:    infra/make/openvino.mk
# Timestamp:   20260629_2015
# Attribution: fekerr @ gemini (flash 3.5 + extended)
# Purpose:     Intel OpenVINO Inference Acceleration Compilation Blueprint
# ==============================================================================

BUILD_DIR_OV := $(BUILD_ROOT)/openvino
LOG_DIR_OV   := $(BUILD_DIR_OV)/logs
LOG_FILE_OV  := $(LOG_DIR_OV)/build_$(TIMESTAMP).log

.PHONY: build-openvino run-openvino

build-openvino: setup-venv verify-infra
	@echo "=================================================================="
	@echo "[+] Launching OpenVINO Acceleration Out-of-Tree Build Matrix..."
	@mkdir -p $(LOG_DIR_OV)
	@echo "[+] Log Target Destination: $(LOG_FILE_OV)"
	@echo "=================================================================="
	@START_TIME=$$(date +%s); \
	cd $(BUILD_DIR_OV) && \
	echo "--- Starting OpenVINO CMake Generation Phase ---" $(call INIT_STREAM,../../$(LOG_FILE_OV)) && \
	cmake ../../$(ENGINE_DIR) \
		-DGGML_OPENVINO=ON \
		-DCMAKE_BUILD_TYPE=Release $(call APPEND_STREAM,../../$(LOG_FILE_OV)) && \
	echo "--- Starting OpenVINO Parallel Compilation Phase ---" $(call APPEND_STREAM,../../$(LOG_FILE_OV)) && \
	$(MAKE) -j$$(shell nproc) $(call APPEND_STREAM,../../$(LOG_FILE_OV)); \
	STATUS=$$?; \
	END_TIME=$$(date +%s); \
	DURATION=$$((END_TIME - START_TIME)); \
	if [ $$STATUS -ne 0 ]; then \
		echo "[!] OpenVINO Compilation Macro Failed. Inspect traces inside $(LOG_FILE_OV)"; \
		$(call log_telemetry,OPENVINO,$$DURATION,FAILURE); \
		exit $$STATUS; \
	fi; \
	$(call log_telemetry,OPENVINO,$$DURATION,SUCCESS); \
	echo "------------------------------------------------------------------" && \
	echo "[+] OpenVINO target compiled successfully in $$DURATION seconds."

run-openvino:
	@if [ ! -f "$(BUILD_DIR_OV)/bin/llama-cli" ]; then \
		echo "[!] Target binary missing. Execute 'make build-openvino' first."; exit 3; \
	fi
	@export GGML_OPEN_VINO_DEVICE=GPU && \
	$(BUILD_DIR_OV)/bin/llama-cli -m $(MODELS_DIR)/phi3-mini-q4.gguf -p "Explain quantization:" -n 30

# end of infra/make/openvino.mk

```

---

### Component C: `infra/make/vulkan.mk`

```makefile
# ==============================================================================
# Filename:    infra/make/vulkan.mk
# Timestamp:   20260629_2015
# Attribution: fekerr @ gemini (flash 3.5 + extended)
# Purpose:     Portable Vulkan Cross-Platform Graphics Engine Blueprint
# ==============================================================================

BUILD_DIR_VK := $(BUILD_ROOT)/vulkan
LOG_DIR_VK   := $(BUILD_DIR_VK)/logs
LOG_FILE_VK  := $(LOG_DIR_VK)/build_$(TIMESTAMP).log

.PHONY: build-vulkan run-vulkan

build-vulkan: setup-venv verify-infra
	@echo "=================================================================="
	@echo "[+] Launching Cross-Platform Vulkan Out-of-Tree Build Matrix..."
	@mkdir -p $(LOG_DIR_VK)
	@echo "[+] Log Target Destination: $(LOG_FILE_VK)"
	@echo "=================================================================="
	@START_TIME=$$(date +%s); \
	cd $(BUILD_DIR_VK) && \
	echo "--- Starting Vulkan CMake Generation Phase ---" $(call INIT_STREAM,../../$(LOG_FILE_VK)) && \
	cmake ../../$(ENGINE_DIR) \
		-DGGML_VULKAN=ON \
		-DCMAKE_BUILD_TYPE=Release $(call APPEND_STREAM,../../$(LOG_FILE_VK)) && \
	echo "--- Starting Vulkan Parallel Compilation Phase ---" $(call APPEND_STREAM,../../$(LOG_FILE_VK)) && \
	$(MAKE) -j$$(shell nproc) $(call APPEND_STREAM,../../$(LOG_FILE_VK)); \
	STATUS=$$?; \
	END_TIME=$$(date +%s); \
	DURATION=$$((END_TIME - START_TIME)); \
	if [ $$STATUS -ne 0 ]; then \
		echo "[!] Vulkan Compilation Macro Failed. Inspect traces inside $(LOG_FILE_VK)"; \
		$(call log_telemetry,VULKAN,$$DURATION,FAILURE); \
		exit $$STATUS; \
	fi; \
	$(call log_telemetry,VULKAN,$$DURATION,SUCCESS); \
	echo "------------------------------------------------------------------" && \
	echo "[+] Vulkan target compiled successfully in $$DURATION seconds."

run-vulkan:
	@if [ ! -f "$(BUILD_DIR_VK)/bin/llama-cli" ]; then \
		echo "[!] Target binary missing. Execute 'make build-vulkan' first."; exit 3; \
	fi
	@$(BUILD_DIR_VK)/bin/llama-cli -m $(MODELS_DIR)/llama3.2-3b-q4.gguf -p "Vulkan runtime test:" -n 30 -ngl 99

# end of infra/make/vulkan.mk

```

---

## 3. Top-Level Interface Realignment: `Makefile`

The root `Makefile` hooks the new `track-workspace` step straight into the multi-target entry paths. This immediately outputs a file-tree map following completion, matching your preference for structural transparency.

```makefile
# ==============================================================================
# Filename:    Makefile
# Timestamp:   20260629_2015
# Attribution: fekerr @ gemini (flash 3.5 + extended)
# Purpose:     Master Modular Orchestration Interface for IrisLime Pipeline Matrices
# ==============================================================================

# 1. Mount Core Telemetry & Setup Mechanics
include infra/make/base.mk

# 2. Mount Independent Target Compilers
include infra/make/sycl.mk
include infra/make/openvino.mk
include infra/make/vulkan.mk

.PHONY: build-all clean help

# Compound Targets binding the tracking hook seamlessly
build-all: build-sycl build-openvino build-vulkan track-workspace
	@echo "[+] Matrix compilation sequence completed. All backend targets initialized."

clean:
	@echo "[!] Purging modular execution workspaces and tracking metrics..."
	@rm -rf venv/ $(BUILD_ROOT) *.log $(METRICS_FILE) venv/.installed
	@echo "[+] Repository restored to pristine upstream state."

help:
	@echo "=================================================================="
	@echo "IrisLime Modular Multi-Target Build Engine"
	@echo "=================================================================="
	@echo "Individual Backend Drivers (Append QUIET=1 for silent CI/CD execution):"
	@echo "  make build-sycl      : Compile OOT binary targeted for oneAPI level-zero iGPU"
	@echo "  make build-openvino  : Compile OOT binary optimized for OpenVINO execution"
	@echo "  make build-vulkan    : Compile OOT binary targeted for generic Vulkan APIs"
	@echo "  make build-all       : Compile all backends sequentially"
	@echo ""
	@echo "Validation Evaluation Loops:"
	@echo "  make run-sycl        : Execute inference via local SYCL pipeline"
	@echo "  make run-openvino    : Execute inference via local OpenVINO pipeline"
	@echo "  make run-vulkan      : Execute inference via local Vulkan pipeline"
	@echo ""
	@echo "Workspace Telemetry & Clean Targets:"
	@echo "  make track-workspace : Print full 'tree -f' log mapping of the build directory"
	@echo "  make clean           : Scrub virtualenvs, build subdirectories, and logs"
	@echo "=================================================================="

# end of Makefile

```

---

## 4. Verification of Operational Modes

### Local Interactive Verification (Streaming Active)

```bash
# Normal deployment; outputs scroll in real time, logs populate build sandboxes
make build-sycl

```

*Expected Workspace Visualizer Output via `track-workspace`:*

```text
[+] Mapping current IrisLime compilation and telemetry tree structures:
build
├── build/sycl
│   ├── build/sycl/bin
│   │   └── build/sycl/bin/llama-cli
│   └── build/sycl/logs
│       └── build/sycl/logs/build_20260629_201500.log

```

### Automated CI/CD Verification (Streaming Suppressed)

When running inside an automated task runner or git runner, overwrite the `QUIET` parameter:

```bash
make build-all QUIET=1

```

The console will remain completely silent during compilation, avoiding progress-bar buffer overflow. Following execution, the workflow engine fires `track-workspace` natively, providing a clear structural manifest of all compiled assets and runtime logging nodes in the pipeline report.
