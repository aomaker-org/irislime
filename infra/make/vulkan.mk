# ==============================================================================
# Filename:    infra/make/vulkan.mk
# Purpose:     Portable Vulkan Cross-Platform Graphics Engine Blueprint
# Type:        Makefile Component (Dynamic Build-Isolation Compliant)
# Attribution: fekerr & Gemini (20260701_1028 / flash 3.5 extended)
# ==============================================================================

BUILD_DIR     ?= build/vulkan_release
LOG_FILE_PATH ?= $(BUILD_DIR)/logs/build_manual.log

.PHONY: build-vulkan clean-vulkan

build-vulkan:
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
		$(CMAKE_FLAGS) >> $(LOG_FILE_PATH) 2>&1 && \
	$(MAKE) -j$(NUM_BUILD_JOBS) >> $(LOG_FILE_PATH) 2>&1; \
	STATUS=$$?; \
	END_TIME=$$(date +%s); \
	DURATION=$$((END_TIME - START_TIME)); \
	if [ $$STATUS -ne 0 ]; then \
		echo "[!] Vulkan Compilation Macro Failed. Inspect $(LOG_FILE_PATH)"; \
		exit $$STATUS; \
	fi

clean-vulkan:
	rm -rf $(BUILD_DIR)

# end of infra/make/vulkan.mk
