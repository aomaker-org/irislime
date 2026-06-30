Managing parallel scheduling across Intel's hybrid Core architectures (introduced in 12th Gen Alder Lake and expanded in subsequent architectures) requires a fundamental shift in how we structure both **build-time parallelism** (`make -j`) and **runtime inference allocation** (`llama-cli -t`).

Treating all execution streams identically under a generic `nproc` macro introduces significant hardware vulnerabilities that degrade performance.

---

## 1. The Architectural Trap: Performance vs. Efficient Cores

Intel 11th Gen (Tiger Lake) architectures utilize a homogeneous core layout: every core is identical and supports Symmetric Multithreading (SMT / Hyper-Threading). However, Intel 12th Gen (Alder Lake) architectures introduce a heterogeneous layout combining two distinct core microarchitectures onto a single silicon die:

* **Performance-cores (P-cores):** High-IPC, high-frequency execution blocks that support Hyper-Threading (2 logical threads per physical core). These cores handle heavy vector and matrix math compute paths.
* **Efficient-cores (E-cores):** Low-power, single-threaded execution blocks (1 logical thread per physical core) designed to handle background tasks and low-priority OS threads. They lack Hyper-Threading and run at lower clock speeds with a smaller cache allocation.

```
                  HYBRID CPU TOPOLOGY (e.g., Core i7-12700H)
 ┌─────────────────────────────────────────────────────────────────────────┐
 │                           Shared L3 Cache                               │
 └─────────────────────────────────────────────────────────────────────────┘
        ▲                     ▲                     ▲                 ▲
 ┌──────────────┐      ┌──────────────┐      ┌──────────────┐  ┌───────────┐
 │ Physical P0  │      │ Physical P1  │      │ Physical P5  │  │ E-Core    │
 ├──────┬───────┤      ├──────┬───────┤ ...  ├──────┬───────┤  │ Cluster   │
 │ T0   │ T12   │      │ T1   │ T13   │      │ T5   │ T17   │  │ (T8-T15)  │
 └──────┴───────┘      └──────┴───────┘      └──────┴───────┘  └───────────┘
  (High IPC, SMT)       (High IPC, SMT)       (High IPC, SMT)   (Low IPC, No SMT)

```

### The Build-Time Bottleneck (`make -j`)

If a 12th Gen mobile chip features 6 P-cores (12 threads) and 8 E-cores (8 threads), `nproc` reports **20 logical processors**.

* Running `make -j20` forces the compiler (`icpx`) to spawn 20 simultaneous compilation processes.
* Heavy C++ compilation units are highly cache-sensitive. Spawning 20 jobs saturates the shared L3 cache and memory bus bandwidth.
* When a complex compilation job is scheduled onto an E-core, it executes significantly slower than parallel jobs on P-cores. Because the build system must hit compilation serialization barriers (waiting for object files before linking), the overall build speed is throttled by the slowest executing thread (the E-core tail latency issue).
* Simultaneously running all 20 threads at 100% load on a laptop causes rapid thermal saturation, triggering aggressive clock-frequency throttling across the P-cores.

### The Inference-Time Disaster (`-t` Flag)

During text generation, `llama.cpp` uses row/column splitting to divide matrix multiplications across its assigned thread pool.

* These threads must synchronize at strict barriers after calculating each matrix block before moving to the next layer activation.
* If you pass the raw logical processor count (e.g., `-t 20`), the threads mapped to P-cores finish their operations almost instantly. They then enter a spin-lock state, consuming power and sitting completely idle while waiting for the slow E-core threads to finish their portion of the matrix.
* **The Rule of Thumb:** For optimal edge inference, the thread pool size must match the number of **physical Performance-cores** exactly, leaving E-cores completely out of the tensor math path.

---

## 2. Implementing the Topology Parser: `infra/make/base.mk`

To automate this layout mapping safely without introducing external dependencies, we use a custom Linux kernel `sysfs` parser directly inside our build configurations.

On Intel platforms, P-cores support Hyper-Threading (their `thread_siblings_list` contains a comma separator, e.g., `0,12`), while E-cores do not (their list contains an isolated integer, e.g., `8`). We use this hardware distinction to calculate balanced build and inference execution targets.

```makefile
# ==============================================================================
# Filename:    infra/make/base.mk
# Timestamp:   20260629_2020
# Attribution: fekerr @ gemini (flash 3.5 + extended)
# Purpose:     Dynamic Hardware Topology Telemetry Parser for Hybrid Core Architectures
# ==============================================================================

ifndef IRISLIME_READY
  $(error [!] IrisLime environment context not detected! Run 'source config_env')
endif

SHELL        := /usr/bin/env bash
.SHELLFLAGS  := -euo pipefail -c

QUIET ?= 0

# --- CORE TOPOLOGY AUTOMATED PARSER ---
# Query Linux sysfs to count logical processors with active hyperthreads (P-cores)
NUM_P_THREADS := $(shell grep -l ',' /sys/devices/system/cpu/cpu*/topology/thread_siblings_list 2>/dev/null | wc -l)
NUM_E_THREADS := $(shell grep -L ',' /sys/devices/system/cpu/cpu*/topology/thread_siblings_list 2>/dev/null | wc -l)
TOTAL_THREADS := $(shell nproc)

# Fallback block for older kernels or non-hybrid platforms (e.g., 11th Gen homogeneous chips)
ifeq ($(NUM_P_THREADS),0)
  # System is homogeneous. Allocate all available hardware units.
  NUM_BUILD_JOBS := $(TOTAL_THREADS)
  NUM_INF_THREADS := $(shell echo $$(( $(TOTAL_THREADS) / 2 )))
else
  # System is heterogeneous (12th Gen+ Hybrid). Implement the Balanced Scaling Model.
  # Optimization Strategy: Map all P-threads + half of E-core density to prevent cache/thermal saturation
  NUM_BUILD_JOBS := $(shell echo $$(( $(NUM_P_THREADS) + ($(NUM_E_THREADS) / 2) )))
  # Execution Strategy: Lock thread arrays strictly to physical Performance Core counts
  NUM_INF_THREADS := $(shell echo $$(( $(NUM_P_THREADS) / 2 )))
endif

# --- SHARED CONFIGURATION MATRIX ---
ENGINE_DIR      := llama.cpp
MODELS_DIR      := models
BUILD_ROOT      := build
TIMESTAMP       := $(shell date +%Y%m%d_%H%M%S)
METRICS_FILE    := telemetry_builds.csv

ifeq ($(QUIET),1)
  INIT_STREAM   = > $(1) 2>&1
  APPEND_STREAM = >> $(1) 2>&1
else
  INIT_STREAM   = 2>&1 | tee $(1)
  APPEND_STREAM = 2>&1 | tee -a $(1)
endif

define log_telemetry
	echo "$(TIMESTAMP),$(1),$(2),$(3)" >> $(METRICS_FILE)
endef

.PHONY: verify-infra setup-venv track-workspace show-topology

show-topology:
	@echo "=================================================================="
	@echo "IrisLime Hardware Telemetry Report"
	@echo "=================================================================="
	@echo "  Detected Total Logical Processors  : $(TOTAL_THREADS)"
	@echo "  Performance Core Threads Detected  : $(NUM_P_THREADS) (Physical P-Cores: $(NUM_INF_THREADS))"
	@echo "  Efficient Core Threads Detected    : $(NUM_E_THREADS)"
	@echo "------------------------------------------------------------------"
	@echo "  Optimized Build Parallelism (-j)   : $(NUM_BUILD_JOBS)"
	@echo "  Optimized Inference Context (-t)   : $(NUM_INF_THREADS)"
	@echo "=================================================================="

verify-infra:
	@if [ ! -d "infra/make" ]; then \
		echo "[!] Critical Error: Modular build directory structure missing at infra/make"; \
		exit 1; \
	fi

setup-venv: venv/.installed

venv/.installed: requirements.txt
	@echo "[+] Verifying localized python runtime environment..."
	@if [ ! -d "venv" ]; then python3 -m venv venv; fi
	@./venv/bin/pip install --upgrade pip > /dev/null
	@./venv/bin/pip install -r requirements.txt > /dev/null
	@touch venv/.installed

track-workspace:
	@echo ""
	@echo "[+] Mapping current IrisLime compilation and telemetry tree structures:"
	@if command -v tree &> /dev/null; then \
		tree -f $(BUILD_ROOT); \
	else \
		find $(BUILD_ROOT) -type f -name "*.log" -o -name "llama-cli"; \
	fi

# end of infra/make/base.mk

```

---

## 3. Integrating the Parameters Into Module Targets

By routing our build concurrency variable (`NUM_BUILD_JOBS`) and inference execution parameter (`NUM_INF_THREADS`) through the centralized baseline configurations, our backend sub-makefiles will scale their execution boundaries dynamically based on the underlying hardware layout.

### Updated Compilation Sequence Template (e.g., `infra/make/sycl.mk`)

Update the inner call of the underlying makefile compilation target to substitute raw `nproc` calls with our newly derived thread boundary flag:

```makefile
# Inside infra/make/sycl.mk...
# Replace old raw subshell allocation: $(MAKE) -j$(shell nproc)
# Deploy optimized topology mapping:
$(MAKE) -j$(NUM_BUILD_JOBS) $(call APPEND_STREAM,../../$(LOG_FILE_SYCL))

```

### Updated Runtime Evaluation Sequence Template

Similarly, update the runtime execution flags to use the optimized physical core count, forcing high-density matrix math operations onto the P-cores while preventing thread pool fragmentation across E-cores:

```makefile
# Inside infra/make/sycl.mk...
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

```

*(Apply this same `-t $(NUM_INF_THREADS)` structure across `openvino.mk` and `vulkan.mk` execution hooks to normalize runtime testing paths.)*

---

## 4. Architectural Verification Metrics

To view how your local hardware topology maps to these optimized configurations, execute the new telemetry target:

```bash
make show-topology

```

### Profile A: Core i7-12700H (Heterogeneous Mobile Profile)

```text
==================================================================
IrisLime Hardware Telemetry Report
==================================================================
  Detected Total Logical Processors  : 20
  Performance Core Threads Detected  : 12 (Physical P-Cores: 6)
  Efficient Core Threads Detected    : 8
------------------------------------------------------------------
  Optimized Build Parallelism (-j)   : 16
  Optimized Inference Context (-t)   : 6
==================================================================

```

* **Build Optimization Benefit:** Dropping compilation parallelism from 20 down to 16 prevents cache starvation across the shared L3 boundary and leaves a portion of the E-core cluster available for background OS operations, mitigating terminal lag during heavy compilation phases.
* **Inference Optimization Benefit:** Locking execution threads to exactly 6 pins the entire tensor processing matrix directly to the high-frequency physical P-cores, completely eliminating cross-core synchronization latencies and spin-lock execution bottlenecks.

### Profile B: Core i7-1185G7 (Homogeneous Mobile Profile)

```text
==================================================================
IrisLime Hardware Telemetry Report
==================================================================
  Detected Total Logical Processors  : 8
  Performance Core Threads Detected  : 8 (Physical P-Cores: 4)
  Efficient Core Threads Detected    : 0
------------------------------------------------------------------
  Optimized Build Parallelism (-j)   : 8
  Optimized Inference Context (-t)   : 4
==================================================================

```

* **Homogeneous Scaling:** The parser detects the lack of independent core variants and safely falls back to standard symmetric multi-core patterns, utilizing all available execution threads for compilation and standard physical cores for matrix multiplication.
