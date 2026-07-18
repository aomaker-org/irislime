# ==============================================================================
# Filename:     infra/make/vulkan.mk
# Purpose:      Portable Vulkan Cross-Platform Graphics Engine Blueprint
# Type:         Makefile Component (Dynamic Build-Isolation Compliant)
# Attribution:  fekerr & Gemini (20260704_1710 / Optimization Pass)
# ==============================================================================

BUILD_DIR     ?= build/vulkan_release
LOG_FILE_PATH ?= $(BUILD_DIR)/logs/build_manual.log

.PHONY: build-vulkan clean-vulkan

build-vulkan: ## Configure and compile the portable Mesa Vulkan compute target workspace
	@echo "[Make] Initializing Vulkan SPIR-V compilation inside: $(BUILD_DIR)"
	@mkdir -p $(BUILD_DIR) $(dir $(LOG_FILE_PATH))
	@echo "==================================================================" >> $(LOG_FILE_PATH)
	@echo "[Make Session] Launching Build at $$(date)" >> $(LOG_FILE_PATH)
	@echo "==================================================================" >> $(LOG_FILE_PATH)
	@echo "[Make] Log Target Destination: $(LOG_FILE_PATH)"
	@START_TIME=$$(date +%s); \
	cd $(BUILD_DIR) && \
	cmake ../../$(ENGINE_DIR) \
		-DGGML_VULKAN=ON \
		-DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
		-DLLAMA_BUILD_TESTS=ON \
		-DCMAKE_C_COMPILER_LAUNCHER=ccache \
		-DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
		$(CMAKE_FLAGS) >> $(LOG_FILE_PATH) 2>&1 && \
	cmake --build . -j$(NUM_BUILD_JOBS) --config $(CMAKE_BUILD_TYPE) >> $(LOG_FILE_PATH) 2>&1; \
	STATUS=$$?; \
	END_TIME=$$(date +%s); \
	DURATION=$$((END_TIME - START_TIME)); \
	if [ $$STATUS -ne 0 ]; then \
		echo "[!] Vulkan Compilation Macro Failed. Inspect $(LOG_FILE_PATH)"; \
		exit $$STATUS; \
	fi; \
	echo "$(TIMESTAMP),vulkan,$(CMAKE_BUILD_TYPE),$${DURATION}" >> $(METRICS_FILE)

clean-vulkan: ## Purge isolated targets and generated cache objects for Vulkan
	rm -rf $(BUILD_DIR)
