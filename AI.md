# IrisLime LLM Context Architecture & Session State
# Filename:    AI.md
# Location:    Repository Root (/)
# Timestamp:   20260630_0748
# Attribution: fekerr @ gemini (flash 3.5 + extended)
# Purpose:     Idempotent Context-Transfer Interface for Incoming AI Agents

## 1. Project Taxonomy, Engineering Mission, & Interface Conventions
IrisLime is a highly optimized, modular, out-of-tree multi-target build pipeline wrapping the `llama.cpp` / `ggml` ecosystem. The project is specifically engineered to maximize local edge inference performance and build-time safety across asymmetric, heterogeneous hybrid CPU architectures (e.g., Intel 12th Gen Core i7-1255U with 2 P-Cores and 8 E-Cores) and virtualized consumer iGPUs under WSL2 (Ubuntu 24.04 LTS Noble).

### Key Architectural Constraints
- **Zero In-Tree Symlinks:** All model cache objects reside strictly outside the project workspace via environment paths.
- **Budget-Gated Offloading:** Public repository visibility leverages free-tier GitHub Actions hosted runners. Premium-rate cloud resources are restricted.
- **Asymmetric Affinity:** Threads are aggressively managed to prevent memory cache starvation and spin-lock execution latencies.

### 1.1 Script Metadata Encodings (Mandatory)
Every shell, utility, or orchestration script introduced to this repository must implement an explicit Header and Footer block:
1. **Header Block:** Must declare `Filename`, `Purpose`, `Type` (Sourced vs Executable), `Attribution`, and a point-in-time `Timestamp`.
2. **Execution Safety:** Executable scripts must use `set -euo pipefail`. Sourced scripts must include a guard trap blocking direct subshell execution.
3. **Footer Block:** Must output a standard explicit text string upon successful completion to guarantee deterministic parsing of execution logs.

### 1.2 Universal Stream Marking (The Human-AI Interface Rule)
To minimize cognitive load and stabilize working memory during extended collaborative sessions, all high-density text outputs—including interactive chat responses, script files, and sandbox execution logs—must be explicitly bounded by structural frames:
1. **Chat Streams:** Must open with an identifier header declaring the timestamped label, operational tags, and primary purpose, and close with a matching tracking footer.
2. **Telemetry Logs:** Standardize text-stream markers so that human developers or regex-based script parsers can instantly slice log contents without scanning unfiltered terminal noise.

---

## 2. Active System Topology & Telemetry Maps

### Host Hardware Blueprint (Validation Station)
- **Processor:** Intel Core i7-1255U (Heterogeneous: 2 Physical P-Cores with SMT / 8 E-Cores without SMT).
- **Available Guest RAM:** 7 GB (Constrained Virtualized Page Allocation via WSL2).
- **Target Accelerator:** Intel Iris Xe Integrated Graphics (96 EUs, Architecture ID `0x46a8`).
- **Hypervisor Boundary:** Windows 11 Host to Ubuntu 24.04 LTS Guest passing through `/dev/dxg`.

### Automated Build Parameters
- **`NUM_BUILD_JOBS := 1`**: Dynamically computed by `infra/make/base.mk` because RAM constraints (7 GB total / 4 GB required per heavy Flash Attention C++ compiler thread) override logical processor density. This limits compilation to single-threaded passes to prevent OOM swap-thrashing.
- **`NUM_INF_THREADS := 2`**: Automatically mapped to lock execution matrices strictly to physical Performance Core boundaries, leaving E-cores free for OS tasks.

---

## 3. Forensic Debugging & Milestone Ledger

### Milestone A: One-Shot SYCL Engine Success
- **Result:** Successfully compiled the out-of-tree SYCL backend (`infra/make/sycl.mk`) in **2125 seconds** utilizing memory-aware scheduling flags.
- **Artifact Matrix:** Generated a 58 MB dynamic link engine core at `build/sycl/bin/libggml-sycl.so.0.15.2`.

### Forensic Subsystem Discovered: The Level Zero `0x1` Segfault
- **Anatomy:** Querying the hardware via `sycl-ls` or `llama-ls-sycl-device` threw an immediate `SIGSEGV {si_signo=SIGSEGV, si_code=SEGV_MAPERR, si_addr=0x1}` core dump.
- **Root Cause:** A library compliance skew between Ubuntu's system-level `libze_loader.so.1` and the host Windows graphics driver passing through the virtual hypervisor interface.
- **Workaround Resolution:** Bypassed Level Zero entirely by routing instructions over the stable OpenCL graphics layer via the explicit environment selector override: `ONEAPI_DEVICE_SELECTOR="opencl:1"`.

### Forensic Runtime Discovered: Binary Bifurcation & Flag Order
- **Behavior:** `llama-cli` has migrated upstream to function strictly as an interactive conversational chat interface, ignoring the old `--no-conversation` switches. 
- **Remediation:** Switched execution pointer to the companion binary **`llama-completion`** for programmatic one-shot evaluation runs.
- **Flag Sequencing Order:** Upstream options parsers require that layout configuration flags (`-no-cnv` and `--log-colors off`) be declared **before** asset arguments (`-m` and `-p`) to prevent the engine from pre-initializing interactive templates.

---

## 4. Active Repository File Trees

- `config_env`: Sourced shell utility mapping environment constants, oneAPI variables, and directory cache locations (`IRISLIME_MODELS_DIR="../models"`).
- `Makefile`: Master entry point containing top-level orchestrations (`make setup`, `make build-all`).
- `infra/make/`: Isolated backend compilation descriptors (`base.mk`, `sycl.mk`, `openvino.mk`, `vulkan.mk`).
- `scripts/inference_runner.py`: Stream tracking parser that dynamically executes targets, strips ANSI terminal colors, and filters out `ext_intel_free_memory` driver noise.
- `logs/`: Comment-tolerant performance ledgers (`telemetry_builds.json`, `cost_governance.json`).
- `docs/`: Sequential incremental laboratory logs (`todo260630_001.md` through `todo260630_013.md`).

---

## 5. Active Backlog & Next Session Action Items

### Task Block 1: OpenVINO Build Resolution
The OpenVINO compilation matrix (`make build-openvino`) is currently failing at the CMake step with a missing package configuration error (`FindOpenVINO.cmake`).
- **The Blockade:** Ubuntu Noble (24.04) does not carry `libopenvino-dev` inside its standard universe channels, resulting in a package location error during `apt-get install`.
- **Next Step:** Forensically map the historical paths used in your previous compilation runs, or register Intel's official APT graphics repositories to resolve the development headers.

### Task Block 2: Log Rotation & Structural Polishing
- **Target:** Transition the loose `build_*.log` files from the root directory into backend sandboxes (`build/<backend>/logs/`).
- **Target:** Port the git-tracked file headers and footers implemented inside `openvino.mk` over to the companion `sycl.mk` and `vulkan.mk` scripts.

### Task Block 3: Cloud Agentic Workflows
- **Target:** Construct `.github/workflows/build-matrix.yml` targeting free-tier standard Linux runners.
- **Target:** Enforce automatic environment detection inside the makefiles to inject `NUM_BUILD_JOBS=1` sequential processing constraints when executing on GitHub hosted nodes.

---

### Verification for Next Session Initialization

When you start up your next chat thread or launch an automated development agent, pass this prompt command block to immediately restore context:

> "Please ingest the `AI.md` file at the root of the workspace. Review the OpenVINO CMake failure and the open tasks in Section 5, then provide the step-by-step remediation plan to resolve the Ubuntu Noble repository package gap."
