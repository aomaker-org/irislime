# Environment Configuration Engine (`config_env`)

The `config_env` script is an idempotent, sourced environment initializer for the `irislime` sandbox. It orchestrates Python virtual environments, local hardware runtimes (Intel oneAPI, OpenVINO, LiteRT), Node.js toolchains, and environment variable overrides for heterogeneous compute targets.

## 🏗️ Architectural Overview

The environment bootstrap sequence operates across several key stages to prepare your system for execution:


```

[source config_env]
│
▼
[Idempotency & Guard Checks]
│
▼
[Python .venv Activation] ───► Run: 'uv sync' (Aligns dependencies to lockfile)
│
▼
[Intel oneAPI Sourcing]   ───► Pulls: /opt/intel/oneapi/setvars.sh
│
▼
[Model Directory Mapping] ───► Interpolates: ../models (Tree-External)
│
▼
[Hardware Overrides]      ───► Injects: OpenCL selectors & Thread mitigations
│
▼
[Node.js Toolchain]       ───► Pins: Node 20 via NVM (Silent load)

```

---

## ⚙️ Core Environment Variables & Interpolation

### 1. Model Tracking (Tree-External Storage)
To keep the Git footprint agile, large language and small language model weights are **never stored inside the repository tree**. They reside in an adjacent, out-of-tree directory:
* `IRISLIME_MODELS_DIR`: Defaults dynamically to `../models`.
* `IRISLIME_TEST_MODEL`: Resolves to `${IRISLIME_MODELS_DIR}/tinyllama-1.1b-chat-v1.0.Q4_0.gguf`.

### 2. Intel oneAPI & OpenVINO Matrix Paths
* `OpenVINO_DIR`: Points directly to the CMake layout configuration (`/usr/lib/cmake/openvino2024.6.0`).
* `INTEL_OPENVINO_DIR`: Sets the core header root directory (`/usr`).

### 3. Accelerator Workload Control & Safety Hooks
* `ONEAPI_DEVICE_SELECTOR="opencl:1"`: Explicitly routes execution queries away from raw Level Zero layer states to the stable OpenCL runtime, bypassing a known `SIGSEGV` hazard when compiling or running code on certain Intel integrated GPU hardware profiles.
* `ZES_ENABLE_SYSMAN=1`: Forces the initialization of the Intel Level Zero Sysman interfaces, allowing backend tools to track hardware metrics (like temperature, frequency, and real-time GPU power usage).
* `TCM_ENABLE=1`: Suppresses `oneTBB` thread composability warnings and keeps core scaling balances well-behaved when multi-threaded applications run parallel computing tasks.

---

## 🎮 Command and Operations Flow

### Standard Loading
Initialize or verify the environment inside your active terminal session:
```bash
source config_env

```

### Force Verifying / Reloading

If you change environment paths or need to clear cached states, force a complete evaluation pass over the initialization logic:

```bash
source config_env force

```

### Tearing Down (Unsetting)

To return your shell state back to standard defaults, execute the cleanup route:

```bash
source config_env unset

```

This routine unsets all exported variables, disables the active Python virtual environment, and untracks Node Version Manager (`nvm`) bindings.

```
