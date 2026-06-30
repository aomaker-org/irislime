# ==============================================================================
# Filename:    infra/make/vulkan.mk
# Purpose:     Portable Vulkan Cross-Platform Graphics Engine Blueprint
# ==============================================================================

BUILD_DIR_VK := $(BUILD_ROOT)/vulkan
LOG_VK       := build_vulkan_$(TIMESTAMP).log

.PHONY: build-vulkan run-vulkan

build-vulkan: setup-venv verify-infra
	@echo "[+] Launching Cross-Platform Vulkan Out-of-Tree Build Matrix..."
	@mkdir -p $(BUILD_DIR_VK)
	@START_TIME=$$(date +%s); \
	cd $(BUILD_DIR_VK) && \
	cmake ../../$(ENGINE_DIR) \
		-DGGML_VULKAN=ON \
		-DCMAKE_BUILD_TYPE=Release > ../../$(LOG_VK) 2>&1 && \
	$(MAKE) -j$$(shell nproc) >> ../../$(LOG_VK) 2>&1; \
	STATUS=$$?; \
	END_TIME=$$(date +%s); \
	DURATION=$$((END_TIME - START_TIME)); \
	if [ $$STATUS -ne 0 ]; then \
		echo "[!] Vulkan Compilation Macro Failed. Inspect $(LOG_VK)"; \
		$(call log_telemetry,VULKAN,$$DURATION,FAILURE); \
		exit $$STATUS; \
	fi; \
	$(call log_telemetry,VULKAN,$$DURATION,SUCCESS); \
	echo "[+] Vulkan target compiled successfully in $$DURATION seconds -> $(BUILD_DIR_VK)/bin/"

run-vulkan:
	@if [ ! -f "$(BUILD_DIR_VK)/bin/llama-cli" ]; then \
		echo "[!] Target binary missing. Execute 'make build-vulkan' first."; exit 3; \
	fi
	@$(BUILD_DIR_VK)/bin/llama-cli -m $(MODELS_DIR)/llama3.2-3b-q4.gguf -p "Vulkan runtime test:" -n 30 -ngl 99

# end of infra/make/vulkan.mk
