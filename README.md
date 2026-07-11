```
# irislime

An experimental hardware-software co-design sandbox optimized for edge AI inference, low-level tensor acceleration, and repository-aware agent automation. This repository serves as a live engineering playground for optimizing small language models on heterogeneous consumer hardware.

git clone --recurse-submodules https://github.com/aomaker-org/irislime.git

See docs/quick_uv_install.md and tools/provision.sh to install necessary tools.

## 🎯 Project Intent: Portfolio to Sandbox
This repository has evolved from a static project portfolio into a live, high-velocity development sandbox. The architecture focuses on:
* **Hardware Abstraction Loops:** Bypassing driver and toolkit collisions (such as Intel oneAPI/Khronos header conflicts) to run stable execution matrices across OpenVINO, SYCL, and Vulkan backends.
* **Agent Integration:** Building and testing autonomous repository-aware scripts and hooks—leveraging environments like Jules (`jules.google.com`)—to orchestrate continuous integration and structural codebase audits.
* **Headless Automation:** Shifting away from fragile interactive console loops to robust, programmatic verification matrices (`test_runner.py`) that evaluate low-level mathematical kernel stability (`test-backend-ops`) and track high-precision telemetry.

## 🏗️ Hardware Architecture & Configuration Matrix
All build targets, parallelization thread pool allocations, compiler flags, and runtime environment overrides are declared centrally within a single engineering blueprint: `matrix_control.json`.

### Core Workflow Execution
1. **Source Runtimes:** Ensure hardware-specific environment mappings are bound to the active shell:
   ```bash
   source /opt/intel/oneapi/setvars.sh

# Drift: previous README content

# IrisLime: Edge AI Exploration Sandbox

**IrisLime** (Iris + SLM) is a research environment optimized for executing local, small-scale Large Language Model (LLM) inference on Intel Iris Xe integrated graphics. It establishes a secure compute bridge between a Windows 11 host GPU driver layer and a virtualized Linux workspace using WSL2 and the Intel oneAPI developer toolkit.

## Repository Vision
To preserve a lean, forensic-ready project footprint, this environment rigorously decouples tracking infrastructure from upstream inference engine source repositories and high-density binary model weights using isolated file allocation bounds and directory symlinks.

## Document Stratum Map
Before executing local builds or validation testing sequences, orient yourself with the authoritative documentation layers:

1. ?? **[Quick Start Deployment Recipe](quick_start.md)**: The streamlined copy-paste terminal checklist for first-time instance initialization on target developer hardware.
2. ?? **[Deep Dive Getting Started Guide](getting_started.md)**: Comprehensive guide outlining host kernel graphics modprobe parameters, environmental gate criteria, and isolated debugging harnesses.
3. ?? **[Training and Onboarding Repository](training/README.md)**: Architectural reference center documenting team Git workflow models, squash-merge rationales, and cross-OS encoding troubleshooting.

## Core Workspace Taxonomy
* `config_env`: Idempotent session environment gate loader. Initializes localized Python virtual environments and maps Intel system variables.
* `scratch/`: Engineering sandbox workspace. Holds point-in-time snapshot utilities, local backlog indices, and validation scripts (`run_test000.sh`, `run_test002.sh`).
* `tools/`: Maintained background orchestration utilities and automated headless text extraction engines.
* `models/`: Filesystem symlink pointing to your centralized local storage directory for GGUF model binaries.
* `llama.cpp/`: Filesystem symlink pointing to your active, custom-patched C++ inference engine fork repository.

---
*Verily, thou shalt hoard data.*

```
