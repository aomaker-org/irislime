# IrisLime Multi-Backend Compilation Matrix Control Specification

This document defines the schema, architecture, and configuration boundaries for the root project control file `matrix_control.json`. This architecture isolates environment configurations, compilation profiles, and hardware flags out of execution binaries and script logic, providing a user-driven, format-agnostic automation grid.

---

## 1. Directory Tree Structural Layout

The build execution pipeline dynamically creates isolated target subdirectories within the root `build/` directory based on the active matrix combinations. This prevents `CMakeCache.txt` cross-contamination and allows multi-backend testing to run concurrently.

irislime/
├── matrix_control.json         # ◄ Core Project Control File (User Configured)
├── matrix_control.md           # This Architectural Specification Document
├── config_env                  # Toolchain Environment Path Setup (Static)
├── Makefile                    # Top-Level Automation Build Entry
├── build/
│   ├── build_status.json       # Master State Manifest (Updated by build_runner)
│   ├── openvino_relwithdebinfo/# Isolated Binary & CMake Compilation Tree
│   ├── openvino_debug/         # Isolated Binary & CMake Compilation Tree
│   └── vulkan_release/         # Isolated Binary & CMake Compilation Tree
└── tools/
├── build_runner.py         # Ingests control schema and fires compiler passes
└── test_runner.py          # Dynamic, profile-aware smoke verification tool


---

## 2. Configuration Schema Blueprint (`matrix_control.json`)

The structural JSON file at the repository root must follow this precise object layout mapping:

```json
{
  "global_settings": {
    "min_required_disk_space_gb": 5.0,
    "default_parallel_jobs": 1
  },
  "backend_overrides": {
    "openvino": {
      "enabled": true,
      "profiles": ["RelWithDebInfo"],
      "parallel_jobs": 1,
      "cmake_cxx_flags": "-DCL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KHR=0x406E -DCL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KMT_KHR=0x406F -DCL_EXTERNAL_MEMORY_HANDLE_D3D12_HEAP_KHR=0x4070 -DCL_EXTERNAL_MEMORY_HANDLE_D3D12_RESOURCE_KHR=0x4071",
      "env_vars": {
        "GGML_OPEN_VINO_DEVICE": "GPU",
        "TCM_ENABLE": "1"
      }
    }
  }
}
Key Parameter Definitions
profiles: An array string specifying the target compilation types (Release, Debug, RelWithDebInfo). The build_runner.py parser loops through this array to create isolated build tracks sequentially.

cmake_cxx_flags: Injects hardware-level macro workarounds directly into CMake generation states (such as bypassing the Khronos OpenCL preprocessor macro race conditions).

env_vars: An explicit sub-dictionary mapping runtime controls directly into Python's subprocess.run execution shell context layer, keeping terminal states completely pristine.

3. Operational Guiding Principles
Toolchain Neutrality: config_env handles host platform paths (Intel oneAPI sourcing, venv locks). It must never absorb compiler-specific optimization parameters or variable overrides.

Fail-Fast Safety Gates: Prior to waking compiler workers, the execution script must assert that local host storage spaces do not breach the min_required_disk_space_gb constraint.

Atomic State Tracking: On completion of a compilation target, the runner updates build/build_status.json with the exact metadata map of the active binary location, which the verification engine automatically tracks.

--- END OF SPECIFICATION: matrix_control.md ---
