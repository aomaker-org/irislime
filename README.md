# IrisLime: Edge AI Exploration

**IrisLime** (Iris + SLM) is a research-focused environment designed to facilitate local, small-scale Large Language Model (LLM) inference on Intel Iris Xe integrated graphics, leveraging WSL2 and the Intel oneAPI toolkit.

## Vision
To provide a replicable, self-documenting workflow for running GGUF-based models on Intel hardware, bridging the gap between Windows-hosted GPU resources and Linux-based AI inference.

## Key Features
- **Modular Orchestration:** A Python-based `config_env.py` conductor handles hardware diagnostics and inference engine builds.
- **Hardware-First:** Validates the WSL2/GPU bridge (Level Zero/OpenCL) before any workload begins.
- **Portable Setup:** Decoupled from user-specific shell configurations (e.g., `.bashrc`) to ensure reproducibility.

## Project Structure
- `config_env.py`: The root orchestrator for the environment.
- `tools/`: Modular library containing hardware diagnostics and build logic.
- `models/`: Placeholder for your GGUF model files.
- `docs/`: Research notes and performance logs.

## Getting Started
See [getting_started.md](getting_started.md) to begin your setup.
