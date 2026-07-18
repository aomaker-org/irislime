# IrisLime Core Engine Integration Platform

Welcome to the IrisLime core local validation and edge AI workspace. This platform acts as an automated, unified integration layer optimized specifically for the Ubuntu 26.04 LTS / WSL2 subsystem running on Core12 multi-backend workstation architectures.

The repository manages advanced local hardware acceleration implementations (Intel SYCL, OpenVINO, and Vulkan) for language model inference while serving as a local computing sandbox for model training and lossy text data compression research.

---

## Core Architectural Topology

The workspace is organized into explicit structural domains to separate engine sources, automated pipelines, orchestration telemetry logs, and instructional sandboxes:

* **`fekerr-dev/`** - Centralized PowerShell 7 host toolkit and container bootstrap stratum (`ps7/`, `irislime_ubu26_init/`, workspace integrity signers).
* **`infra/`** - Authoritative system makefile macro engines (`vulkan.mk`, `sycl.mk`) managing localized compilation parameters, profile layouts, and environment checks.
* **`llama.cpp/`** - Local framework fork version-locked to the active Intel performance patch vectors (`remotes/origin/feature/sycl-openvino-intel-patches`).
* **`deps/`** - Immutable system and optimization dependencies, including the core `litert-lm` engine tracks.
* **`deps/learning/`** - Localized repository forks owned by `aomaker-org` containing foundational educational platforms for machine learning verification.
* **`tools/`** - Intelligent python script utilities and execution wrappers managing cross-backend builds, hardware diagnostics, and inference loops.
* **`logs/`** - Telemetry datastores split cleanly into persistent build journals (`logs/builds/`) and structured test metrics (`logs/tests/`).

---

## Integrated Automation Features

### 1. Unified Profile Build Orchestrator (`tools/build_runner.py`)
A hardened compilation wrapper that enforces safe process isolation for macro builds. It satisfaction-checks Python 3.14 text-mode pipe specifications and features a three-tiered watchdog system:
* **Standard Output Stream Scanning:** Non-blocking queue reads prevent terminal buffer deadlocks.
* **Filesystem Inode Ingestion:** Tracks real-time log allocation (`st_size`) to confirm background compilation activity even if stdout is dark.
* **Parameterized Heartbeat Traps:** Actively reads text pulses committed to `.irislime_heartbeat` to expand or shrink the silence counter budget on the fly.

### 2. Profiled Verification Engine (`tools/bbptests_runner.py`)
A adaptive, zero-maintenance test harness that completely discards brittle, hardcoded execution lists. By dynamically probing target binary folders, it extracts and isolates compiled executables matching the `test-` prefix. It runs them inside their native directories to protect relative resource mapping paths, uses string replacement gates (`errors="replace"`) to cleanly ingest raw token outputs without throwing Unicode decoder crashes, and populates interactive horizontal tickers.

### 3. Capabilities Help-Smoke Tester (`bbpsmoke_runner`)
Leverages the dynamic engine to run high-velocity linkage validation across every compiled binary in the multi-backend directory tree. By passing the `-h` flag to all discovered assets, it verifies that library dependencies resolve successfully, isolates shared object faults (`LINK_ERR`), and stores help catalogs.

### 4. Scrolling Hardware Watchdog (`tools/compiler_watch`)
A non-destructive, non-blocking process tree visualizer. It eliminates screen-clearing operations to protect your terminal app's historical scrollback memory, formats parent-child lines natively, extracts thread allocations, traces core affinity matrix variables (`PSR`), and supports quiet escapes via `q`.

### 5. Automated Data Ingestion (`tools/model_manager.py`)
A standard-library-driven network provisioner that handles asset transfers directly from Hugging Face repositories using chunked urllib pipelines. It features an inline progress metronome, validates file sizing targets, and automatically senses local `HF_TOKEN` variables to inject secure bearer authorization.

---


