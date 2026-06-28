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
