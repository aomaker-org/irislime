# ==============================================================================
# Filename:     infra/make/litert.mk
# Purpose:      Resource-Gated Bazel Orchestration Wrapper for LiteRT Submodule
# Target:       Intel Iris Xe Framework Compliant Target Infrastructure
# Attribution:  fekerr & Gemini (20260704_1720 / Cross-Platform Pass)
# ==============================================================================

LITERT_SRC      ?= deps/litert-lm

.PHONY: litert-all litert-debug litert-clone litert-clean

litert-all: ## Step-through: Verify and compile native LiteRT-LM in Release mode
	@$(MAKE) litert-clone
	@echo "[+] Delegating optimized Release execution to throttled Bazel subsystem..."
	@bash tools/bazel_gated_build.sh release
	@echo "[+] LiteRT-LM Release Build Phase: SUCCESS"

litert-debug: ## Step-through: Verify and compile native LiteRT-LM in Debug mode
	@$(MAKE) litert-clone
	@echo "[+] Delegating heavy-symbol Debug execution to throttled Bazel subsystem..."
	@bash tools/bazel_gated_build.sh debug
	@echo "[+] LiteRT-LM Debug Build Phase: SUCCESS"

litert-clone:
	@if [ ! -f "$(LITERT_SRC)/WORKSPACE" ] && [ ! -f "$(LITERT_SRC)/MODULE.bazel" ]; then \
		echo "[!] Error: LiteRT-LM fork submodule is missing or uninitialized."; \
		exit 1; \
	fi

litert-clean: ## Clear staging directories and invoke contextual out-of-tree Bazel expunge
	@echo "[-] Clearing down local LiteRT build folders..."
	rm -rf build/litert_release build/litert_debug
	@if command -v bazel &> /dev/null && [ -d "$(LITERT_SRC)" ] && { [ -f "$(LITERT_SRC)/WORKSPACE" ] || [ -f "$(LITERT_SRC)/MODULE.bazel" ]; }; then \
		echo "[-] Context shift: Entering workspace at $(LITERT_SRC) for cache expunge..."; \
		cd $(LITERT_SRC) && bazel --output_base="$(HOME)/.cache/bazel_irislime" clean --expunge; \
	fi
