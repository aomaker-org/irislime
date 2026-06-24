# Filename: Makefile
# Purpose: Research Environment Management for IrisLime
# Usage:
#   1. source config_env
#   2. make build    (Perform OOT build of engine)
#   3. make verify   (Check forensic baselines)

.PHONY: build setup scrub verify promote clean help

# --- STRICT ENVIRONMENT GUARD ---
ifndef IRISLIME_READY
  $(error [!] IrisLime environment not detected! Run 'source config_env')
endif

BUILD_DIR := ./build
ENGINE_DIR := ./llama.cpp
FILES := config_env Makefile
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)
LOG_FILE := build_$(TIMESTAMP).log

# --- TARGETS ---

# Setup: Handle python environment
setup: venv/.installed

venv/.installed: requirements.txt
	@if [ ! -d "venv" ]; then python3 -m venv venv; fi
	@./venv/bin/pip install --upgrade pip
	@./venv/bin/pip install -r requirements.txt
	@touch venv/.installed
	@echo "[+] Environment setup complete."

# Build: Out-of-Tree (OOT) build of llama.cpp using Intel oneAPI
build: setup
	@echo "--- Starting Out-of-Tree build ---"
	@echo "[+] Logging to $(LOG_FILE)"
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && \
		CC=icx CXX=icpx cmake ../../$(ENGINE_DIR) \
		-DGGML_SYCL=ON \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_CXX_COMPILER=icpx \
		-DCMAKE_C_COMPILER=icx 2>&1 | tee ../../$(LOG_FILE)
	@cd $(BUILD_DIR) && $(MAKE) -j$(shell nproc) 2>&1 | tee -a ../../$(LOG_FILE)
	@echo "[+] Build complete. Binary located at $(BUILD_DIR)/bin/"

# Forensic Pipeline (Scrub/Verify/Promote)
scrub:
	@./tools/scrub $(FILES)

verify: scrub
	@for f in $(FILES); do \
		if [ ! -f "$$f.trusted" ]; then \
			echo "[!] Missing baseline for $$f. Run 'make promote'."; \
			exit 1; \
		fi; \
		diff -q $$f.scrubbed $$f.trusted > /dev/null || \
		(echo "[!] REGRESSION: $$f differs from $$f.trusted!" && exit 1); \
	done
	@echo "[+] Verification passed."

promote: scrub
	@for f in $(FILES); do \
		cp $$f.scrubbed $$f.trusted; \
		echo "[+] Promoted $$f to trusted status."; \
	done

# Run: Example usage of the OOT binary
run-llama:
	@$(BUILD_DIR)/bin/llama-cli \
	  -m models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
	  -p "The future of AI is" \
	  -n 50

# Clean: Remove build artifacts and environment
clean:
	@rm -rf venv/ *.scrubbed $(BUILD_DIR) build.log
	@echo "[+] Build artifacts and virtualenv removed."

# Help: Display available targets
help:
	@echo "Available Targets:"
	@echo "  setup   : Install python dependencies"
	@echo "  build   : Run OOT CMake build using Intel oneAPI"
	@echo "  scrub   : Run forensic scrubbing on config files"
	@echo "  verify  : Compare against trusted baselines"
	@echo "  promote : Update trusted baselines"
	@echo "  run-llama : Run basic inference test"
	@echo "  clean   : Remove artifacts and venv"
