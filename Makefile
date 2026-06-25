# Filename: Makefile
.PHONY: build validate-build setup scrub verify promote clean help _init_logs capture-build-manifest check-disk-space

# --- STRICT ENVIRONMENT GUARD ---
ifndef IRISLIME_READY
  $(error [!] IrisLime environment not detected! Run 'source config_env')
endif

BUILD_ROOT := ./build
ENGINE_DIR := ./llama.cpp
LOG_BASE   := ./logs
BUILD_LOG_DIR := $(LOG_BASE)/build
MIN_FREE_GB ?= 40
VALIDATE ?= 1
DISK_GUARD_PATH ?= /mnt/c
COMMON_CMAKE_FLAGS := -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DGGML_BUILD_TESTS=OFF -DGGML_BUILD_EXAMPLES=OFF

# Default target
TARGET ?= default
BUILD_DIR := $(BUILD_ROOT)/$(TARGET)

# Configuration Routing
ifeq ($(TARGET), sycl_release)
	CMAKE_FLAGS := -DGGML_SYCL=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=icpx -DCMAKE_C_COMPILER=icx $(COMMON_CMAKE_FLAGS)
else ifeq ($(TARGET), sycl_relwithdebinfo)
	CMAKE_FLAGS := -DGGML_SYCL=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_CXX_COMPILER=icpx -DCMAKE_C_COMPILER=icx $(COMMON_CMAKE_FLAGS)
else ifeq ($(TARGET), sycl_debug)
	CMAKE_FLAGS := -DGGML_SYCL=ON -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_COMPILER=icpx -DCMAKE_C_COMPILER=icx $(COMMON_CMAKE_FLAGS)
else ifeq ($(TARGET), cpu_release)
	CMAKE_FLAGS := -DGGML_SYCL=OFF -DCMAKE_BUILD_TYPE=Release $(COMMON_CMAKE_FLAGS)
else ifeq ($(TARGET), cpu_relwithdebinfo)
	CMAKE_FLAGS := -DGGML_SYCL=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo $(COMMON_CMAKE_FLAGS)
else ifeq ($(TARGET), cpu_debug)
	CMAKE_FLAGS := -DGGML_SYCL=OFF -DCMAKE_BUILD_TYPE=Debug $(COMMON_CMAKE_FLAGS)
else
	CMAKE_FLAGS := -DCMAKE_BUILD_TYPE=Release $(COMMON_CMAKE_FLAGS)
endif

setup: venv/.installed

venv/.installed: requirements.txt
	@if [ ! -d "venv" ]; then python3 -m venv venv; fi
	@./venv/bin/pip install --upgrade pip
	@./venv/bin/pip install -r requirements.txt
	@touch venv/.installed
	@echo "[+] Environment setup complete."

_init_logs:
	@mkdir -p $(BUILD_LOG_DIR)

check-disk-space:
	@CHECK_PATH="$(DISK_GUARD_PATH)"; \
	if [ ! -d "$$CHECK_PATH" ]; then CHECK_PATH="."; fi; \
	FREE_GB=$$(df -BG "$$CHECK_PATH" | awk 'NR==2 { gsub("G", "", $$4); print $$4 }'); \
	if [ "$$FREE_GB" -lt "$(MIN_FREE_GB)" ]; then \
		echo "[!] Free space guard triggered on $$CHECK_PATH: $$FREE_GB GB available (< $(MIN_FREE_GB) GB threshold)."; \
		echo "[!] Pause build and clean up disk, then rerun."; \
		exit 2; \
	fi; \
	echo "[+] Free space check passed on $$CHECK_PATH: $$FREE_GB GB available (threshold: $(MIN_FREE_GB) GB)."

# Define validation logic
validate-build:
	@echo "--- Validating Build [Target: $(TARGET)] ---"
	@# Check for device visibility
	@$(BUILD_DIR)/bin/llama-cli --list-devices 2>&1 | tee -a $(LOG_FILE)
	@# Add a basic version check
	@$(BUILD_DIR)/bin/llama-cli --version >> $(LOG_FILE)

capture-build-manifest:
	@./tools/capture_build_manifest.sh "$(BUILD_DIR)" "$(TARGET)" "$(CMAKE_FLAGS)" "$(LOG_FILE)"

build: setup _init_logs check-disk-space
	$(eval TIMESTAMP := $(shell date +%Y%m%d_%H%M%S))
	$(eval LOG_FILE := $(BUILD_LOG_DIR)/$(TARGET)_$(TIMESTAMP).log)
	@echo "--- Starting build [Target: $(TARGET)] ---"
	@echo "[+] Logging to $(LOG_FILE)"
	@mkdir -p $(BUILD_DIR)
	@# Explicitly invoke bash to handle the 'time' keyword correctly
	@bash -c "time ( \
		cd $(BUILD_DIR) && \
		cmake ../../$(ENGINE_DIR) $(CMAKE_FLAGS) 2>&1 && \
		$(MAKE) -j$(shell nproc) 2>&1 \
	)" 2>&1 | tee $(LOG_FILE)
	@# (quick smoke test) Validate the build outside of the timer of the build process
	@if [ "$(VALIDATE)" = "1" ]; then \
		$(MAKE) validate-build TARGET=$(TARGET) LOG_FILE=$(LOG_FILE); \
	else \
		echo "[!] VALIDATE=0: skipping validate-build" | tee -a $(LOG_FILE); \
	fi
	@$(MAKE) capture-build-manifest TARGET=$(TARGET) LOG_FILE=$(LOG_FILE)
	@echo "[+] Build tree usage: $$(du -sh $(BUILD_DIR) 2>/dev/null | awk '{print $$1}')"
	@echo "[+] Build complete. Duration logged."

clean:
	@rm -rf $(BUILD_ROOT) venv/ *.scrubbed $(LOG_BASE)/build/*
	@echo "[+] Environment and build artifacts cleared."

help:
	@echo "Targets: setup, build, validate-build, capture-build-manifest, check-disk-space, clean, verify, promote"
	@echo "Build TARGET values: default, sycl_release, sycl_relwithdebinfo, sycl_debug, cpu_release, cpu_relwithdebinfo, cpu_debug"
	@echo "Variables: MIN_FREE_GB=$(MIN_FREE_GB), VALIDATE=$(VALIDATE), DISK_GUARD_PATH=$(DISK_GUARD_PATH)"
