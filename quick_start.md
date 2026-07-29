# IrisLime Quick Start Deployment Recipe

This guide details the deployment sequence for bringing up the IrisLime development environment on WSL2 / Windows 11 host workstations.

---

## 1. Local & External Model Storage Topography

Model weights reside decoupled from code compilation trees to preserve repository cleanliness:
- **POSIX Model Path (`LOCAL_AI_MODELS_DIR`)**: `/mnt/c/AI_models` (Windows 11 host storage) or sibling path `../models/`.
- **Windows Host Path (`WIN_AI_MODELS_DIR`)**: `C:\AI_models`.

```bash
# Verify model directory topography
ls -la /mnt/c/AI_models
```

---

## 2. Environment Initialization & Dependency Sync

Initialize local Python virtual environments and sync toolchain dependencies via `uv`:

```bash
cd ~/src/irislime-pr-36

# Sync virtual environment dependencies via uv
uv sync
```

---

## 3. Parameterized Session Boot (`config_env` & `config_win11`)

Source `config_env` (or `config_win11` under Windows Git Bash) with an optional prompt tag:

```bash
# Load environment with custom prompt tag
. config_env vulkan_debug

# Under Windows Git Bash:
. config_win11 vulkan_debug
```
*Note: Always **source** using `.` or `source`.*

---

## 4. 1:1 Utility Aliases & Tooling Commands

- **`files2clip [targets]`**: Pack workspace files into the system clipboard buffer (supports `-a` / `--everything` for full filesystem traversal).
- **`build_runner`**: Run compilation passes via `uv run tools/build_runner.py`.
- **`test_runner`**: Run test suite via `uv run tools/test_runner.py`.
- **`run-bench.sh`**: Execute inference performance benchmarks.

---

## 5. Strict Observability Standard (`*** NO PIPE TO NULL ***`)

All execution tools, scripts, and Makefiles strictly enforce zero stream discarding. No output is piped to `/dev/null`; stdout/stderr streams remain 100% visible or are logged directly to `./logs/` or `/tmp/` audit files.
