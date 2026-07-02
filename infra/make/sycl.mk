# ==============================================================================
# Filename:    infra/make/sycl.mk
# Purpose:     Intel oneAPI SYCL Engine Compilation Blueprint
# Type:        Makefile Component (Dynamic Build-Isolation Compliant)
# Attribution: fekerr @ gemini (20260701_1038 flash 3.5 + extended)
# ==============================================================================

BUILD_DIR     ?= build/sycl_relwithdebinfo
LOG_FILE_PATH ?= $(BUILD_DIR)/logs/build_manual.log

.PHONY: build-sycl clean-sycl

build-sycl:
	@echo "[Make] Initializing Intel oneAPI SYCL compilation inside: $(BUILD_DIR)"
	@mkdir -p $(BUILD_DIR) $(dir $(LOG_FILE_PATH))
	@echo "==================================================================" >> $(LOG_FILE_PATH)
	@echo "[Make Session] Launching Build at $$(date)" >> $(LOG_FILE_PATH)
	@echo "==================================================================" >> $(LOG_FILE_PATH)
	@echo "[Make] Log Target Destination: $(LOG_FILE_PATH)"
	@START_TIME=$$(date +%s); \
	cd $(BUILD_DIR) && \
	CC=icx CXX=icpx cmake ../../$(ENGINE_DIR) \
		-DGGML_SYCL=ON \
		-DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
		$(CMAKE_FLAGS) >> $(LOG_FILE_PATH) 2>&1 && \
	$(MAKE) -j$(NUM_BUILD_JOBS) >> $(LOG_FILE_PATH) 2>&1; \
	STATUS=$$?; \
	END_TIME=$$(date +%s); \
	DURATION=$$((END_TIME - START_TIME)); \
	if [ $$STATUS -ne 0 ]; then \
		echo "[!] SYCL Compilation Macro Failed. Inspect $(LOG_FILE_PATH)"; \
		exit $$STATUS; \
	fi

clean-sycl:
	rm -rf $(BUILD_DIR)

# end of infra/make/sycl.mk
