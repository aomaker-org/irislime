# ==============================================================================
# Filename:    infra/make/openvino.mk
# Purpose:     Intel OpenVINO Inference Acceleration Compilation Blueprint
# Type:        Makefile Component
# Attribution: fekerr & Gemini (20260630_1138 / flash 3.5 extended)
# Timestamp:   20260630_1138
# ==============================================================================

BUILD_DIR_OV := $(BUILD_ROOT)/openvino
LOG_DIR_OV   := $(BUILD_DIR_OV)/logs
LOG_FILE_OV  := $(LOG_DIR_OV)/build_$(TIMESTAMP).log

# --- ENFORCED ENVIRONMENT POINTER INTERPOLATION ---
# Prioritize variables exported via config_env, falling back to discovered system pathing
ifeq ($(OpenVINO_DIR),)
    OPENVINO_SEARCH_PATHS := /usr/lib/cmake/openvino2024.6.0 /opt/intel/openvino /usr/lib/x86_64-linux-gnu/cmake/OpenVINO
    TARGET_OV_DIR := $(firstword $(wildcard $(OPENVINO_SEARCH_PATHS)))
else
    TARGET_OV_DIR := $(OpenVINO_DIR)
endif

.PHONY: build-openvino run-openvino clean-openvino

clean-openvino:
	@echo "[!] Purging OpenVINO build workspace tracking artifacts..."
	@rm -rf $(BUILD_DIR_OV)
	@echo "[+] OpenVINO build artifacts removed."

build-openvino: setup-venv verify-infra
	@echo "=================================================================="
	@echo "[+] Launching OpenVINO Acceleration Out-of-Tree Build Matrix..."
	@mkdir -p $(LOG_DIR_OV)
	@echo "[+] Log Target Destination: $(LOG_FILE_OV)"
	@echo "=================================================================="
	@START_TIME=$$(date +%s); \
	cd $(BUILD_DIR_OV) && \
	echo "==============================================================================" > ../../$(LOG_FILE_OV) && \
	echo "LOG FILE HEADER" >> ../../$(LOG_FILE_OV) && \
	echo "Filename:    $(LOG_FILE_OV)" >> ../../$(LOG_FILE_OV) && \
	echo "Timestamp:   $(TIMESTAMP)" >> ../../$(LOG_FILE_OV) && \
	echo "Pipeline:    IrisLime OpenVINO Build Matrix" >> ../../$(LOG_FILE_OV) && \
	echo "==============================================================================" >> ../../$(LOG_FILE_OV) && \
	echo "--- Starting OpenVINO CMake Generation Phase ---" $(call APPEND_STREAM,../../$(LOG_FILE_OV)) && \
	cmake ../../$(ENGINE_DIR) \
		-DGGML_OPENVINO=ON \
		-DCMAKE_BUILD_TYPE=Release \
		$(if $(TARGET_OV_DIR),-DCMAKE_PREFIX_PATH="$(TARGET_OV_DIR)",) \
		-DCMAKE_CXX_FLAGS="-DCL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KHR=0x406E -DCL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KMT_KHR=0x406F -DCL_EXTERNAL_MEMORY_HANDLE_D3D12_HEAP_KHR=0x4070 -DCL_EXTERNAL_MEMORY_HANDLE_D3D12_RESOURCE_KHR=0x4071" \
		$(call APPEND_STREAM,../../$(LOG_FILE_OV)) && \
	echo "--- Starting OpenVINO Parallel Compilation (Jobs Allocated: $(NUM_BUILD_JOBS)) ---" $(call APPEND_STREAM,../../$(LOG_FILE_OV)) && \
	$(MAKE) -j$(NUM_BUILD_JOBS) $(call APPEND_STREAM,../../$(LOG_FILE_OV)); \
	STATUS=$$?; \
	END_TIME=$$(date +%s); \
	DURATION=$$((END_TIME - START_TIME)); \
	echo "==============================================================================" >> ../../$(LOG_FILE_OV) && \
	echo "LOG FILE FOOTER" >> ../../$(LOG_FILE_OV) && \
	if [ $$STATUS -ne 0 ]; then \
		echo "Status:     FAILURE" >> ../../$(LOG_FILE_OV); \
		echo "Timestamp:   $$(date +%Y%m%d_%H%M%S)" >> ../../$(LOG_FILE_OV); \
		echo "==============================================================================" >> ../../$(LOG_FILE_OV); \
		echo "[!] OpenVINO Compilation Macro Failed. Inspect traces inside $(LOG_FILE_OV)"; \
		$(call log_telemetry,OPENVINO,$$DURATION,FAILURE); \
		exit $$STATUS; \
	fi; \
	echo "Status:     SUCCESS" >> ../../$(LOG_FILE_OV); \
	echo "Timestamp:   $$(date +%Y%m%d_%H%M%S)" >> ../../$(LOG_FILE_OV); \
	echo "==============================================================================" >> ../../$(LOG_FILE_OV); \
	$(call log_telemetry,OPENVINO,$$DURATION,SUCCESS); \
	echo "------------------------------------------------------------------" && \
	echo "[+] OpenVINO target compiled successfully in $$DURATION seconds."

run-openvino:
	@if [ ! -f "$(BUILD_DIR_OV)/bin/llama-cli" ]; then \
		echo "[!] Target binary missing. Execute 'make build-openvino' first."; exit 3; \
	fi
	@export GGML_OPEN_VINO_DEVICE=GPU && \
	$(BUILD_DIR_OV)/bin/llama-cli \
		-m "$(IRISLIME_TEST_MODEL)" \
		-p "Explain model quantization optimization steps:" \
		-n 30 \
		-t $(NUM_INF_THREADS) \
		-co off

# ==============================================================================
# Footer:      infra/make/openvino.mk
# ==============================================================================
