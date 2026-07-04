# Design Decisions Log (DDL)

**Document Reference:** `docs/design_decisions.md`

**Timestamp:** 20260629_1950

**Attribution:** fekerr @ gemini (flash 3.5 + extended)

**Status:** Approved / Architecture Frozen

---

## 1. Executive Summary & Project Mission

The **Irislime** project is an engineering and research sandbox designed to optimize the execution of Small Language Models (SLMs) on edge devices. The specific target hardware consists of Intel 11th Generation (Tiger Lake) and 12th Generation (Alder Lake) architectures featuring integrated Iris Xe Graphics (iGPU).

### Strategic Career Goals

1. **Domain Expertise:** Establish verifiable competence in low-level Edge AI computing, matrix acceleration hardware, and runtime compilation toolchains.
2. **Engineering Discipline:** Demonstrate rigorous software configuration management (SCM), Infrastructure-as-Code (IaC) principles, and reproducibility models.
3. **Advanced Toolchain Utilization:** Build an environment explicitly structured for co-development between human engineers and automated AI agents (such as GitHub Copilot, Jules, and external large language models).

---

## 2. Hardware Architecture & Memory Mapping Constraints

### Decision 2.1: Enforcement of 4-bit and 5-bit Quantization Constraints

* **Context:** Intel Iris Xe graphics operate on a Unified Memory Architecture (UMA). Unlike discrete accelerators utilizing high-speed dedicated memory interfaces (GDDR6/HBM), the iGPU shares standard system memory channels (DDR4/LPDDR4X/DDR5) with the host CPU CPU cores. System memory bandwidth typically peaks between $35\text{–}60 \text{ GB/s}$.
* **Problem:** Generative LLM inference is fundamentally memory-bandwidth bound during the autoregressive phase. Loading weights from system memory into the graphics compute blocks at high precision (FP16) results in catastrophic bus thrashing, capping generation throughput far below real-time requirements ($\ge 10\text{ tokens/sec}$).
* **Decision:** The runtime framework mandates 4-bit and 5-bit quantization layers (specifically `Q4_K_M` and `Q5_K_M` GGUF profiles) as primary targets.
* **Engineering Rationale:** Quantization reduces individual weight footprints by over 70%, effectively increasing the functional bandwidth of the physical system memory bus. This ensures that models up to 3.8B parameters (e.g., Phi-3-mini) fit within local graphics hardware caches while maintaining acceptable perplexity ceilings.

### Decision 2.2: Execution Unit (EU) Density Qualification Filtering

* **Context:** Iris Xe iGPU configurations vary significantly across SKU segments, spanning from 48 EUs up to 96 EUs.
* **Decision:** The project formally filters target execution environments to chips featuring **80 to 96 EUs**.
* **Engineering Rationale:** Sub-80 EU parts lack the raw integer and dot-product execution density required to handle high-concurrency tensor operations at low latency. Targeting the 80–96 EU boundary ensures proper hardware utilization of **DP4A (Dot Product 4 Accumulate)** instructions, allowing native 4-way INT8 matrix multiplications to execute within a single clock cycle.

---

## 3. Repository Topology & Submodule Strategy

```
                           +-------------------------------------+
                           |        irislime (Main Repo)         |
                           +------------------+------------------+
                                              |
                     +------------------------+------------------------+
                     |                                                 |
                     v                                                 v
       +-------------+-------------+                     +-------------+-------------+
       |   submodules/llama.cpp/   |                     |          models/          |
       |  (Pinned Upstream Fork)   |                     |     (Idempotent Symlink)  |
       +---------------------------+                     +-------------+-------------+
                                                                       |
                                                                       v
                                                         +-------------+-------------+
                                                         | ~/.cache/irislime/models/ |
                                                         |    (Local Compute Cache)  |
                                                         +---------------------------+

```

### Decision 3.1: Downstream Submodule Forking and Version Pinning

* **Context:** The underlying computational infrastructure relies on `llama.cpp` and `ggml`. The upstream repositories undergo rapid, breaking API refactors that continuously mutate configuration graphs.
* **Decision:** `llama.cpp` is isolated within an independent downstream repository fork and mounted into the main project layout as a strict Git Submodule at `submodules/llama.cpp`. The main repository tracks an immutable, verified upstream commit hash rather than tracking rolling mainlines.
* **Engineering Rationale:** This guarantees absolute environmental determinism. Out-of-tree (OOT) compiler configurations are shielded from upstream modifications, ensuring that build failures indicate local script degradation rather than external API drift.

### Decision 3.2: Decoupled Localized Model Cache and Symbolic Link Bridges

* **Context:** Compiled binary weights for models such as Llama-3.2 and Phi-3 span several gigabytes per footprint. Tracking these via raw Git or Git-LFS inside a highly dynamic, experimental portfolio repository complicates history traversal and increases storage overhead.
* **Decision:** Large assets are stored in an external, user-space cache directory (`$HOME/.cache/irislime/models/`). The root directory repository features a directory entry named `models` which is maintained exclusively as a local symbolic link (`symlink`) pointing to this cache path.
* **Engineering Rationale:** This architecture ensures the repository footprint remains lightweight and decoupled from model weight lifetimes. Clean environments can be spun up instantly across separate nodes without transferring redundant data blocks, while maintaining a standardized path structure (`models/`) for runtime execution scripts.

---

## 4. Git Architecture & The Parallel Forensic Philosophy

### Decision 4.1: Non-Destructive History Retention vs. Squashing

* **Context:** Extended sessions with automated AI agents (e.g., context-overflow states in chat sessions) can generate drift, compiler path misalignment, and highly fractured intermediate commit logs.
* **Decision:** The repository completely rejects destructive commands like `git reset --hard` or squashing historical commits down to a single artificially clean state on working branches.
* **Engineering Rationale:** In low-level systems engineering, tracking failures is as informative as tracking successful configurations. Preserving raw, imperfect histories provides complete transparency into your troubleshooting methodology, showing hiring managers exactly how you diagnose, isolate, and resolve architectural drift.

### Decision 4.2: The Parallel Forensic Branch Isolation Workflow

* **Context:** While raw history must be preserved, presenting a totally chaotic mainline commit history degrades the usability of the repository as a professional portfolio asset.
* **Decision:** When an AI tool session experiences structural drift, the active working branch is immediately frozen, timestamped, and pushed to a remote tracking line (e.g., `forensics/ai-drift-session-20260629`). The primary mainline development branch (`develop` or `main`) is then restored, and corrections are merged via structured reconciliation commits using metadata fields (`Forensics-Source:`, `AI-Tools-Utilized:`).
* **Engineering Rationale:** This approach balances the need for an authentic audit trail with the readability expected of a production-ready engineering repository.

---

## 5. Git-Native Supply Chain Security (Smudge/Clean Filter Architecture)

### Decision 5.1: Localized Configuration of Content Telemetry Engines

* **Context:** Automated tools require immediate visibility into their execution context (active commit hashes, target branch topology, configuration footprints) to prevent runtime state divergence. Hardcoding these details directly into source scripts, however, generates constant local diff noise and dirties the working directory.
* **Decision:** Deploy a formal Git Content Filter platform via local `.gitattributes` routing configurations mapped to automated script infrastructure files (`config_env`, `infra/bootstrap_models.sh`).

```
   [Git Object Store]             [Smudge Filter via sed]           [Local Working Tree]
+----------------------+         +------------------------+        +----------------------+
| INTEGRITY_COMMIT=    | ------> | Injects active short   | ------> | INTEGRITY_COMMIT=    |
|   "TODO"             |         | hash dynamically       |        |   "a1b2c3d"          |
+----------------------+         +------------------------+        +----------------------+
                                                                               |
                                                                               v
   [Git Index/Staging]            [Clean Filter via sed]            [Developer Code Edits]
+----------------------+         +------------------------+        +----------------------+
| INTEGRITY_COMMIT=    | <------ | Scrubs dynamic metrics | <----- | User alters runtime  |
|   "TODO"             |         | back to template string|        | scripts locally      |
+----------------------+         +------------------------+        +----------------------+

```

* **Engineering Rationale:** * **The Clean Path:** Prior to staging and committing changes, the filter automatically scrubs runtime metrics back to standard templates: `INTEGRITY_COMMIT="TODO"`. The central Git database only ever tracks clean, pristine file blueprints.
* **The Smudge Path:** Upon checkout or instantiation, Git passes the template through an inline stream editor (`sed`), injecting the active environment data directly onto disk. This allows scripts to remain fully self-documenting and context-aware during runtime without generating untracked file modifications.



---

## 6. Environment Initialization & Shell Prompt Customization

### Decision 6.1: Subshell Execution Prevention Guardrails

* **Context:** Environment managers must modify the active parent environment context (exporting environment paths, mounting virtual environment indicators, linking library entry points). Running an initialization script as a decoupled executable subshell (`./config_env`) fails to apply these definitions to the shell session.
* **Decision:** The `config_env` script integrates an explicit runtime validation guard:
```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    exit 1
fi

```


* **Engineering Rationale:** This guard catches execution errors early, forcing the script to terminate safely with an error message before executing downstream hooks. This prevents partial state contamination and guides users to leverage correct sourcing mechanics (`source config_env`).

### Decision 6.2: Context-Aware, Literal ASCII Prompt Topology for Clipboard Safety

* **Context:** Engineers working across the Windows 11 WSL2 Ubuntu boundary frequently copy terminal logs, console stack traces, and environment diagnostics to share with remote AI agents or check-in files. Intricate, multi-color modern prompts containing custom fonts or Unicode emojis frequently introduce encoding corruption into clipboard parsers.
* **Decision:** The system prompt (`PS1`) is locked down to strict ASCII characters, featuring explicit newline separation boundaries before input fields:
```bash
export PS1="\[\e[0;36m\][irislime]\[\e[0m\]\[\e[0;33m\][${INTEGRITY_BRANCH}:${INTEGRITY_COMMIT}]\[\e[0m\] \[\e[0;32m\]\w\[\e[0m\]\n$ "

```


* **Engineering Rationale:** 1. Ensures that copied command-line traces paste cleanly into any LLM chat window or document parser without rendering artifacts or corrupted block symbols.
2. The trailing newline ensures that the actual command executed always begins at column zero on a fresh line. This simplifies data parsing and log slicing for automated testing scripts and agent workflows.

---

## 7. Modular Out-of-Tree (OOT) Matrix Build Architecture

### Decision 7.1: Rejection of Monolithic Configuration Trackers

* **Context:** Compiling `llama.cpp` for Intel hardware requires testing across multiple driver abstractions, including SYCL (Intel Level Zero/oneAPI), OpenVINO, and raw Vulkan. Combining all target variants into a single, massive configuration file leads to structural fragility and unreadable recipes.
* **Decision:** Evolve the automation pipeline into a decentralized configuration model using GNU Make's internal `include` mechanism, splitting targets out into independent sub-makefiles inside `infra/make/`:
* `infra/make/base.mk` (Shared logic, environment gates, Python venv orchestration)
* `infra/make/sycl.mk` (oneAPI compiler mappings: `icx`/`icpx`, Level Zero variables)
* `infra/make/openvino.mk` (OpenVINO intermediate graph engines)
* `infra/make/vulkan.mk` (Generic Vulkan compute fallback pipelines)



### Decision 7.2: Isolated Multi-Target Out-of-Tree Output Sandboxing

* **Context:** Compiling separate accelerator backends within the same directory tree leaves behind cached build artifacts that contaminate downstream targets, leading to silent linkage bugs or incorrect optimization flags.
* **Decision:** Each driver target compiles into an isolated subdirectory inside the central build tree:
```text
build/sycl/
build/openvino/
build/vulkan/

```


Traversing out-of-tree to point to the core submodule is handled via exact relative lookups: `../../$(ENGINE_DIR)`.
* **Engineering Rationale:** This sandboxing guarantees that a build run for one driver target cannot pollute the environment of another. It allows for clean, parallel cross-backend profiling and execution testing.

### Decision 7.3: Low-Overhead Build Telemetry Capture

* **Context:** Long-term validation tracking requires clear metrics on how different compilation flags impact build efficiency over time.
* **Decision:** Every build run automatically routes its standard output and errors into an isolated log file (`build_target_timestamp.log`) using standard Unix redirection (`>> log 2>&1`). It calculates total elapsed time using the shell epoch timer (`date +%s`), logging the results to a structured tracking file (`telemetry_builds.csv`).
* **Engineering Rationale:** This architecture prevents verbose build output from flooding the user terminal or clogging CI/CD runners, while building a structured dataset that can be easily parsed for downstream analytics.

---

# end of docs/design_decisions.md
