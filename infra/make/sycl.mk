# ==============================================================================
# Filename:      infra/make/sycl.mk
# Purpose:       Intel oneAPI SYCL Engine Compilation Blueprint (Profile-Aware)
# Type:          Makefile Component (Dynamic Build-Isolation Compliant)
# Attribution:   fekerr & Gemini (20260704_1710 / Optimization Pass)
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

build-sycl: ## Configure and compile the Intel oneAPI SYCL core acceleration target
	@echo "[Make] Profile Target Locked: LITERT_PROFILE=$(LITERT_PROFILE)"
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
		-DCMAKE_PREFIX_PATH="$(LITERT_LINK_DIR)" \
		-DIRISLIME_LITERT_DIR="$(LITERT_LINK_DIR)" \
		$(CMAKE_FLAGS) >> $(LOG_FILE_PATH) 2>&1 && \
	cmake --build . -j$(NUM_BUILD_JOBS) --config $(CMAKE_BUILD_TYPE) >> $(LOG_FILE_PATH) 2>&1; \
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
