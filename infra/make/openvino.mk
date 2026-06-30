# ==============================================================================
# Filename:    infra/make/openvino.mk
# Timestamp:   20260630_0235
# Attribution: fekerr @ gemini (flash 3.5 + extended)
# Purpose:     Intel OpenVINO Inference Acceleration Compilation Blueprint
# ==============================================================================

BUILD_DIR_OV := $(BUILD_ROOT)/openvino
LOG_DIR_OV   := $(BUILD_DIR_OV)/logs
LOG_FILE_OV  := $(LOG_DIR_OV)/build_$(TIMESTAMP).log

# --- AUTOMATED OPENVINO PATH DISCOVERY ---
# Probes common installation paths for the development toolkit binaries
OPENVINO_SEARCH_PATHS := /opt/intel/openvino /opt/intel/openvino_2026 /usr/lib/x86_64-linux-gnu/cmake/OpenVINO
DETECTED_OV_DIR := $(firstword $(wildcard $(OPENVINO_SEARCH_PATHS)))

.PHONY: build-openvino run-openvino

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
		$(if $(DETECTED_OV_DIR),-DCMAKE_PREFIX_PATH="$(DETECTED_OV_DIR)",) \
		$(call APPEND_STREAM,../../$(LOG_FILE_OV)) && \
	echo "--- Starting OpenVINO Parallel Compilation (Jobs Allocated: $(NUM_BUILD_JOBS)) ---" $(call APPEND_STREAM,../../$(LOG_FILE_OV)) && \
	$(MAKE) -j$(NUM_BUILD_JOBS) $(call APPEND_STREAM,../../$(LOG_FILE_OV)); \
	STATUS=$$?; \
	END_TIME=$$(date +%s); \
	DURATION=$$((END_TIME - START_TIME)); \
	echo "==============================================================================" >> ../../$(LOG_FILE_OV) && \
	echo "LOG FILE FOOTER" >> ../../$(LOG_FILE_OV) && \
	if [ $$STATUS -ne 0 ]; then \
		echo "Status:      FAILURE" >> ../../$(LOG_FILE_OV); \
		echo "Timestamp:   $$(date +%Y%m%d_%H%M%S)" >> ../../$(LOG_FILE_OV); \
		echo "==============================================================================" >> ../../$(LOG_FILE_OV); \
		echo "[!] OpenVINO Compilation Macro Failed. Inspect traces inside $(LOG_FILE_OV)"; \
		$(call log_telemetry,OPENVINO,$$DURATION,FAILURE); \
		exit $$STATUS; \
	fi; \
	echo "Status:      SUCCESS" >> ../../$(LOG_FILE_OV); \
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
		-m "$$IRISLIME_MODELS_DIR/tinyllama-1.1b-chat-v1.0.Q4_0.gguf" \
		-p "Explain model quantization optimization steps:" \
		-n 30 \
		-t $(NUM_INF_THREADS) \
		-co off \
		-no-cnv

# end of infra/make/openvino.mk
