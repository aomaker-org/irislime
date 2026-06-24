# IrisLime Hardware Telemetry Sandbox — Workspace Instructions

## Project Identity

This workspace (`~/src/irislime1`) is the IrisLime hardware telemetry sandbox: a fork of
`llama.cpp` wired to Intel Arc / Xe GPU backends (OpenVINO, SYCL, Vulkan) with a Python
byte-stream smoke test harness and automated timestamped logging.

## Environment Gate

**Before any compilation or test task**, the Intel oneAPI + venv environment must be active:
```bash
source config_env
```
The sentinel variable is `IRISLIME_READY`. If it is unset, the environment is not loaded.

## Build Targets

| Directory | Backend | Entry Point |
|-----------|---------|-------------|
| `build/openvino_release` | OpenVINO | `tools/build_openvino.sh` |
| `build/sycl_release` | SYCL/oneAPI | `tools/` (see Makefile) |
| `build/vulkan_release` | Vulkan | `tools/` (see Makefile) |
| `build/cpu_release` | CPU | `tools/` (see Makefile) |

## Log Artifacts

All logs in `logs/build/` and `logs/test/` are **append-only and immutable**. Never delete
or overwrite existing log files. New runs produce new timestamped files (`YYYYMMDD_HHMM`).

## Patch Attribution

All source patches must include a one-line attribution comment:
`/* YYYYMMDD <author> | <reason> */`

## Agent

For deep build/test/debug work in this workspace, use the **Senior Systems Validation Agent**
(`.github/agents/senior-systems-validator.agent.md`).
