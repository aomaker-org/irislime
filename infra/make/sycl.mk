# ==============================================================================
# Filename:      infra/make/sycl.mk
# Purpose:       Intel oneAPI SYCL Engine Compilation Blueprint (Profile-Aware)
# Type:          Makefile Component (Dynamic Build-Isolation Compliant)
# Attribution:   fekerr & Gemini (20260706_1350 / Hoisted Path Pass)
# Line Width:    Aligned strictly to the 80-column safety horizon
# ==============================================================================

LITERT_PROFILE ?= release

ifeq ($(LITERT_PROFILE),debug)
	BUILD_DIR        := build/sycl_debug
	CMAKE_BUILD_TYPE := Debug
	LITERT_LINK_DIR  := $(CURDIR)/build/litert_debug
else
	BUILD_DIR        := build/sycl_relwithdebinfo
	CMAKE_BUILD_TYPE := RelWithDebInfo
	LITERT_LINK_DIR  := $(CURDIR)/build/litert_release
endif

LOG_FILE_PATH ?= $(BUILD_DIR)/logs/build_manual.log

.PHONY: build-sycl clean-sycl

build-sycl: bootstrap-headers ## Configure and compile Intel SYCL target
	@echo "[Make] Profile Target Locked: LITERT_PROFILE=$(LITERT_PROFILE)"
	@echo "[Make] Initializing Intel oneAPI SYCL inside: $(BUILD_DIR)"
	@mkdir -p $(BUILD_DIR) $(dir $(LOG_FILE_PATH))
	@echo "=====================================================" >> $(LOG_FILE_PATH)
	@echo "[Make Session] Launching Build at $$(date)" >> $(LOG_FILE_PATH)
	@echo "=====================================================" >> $(LOG_FILE_PATH)
	@echo "[Make] Log Target Destination: $(LOG_FILE_PATH)"
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
		$(CMAKE_FLAGS) >> $(LOG_FILE_PATH) 2>&1 && \
	cmake --build . -j$(NUM_BUILD_JOBS) \
		--config $(CMAKE_BUILD_TYPE) >> $(LOG_FILE_PATH) 2>&1 & \
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
		echo "[!] SYCL Compilation Macro Failed. Inspect $(LOG_FILE_PATH)"; \
		exit $$STATUS; \
	fi; \
	echo "$(TIMESTAMP),sycl,$(CMAKE_BUILD_TYPE),$${DURATION}" >> $(METRICS_FILE)

clean-sycl: ## Purge runtime generation artifacts and logs for the SYCL engine
	@echo "[!] Purging target space: $(BUILD_DIR)"
	rm -rf $(BUILD_DIR)
