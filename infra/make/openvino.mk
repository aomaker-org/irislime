# ==============================================================================
# Filename:    infra/make/openvino.mk
# Purpose:     Intel OpenVINO Inference Acceleration Compilation Blueprint
# Type:        Makefile Component (Dynamic Build-Isolation Compliant)
# Attribution: fekerr & Gemini (20260702_0932 / flash 3.5 extended)
# ==============================================================================

BUILD_DIR     ?= build/openvino_relwithdebinfo
LOG_FILE_PATH ?= $(CURDIR)/$(BUILD_DIR)/logs/build_default.log

# --- CLEAN COMPILER PATCH MATRIX ---
OPENCL_PATCH_DEFS := \
    CL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KHR=0x406E \
    CL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KMT_KHR=0x406F \
    CL_EXTERNAL_MEMORY_HANDLE_D3D12_HEAP_KHR=0x4070 \
    CL_EXTERNAL_MEMORY_HANDLE_D3D12_RESOURCE_KHR=0x4071

OPENVINO_CXX_FLAGS := $(addprefix -D,$(OPENCL_PATCH_DEFS))

# --- ENFORCED ENVIRONMENT POINTER INTERPOLATION ---
ifeq ($(OpenVINO_DIR),)
    OPENVINO_SEARCH_PATHS := \
        /usr/lib/cmake/openvino2024.6.0 \
        /opt/intel/openvino \
        /usr/lib/x86_64-linux-gnu/cmake/OpenVINO
    TARGET_OV_DIR := $(firstword $(wildcard $(OPENVINO_SEARCH_PATHS)))
else
    TARGET_OV_DIR := $(OpenVINO_DIR)
endif

.PHONY: build-openvino clean-openvino

build-openvino: ## Configure and compile the target OpenVINO acceleration workspace
	@echo "[Make] Initializing OpenVINO compilation inside: $(BUILD_DIR)"
	@mkdir -p $(BUILD_DIR) $(dir $(LOG_FILE_PATH))
	@if [ -f "$(LOG_FILE_PATH)" ]; then \
		ARCHIVE_TIME=$$(date +%Y%m%d_%H%M%S); \
		echo "[Make] Archiving historical session to logs/build_default.$$ARCHIVE_TIME.log"; \
		mv "$(LOG_FILE_PATH)" "$(dir $(LOG_FILE_PATH))build_default.$$ARCHIVE_TIME.log"; \
	fi
	@echo "==================================================================" >> $(LOG_FILE_PATH)
	@echo "[Make Session] Launching Build at $$(date)" >> $(LOG_FILE_PATH)
	@echo "==================================================================" >> $(LOG_FILE_PATH)
	@echo "[Make] Log Target Destination: $(LOG_FILE_PATH)"
	@START_TIME=$$(date +%s); \
	cd $(BUILD_DIR) && \
	cmake ../../$(ENGINE_DIR) \
		-DGGML_OPENVINO=ON \
		-DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
		-DOpenVINO_DIR=$(TARGET_OV_DIR) \
		$(CMAKE_FLAGS) \
		-DCMAKE_CXX_FLAGS="$(OPENVINO_CXX_FLAGS)" >> $(LOG_FILE_PATH) 2>&1 && \
	$(MAKE) -j$(NUM_BUILD_JOBS) >> $(LOG_FILE_PATH) 2>&1; \
	STATUS=$$?; \
	END_TIME=$$(date +%s); \
	DURATION=$$((END_TIME - START_TIME)); \
	if [ $$STATUS -ne 0 ]; then \
		echo "[!] OpenVINO Compilation Macro Failed. Inspect $(LOG_FILE_PATH)"; \
		exit $$STATUS; \
	fi; \
	echo "$(TIMESTAMP),openvino,$(CMAKE_BUILD_TYPE),$${DURATION}" >> $(METRICS_FILE)

clean-openvino: ## Purge isolated target configurations and logs for OpenVINO
	@echo "[!] Purging isolated target directory: $(BUILD_DIR)"
	rm -rf $(BUILD_DIR)
