# IrisLime Consolidated Project Documentation

*Generated dynamically from project markdown files.*

## Core Architectural Topology
The workspace is organized into explicit structural domains to separate engine sources, automated pipelines, orchestration telemetry logs, and instructional sandboxes:

* **`fekerr-dev/`** - Centralized PowerShell 7 host toolkit and container bootstrap stratum (`ps7/`, `irislime_ubu26_init/`, workspace integrity signers).
* **`infra/`** - Authoritative system makefile macro engines (`vulkan.mk`, `sycl.mk`) managing localized compilation parameters, profile layouts, and environment checks.
* **`llama.cpp/`** - Local framework fork version-locked to the active Intel performance patch vectors (`remotes/origin/feature/sycl-openvino-intel-patches`).
* **`deps/`** - Immutable system and optimization dependencies, including the core `litert-lm` engine tracks.
* **`deps/learning/`** - Localized repository forks owned by `aomaker-org` containing foundational educational platforms for machine learning verification.
* **`tools/`** - Intelligent python script utilities and execution wrappers managing cross-backend builds, hardware diagnostics, and inference loops.
* **`logs/`** - Telemetry datastores split cleanly into persistent build journals (`logs/builds/`) and structured test metrics (`logs/tests/`).
* **`jules-ai/`** - Dynamic project documentation and logic isolation directory.

## Core Operational Guardrails
* **The Immutable Logging Paradigm:** Practice a strict "never delete, always append" forensic logging philosophy for file records and transaction tracking. The use of read-only enforcement on archives remains an open exploration (demonstrated via `tools/enforce_readonly.sh`) rather than an active restriction.
* **Cross-Platform Path Alignment:** Never utilize virtualized drive-letter mappings (`G:`, `H:`). All data references between host Windows and guest Linux boundaries must evaluate via native cross-platform loopbacks (`\\wsl.localhost\Ubuntu-24.04\`) or localized home nodes (`--cd ~`).
* **Environment Isolation Guardrails:** All Python execution steps must route exclusively through the native `uv` toolchain manager. Avoid contaminating global system environments by running self-contained, ephemeral sandboxes (`uv run`).

## Unified Profile Build Orchestrator
A hardened compilation wrapper that enforces safe process isolation for macro builds (`tools/build_runner.py`). Target matrices are defined within `matrix_control.json` and optionally modeled into `infra/Containerfile.matrix` following standard OCI parameters.

## Storage Matrix and External Tracking
* Storage arrays span NVMe and cloud arrays (`gaom:`, `gdrive:`, `onedrive:`) using external manifest tools.
* `rclone` and associated "chunker" mounts act as the standard ingress/egress tool for migrating large models and cold storage telemetry. This architecture avoids Git repository bloat.
* To conserve space on developer constrained machines, large local binaries/archives should be managed via manifest trackers (e.g. DVC) or replaced with `.stub`/`.pointer` files mapping to their cloud equivalents.
