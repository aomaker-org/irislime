# ==============================================================================
# Target: Android NDK Build (ARM64 for Pixel Devices)
# ==============================================================================

ANDROID_NDK ?= $(HOME)/Android/Sdk/ndk-bundle # Needs to be set or discovered
ANDROID_ABI ?= arm64-v8a
ANDROID_PLATFORM ?= android-33
BUILD_DIR_ANDROID ?= build/android_$(ANDROID_ABI)

.PHONY: build_android_arm64 clean_android hydrate_llama_cpp

# Hydrate the required submodule dynamically before building
hydrate_llama_cpp:
	@echo "[Android-Build] Hydrating llama.cpp submodule..."
	git submodule update --init --recursive $(ENGINE_DIR)

build_android_arm64: hydrate_llama_cpp
	@echo "================================================================"
	@echo " Building $(ENGINE_DIR) for Android ($(ANDROID_ABI))"
	@echo " NDK: $(ANDROID_NDK)"
	@echo " Platform: $(ANDROID_PLATFORM)"
	@echo "================================================================"
	@mkdir -p $(BUILD_DIR_ANDROID)
	@if [ ! -d "$(ANDROID_NDK)" ]; then \
		echo "[ERROR] ANDROID_NDK path not found. Please set ANDROID_NDK."; \
	fi
	cmake -S $(ENGINE_DIR) -B $(BUILD_DIR_ANDROID) \
		-DCMAKE_TOOLCHAIN_FILE=$(ANDROID_NDK)/build/cmake/android.toolchain.cmake \
		-DANDROID_ABI=$(ANDROID_ABI) \
		-DANDROID_PLATFORM=$(ANDROID_PLATFORM) \
		-DCMAKE_BUILD_TYPE=Release
	cmake --build $(BUILD_DIR_ANDROID) -j $(NUM_BUILD_JOBS)

clean_android:
	rm -rf $(BUILD_DIR_ANDROID)
