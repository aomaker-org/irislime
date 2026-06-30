# ==============================================================================
# Filename:    infra/make/sycl.mk
# Timestamp:   20260630_0015
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
	echo "--- Starting SYCL Parallel Compilation (Jobs Allocated: $(NUM_BUILD_JOBS)) ---" $(call APPEND_STREAM,../../$(LOG_FILE_SYCL)) && \
	$(MAKE) -j$(NUM_BUILD_JOBS) $(call APPEND_STREAM,../../$(LOG_FILE_SYCL)); \
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
	@echo "[+] Launching runtime loop mapped to $(NUM_INF_THREADS) physical P-Cores."
	@$(BUILD_DIR_SYCL)/bin/llama-cli \
		-m $(MODELS_DIR)/llama3.2-3b-q4.gguf \
		-p "Optimize matrix loops for parallel scheduling:" \
		-n 30 \
		-t $(NUM_INF_THREADS) \
		-ngl 99

# end of infra/make/sycl.mk
