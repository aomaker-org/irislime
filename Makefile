# Filename: Makefile
# Purpose: Formal Verification Pipeline for IrisLime
# Usage:
#   1. source config_env
#   2. make setup
#   3. make verify  (Check for regressions)
#   4. make build   (Run the orchestrator)
#   5. make debug-llama (Launch with GDB and environment bypasses)

.PHONY: build setup scrub verify promote clean help run-llama debug-llama

# --- CONFIGURATION ---
# Define the build directory for the binary
BUILD_DIR := llama.cpp/build_iris
# Environment flags to prevent SYCL/LevelZero segfaults
SYCL_DEBUG_FLAGS := ZET_ENABLE_API_TRACING_LAYER=0 ZET_ENABLE_PROGRAM_INSTRUMENTATION=0

# --- STRICT ENVIRONMENT GUARD ---
# Stop execution if environment is not sourced
ifndef IRISLIME_READY
  $(error [!] IrisLime environment not detected! Run 'source config_env')
endif

# Files targeted for scrub/trust
FILES = config_env Makefile
INSTALLED = venv/.installed

# --- TARGETS ---

# Setup: Install/update dependencies only if needed
setup: $(INSTALLED)

$(INSTALLED): requirements.txt
	@if [ ! -d "venv" ]; then python3 -m venv venv; fi
	@./venv/bin/pip install --upgrade pip
	@./venv/bin/pip install -r requirements.txt
	@touch $(INSTALLED)
	@echo "[+] Environment setup complete."

# Scrub: Generate ephemeral .scrubbed files for inspection
scrub:
	@./tools/scrub $(FILES)

# Verify: Check if current scrubbed output matches the 'Trusted' baseline
verify: scrub
	@for f in $(FILES); do \
		if [ ! -f "$$f.trusted" ]; then \
			echo "[!] Missing baseline for $$f. Run 'make promote' to establish one."; \
			exit 1; \
		fi; \
		diff -q $$f.scrubbed $$f.trusted > /dev/null || \
		(echo "[!] REGRESSION: $$f scrubbed output differs from $$f.trusted!" && exit 1); \
	done
	@echo "[+] Verification passed: All scrubbed files match trusted baselines."

# Promote: Update the Trusted baseline from the current Scrubbed version
promote: scrub
	@for f in $(FILES); do \
		cp $$f.scrubbed $$f.trusted; \
		echo "[+] Promoted $$f to trusted status."; \
	done

# Build: Run the orchestrator
build: setup
	@echo "--- Starting build in $(BUILD_DIR) ---"
	@./venv/bin/python3 config_env.py --build-dir $(BUILD_DIR)

# Run-Llama: Run inference using the defined build directory
run-llama:
	@if [ ! -d "$(BUILD_DIR)" ]; then \
		echo "[!] Error: Build directory '$(BUILD_DIR)' not found."; \
		exit 1; \
	fi
	$(SYCL_DEBUG_FLAGS) ./$(BUILD_DIR)/bin/llama-cli \
	  -m ../models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
	  -p "The future of AI is" \
	  -n 50 \
	  --device sycl:0

# Debug-Llama: Launch the binary via GDB with required environment bypasses
debug-llama:
	@if [ ! -d "$(BUILD_DIR)" ]; then \
		echo "[!] Error: Build directory '$(BUILD_DIR)' not found."; \
		exit 1; \
	fi
	$(SYCL_DEBUG_FLAGS) gdb -iex "set auto-load safe-path /" \
	  --args ./$(BUILD_DIR)/bin/llama-cli \
	  -m ../models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
	  -p "The future of AI is" \
	  -n 50 \
	  --device sycl:0

clean:
	@rm -rf venv/ *.scrubbed
	@echo "[+] Clean complete."

help:
	@echo "Targets: setup, scrub, verify, promote, build, clean, run-llama, debug-llama"
