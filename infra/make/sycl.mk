# ==============================================================================
# Path:         infra/make/sycl.mk
# Purpose:      Intel oneAPI SYCL Engine Compilation Blueprint (Profile-Aware)
# Type:         Makefile Component (Dynamic Build-Isolation Compliant)
# Lineage:      Unified Asset Specification
# Updated:      20260710_0105 (fekerr & Gemini / Telemetry Unblinding Pass)
# ==============================================================================

LITERT_PROFILE ?= $(if $(PROFILE),$(shell echo "$(PROFILE)" | tr '[:upper:]' '[:lower:]'),release)

# Target-specific variables for sycl targets to avoid polluting global namespace
build-sycl clean-sycl: BUILD_DIR        = $(if $(filter debug,$(LITERT_PROFILE)),build/sycl_debug,build/sycl_relwithdebinfo)
build-sycl clean-sycl: CMAKE_BUILD_TYPE = $(if $(filter debug,$(LITERT_PROFILE)),Debug,RelWithDebInfo)
build-sycl clean-sycl: LITERT_LINK_DIR  = $(if $(filter debug,$(LITERT_PROFILE)),$(CURDIR)/build/litert_debug,$(CURDIR)/build/litert_release)


.PHONY: build-sycl clean-sycl

build-sycl: bootstrap-headers ## Configure and compile Intel SYCL target
	@echo "[Make] Profile Target Locked: LITERT_PROFILE=$(LITERT_PROFILE)"
	@echo "[Make] Initializing Intel oneAPI SYCL inside: $(BUILD_DIR)"
	@mkdir -p $(BUILD_DIR)
	@START_TIME=$$(date +%s); \
	cd $(BUILD_DIR) && rm -f CMakeCache.txt && \
	P_PATH="$(LITERT_LINK_DIR)" && \
	M_ROOT=$${MKLROOT:-/opt/intel/oneapi/mkl/latest} && \
	M_DIR="$$M_ROOT/lib/cmake/mkl" && \
	CC=icx CXX=icpx MKLROOT="$$M_ROOT" MKL_ROOT="$$M_ROOT" \
	cmake ../../$(ENGINE_DIR) \
		-DGGML_SYCL=ON \
		-DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
		-DCMAKE_PREFIX_PATH="$$P_PATH;$$M_ROOT" \
		-DMKL_DIR="$$M_DIR" \
		-DMKL_ROOT="$$M_ROOT" \
		-DIRISLIME_LITERT_DIR="$$P_PATH" \
		-DLLAMA_BUILD_TESTS=ON \
		-DCMAKE_C_COMPILER_LAUNCHER=ccache \
		-DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
		$(CMAKE_FLAGS) && \
	cmake --build . -j$(NUM_BUILD_JOBS) \
		--config $(CMAKE_BUILD_TYPE) & \
	BUILD_PID=$$! ; \
	echo "[+] Background SYCL build process spawned with PID: $$BUILD_PID" ; \
	uv run tools/track_profile.py --pid $$BUILD_PID \
		--out logs/builds/sycl_profile/resource_telemetry.csv \
		--interval 1.0 ; \
	wait $$BUILD_PID ; \
	STATUS=$$?; \
	END_TIME=$$(date +%s); \
	DURATION=$$((END_TIME - START_TIME)); \
	if [ $$STATUS -ne 0 ]; then \
		echo "[!] SYCL Compilation Macro Failed."; \
		exit $$STATUS; \
	fi; \
	echo "$(TIMESTAMP),sycl,$(CMAKE_BUILD_TYPE),$${DURATION}" >> $(METRICS_FILE)

clean-sycl: ## Purge runtime generation artifacts and logs for the SYCL engine
	@echo "[!] Purging target space: $(BUILD_DIR)"
	rm -rf $(BUILD_DIR)

# ==============================================================================
# Context Boundary: infra/make/sycl.mk_Complete
# ==============================================================================
