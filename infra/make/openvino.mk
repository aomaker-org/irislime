# ==============================================================================
# Filename:     infra/make/openvino.mk
# Purpose:      Intel OpenVINO Inference Acceleration Compilation Blueprint
# Type:         Makefile Component (Self-Healing Header & Granular Clean Compliant)
# Attribution:  fekerr & Gemini (20260704_1915 / Self-Healing Header Pass)
# ==============================================================================

BUILD_DIR     ?= build/openvino_relwithdebinfo
LOG_FILE_PATH ?= $(CURDIR)/$(BUILD_DIR)/logs/build_default.log
LOCAL_INC_DIR := $(CURDIR)/infra/include

# --- CLEAN COMPILER PATCH MATRIX ---
OPENCL_PATCH_DEFS := \
    CL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KHR=0x406E \
    CL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KMT_KHR=0x406F \
    CL_EXTERNAL_MEMORY_HANDLE_D3D12_HEAP_KHR=0x4070 \
    CL_EXTERNAL_MEMORY_HANDLE_D3D12_RESOURCE_KHR=0x4071

# --- ENVIRONMENT POINTER INTERPOLATION (Single Source of Truth) ---
ifeq ($(OpenVINO_DIR),)
    OPENVINO_SEARCH_PATHS := \
        /usr/lib/cmake/openvino2024.6.0 \
        /opt/intel/openvino \
        /usr/lib/x86_64-linux-gnu/cmake/OpenVINO
    TARGET_OV_DIR := $(firstword $(wildcard $(OPENVINO_SEARCH_PATHS)))
else
    TARGET_OV_DIR := $(OpenVINO_DIR)
endif

# --- PLATFORM SPECIFIC COMPILER INFRASTRUCTURE ALIGNMENT ---
ifeq ($(OS),Windows_NT)
    CMAKE_GEN_FLAGS    := -G "Ninja"
    OPENVINO_CXX_FLAGS := $(addprefix -D,$(OPENCL_PATCH_DEFS)) /EHsc -I$(LOCAL_INC_DIR)
    CMAKE_EXTRA_FLAGS  := -DGGML_EXCEPTIONS=ON
else
    CMAKE_GEN_FLAGS    := 
    OPENVINO_CXX_FLAGS := $(addprefix -D,$(OPENCL_PATCH_DEFS)) -fexceptions -I$(LOCAL_INC_DIR)
    CMAKE_EXTRA_FLAGS  := -DGGML_EXCEPTIONS=ON
endif

.PHONY: build-openvino clean-openvino bootstrap-headers clean-cache-openvino

bootstrap-headers: ## Fetches missing Khronos OpenCL C++ bindings autonomously if missing
	@if [ ! -f "$(LOCAL_INC_DIR)/CL/cl2.hpp" ] || [ ! -f "$(LOCAL_INC_DIR)/CL/opencl.hpp" ]; then \
		echo "[*] Bootstrapping missing Khronos OpenCL C++ Bindings via raw source..."; \
		mkdir -p $(LOCAL_INC_DIR)/CL; \
		curl -sSL "https://raw.githubusercontent.com/KhronosGroup/OpenCL-CLHPP/main/include/CL/opencl.hpp" -o "$(LOCAL_INC_DIR)/CL/opencl.hpp"; \
		curl -sSL "https://raw.githubusercontent.com/KhronosGroup/OpenCL-CLHPP/main/include/CL/cl2.hpp" -o "$(LOCAL_INC_DIR)/CL/cl2.hpp"; \
		echo "[+] Khronos OpenCL C++ headers securely mapped to workspace tracking assets."; \
	fi

build-openvino: bootstrap-headers ## Configure and compile the target OpenVINO acceleration workspace
	@if [ -z "$(TARGET_OV_DIR)" ]; then \
		echo "[!] Error: OpenVINO_DIR is not set. Source config_win11 or config_env first."; \
		exit 1; \
	fi
	@echo "[Make] Initializing OpenVINO compilation inside: $(BUILD_DIR)"
	@mkdir -p $(BUILD_DIR)
	@echo "[Make] Log streaming handled via Python multiplexer parent engine."
	@echo "=================================================================="
	unset Platform && cd $(BUILD_DIR) && \
	cmake ../../$(ENGINE_DIR) \
		$(CMAKE_GEN_FLAGS) \
		-DGGML_OPENVINO=ON \
		$(CMAKE_EXTRA_FLAGS) \
		-DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
		-DOpenVINO_DIR="$(TARGET_OV_DIR)" \
		$(CMAKE_FLAGS) \
		-DCMAKE_CXX_FLAGS="$(OPENVINO_CXX_FLAGS)" && \
	cmake --build . -j$(NUM_BUILD_JOBS) --config $(CMAKE_BUILD_TYPE)

clean-openvino: ## Purge isolated target configurations and logs for OpenVINO
	@echo "[!] Purging isolated target directory: $(BUILD_DIR)"
	rm -rf $(BUILD_DIR)

clean-cache-openvino: ## Surgically clear CMake configuration caches without purging pre-compiled object files
	@echo "[-] Surgically pruning OpenVINO CMake cache artifacts..."
	rm -f $(BUILD_DIR)/CMakeCache.txt
	rm -rf $(BUILD_DIR)/CMakeFiles
	@echo "[+] OpenVINO stale cache signatures purged. Object states intact."
