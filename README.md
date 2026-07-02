# irislime

An experimental hardware-software co-design sandbox optimized for edge AI inference, low-level tensor acceleration, and repository-aware agent automation. This repository serves as a live engineering playground for optimizing small language models on heterogeneous consumer hardware.

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

**IrisLime** (Iris + SLM) is a research environment designed for running local, small-scale Large Language Model (LLM) inference on Intel Iris Xe integrated graphics. It bridges Windows-hosted GPU hardware to a virtualized Linux workspace using WSL2 and the Intel oneAPI toolkit.

## Repository Vision
To maintain a lean, forensic-ready project footprint, this environment decouples application tracking from upstream inference engine source code and heavy binary model weights using clean directory boundaries.

## Target Onboarding Matrix
If you are setting up a newly cloned instance of this workspace on a machine (such as a Core12 or Core11 laptop), skip the theory and jump directly to the fast-track recipe:

👉 **[Quick Start Deployment Recipe](quick_start.md)**

## Core Workspace Architecture
- `config_env`: The primary environment gate loader. Idempotently initializes Python virtual environments and hooks into the Intel toolchain.
- `scratch/`: The local engineering sandbox. Contains incremental validation harnesses (`run_test000.sh`, `run_test002.sh`) and append-only performance ledgers.
- `tools/`: Maintained background orchestration utilities and automated diagnostic scripts.
- `models/`: Symlink pointing to your centralized local storage for GGUF model binaries.
- `llama.cpp/`: Symlink pointing to your active, custom-patched inference engine fork.

## Architectural Documentation
For a deep dive into the hardware validation pipeline, security trust model, and step-by-step environmental requirements, see the full **[Getting Started Guide](getting_started.md)**.
