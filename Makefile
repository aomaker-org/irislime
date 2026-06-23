# Filename: Makefile
# Purpose: Formal Verification Pipeline for IrisLime
# Usage:
#   1. source config_env
#   2. make setup
#   3. make verify  (Check for regressions)
#   4. make build   (Run the orchestrator)
.PHONY: build setup scrub verify promote clean help run-llama

# --- STRICT ENVIRONMENT GUARD ---
# Stop execution if environment is not sourced
ifndef IRISLIME_READY
  $(error [!] IrisLime environment not detected! Run 'source config_env')
endif

# Files targeted for scrub/trust
FILES = config_env Makefile
INSTALLED = venv/.installed

# Default model configuration
REPO ?= bartowski/Llama-3.2-1B-Instruct-GGUF
FILE ?= Llama-3.2-1B-Instruct-Q4_K_M.gguf

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
	@echo "--- Starting build ---"
	@./venv/bin/python3 config_env.py

run-llama:
	./llama.cpp/build/bin/llama-cli \
	  -m models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
	  -p "The future of AI is" \
	  -n 50

clean:
	@rm -rf venv/ *.scrubbed
	@echo "[+] Clean complete."

help:
	@echo "Targets: setup, scrub, verify, promote, build, clean"

get-model:
	mkdir -p models
	wget -q https://huggingface.co/$(REPO)/resolve/main/$(FILE) -O models/$(FILE)
