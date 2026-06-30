--- BEGIN FILE: AI.md | Size: 4120 bytes | SHA256: TODO ---
# IrisLime LLM Context Architecture & Session State Laws
# Filename:    AI.md
# Location:    Repository Root (/)
# Timestamp:   20260630_1110
# Attribution: fekerr & Gemini (20260630_1110 / flash 3.5 extended)
# Purpose:     Immutable Context-Transfer Interface and Core Execution Laws

## 1. Project Taxonomy, Engineering Mission, & Interface Conventions
IrisLime is a highly optimized, modular, out-of-tree multi-target build pipeline wrapping the `llama.cpp` / `ggml` ecosystem. The project is specifically engineered to maximize local edge inference performance and build-time safety across asymmetric, heterogeneous hybrid CPU architectures and virtualized consumer iGPUs under WSL2 (Ubuntu 24.04 LTS Noble).

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
3. **Universal Trailer Policy:** Every file (including markdown reference notes) must terminate with a matching comment block repeating the file's relative home location to facilitate tail-scrolled visual confirmation and regex log slicing.

---

## 2. Active System Topology & Telemetry Maps

### Host Hardware Blueprint (Validation Station)
- **Processor:** Intel Core i7-1255U (Heterogeneous: 2 Physical P-Cores with SMT / 8 E-Cores without SMT).
- **Available Guest RAM:** 7 GB (Constrained Virtualized Page Allocation via WSL2).
- **Target Accelerator:** Intel Iris Xe Integrated Graphics (96 EUs, Architecture ID `0x46a8`).
- **Hypervisor Boundary:** Windows 11 Host to Ubuntu 24.04 LTS Guest passing through `/dev/dxg`.

### Automated Build Parameters
- **`NUM_BUILD_JOBS := 1`**: Fixed sequential compilation constraint mandated by guest hypervisor RAM limits (7 GB total / 4 GB required per heavy compiler thread) to prevent out-of-memory swap thrashing.
- **`NUM_INF_THREADS := 2`**: Automatically mapped to lock execution matrices strictly to physical Performance Core boundaries, leaving E-cores free for OS tasks.
- **Runtime Hypervisor Override:** The system requires `ONEAPI_DEVICE_SELECTOR="opencl:1"` to bypass the Level Zero `0x1` hypervisor pointer pass-through segmentation crash (`SIGSEGV`).

---
# EPILOG: End of File Descriptor for AI.md
---
