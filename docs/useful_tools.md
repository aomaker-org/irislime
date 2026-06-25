# Useful Tools Inventory

Purpose: track tools that were missing or problematic during work, with quick install guidance and why they matter.

Policy:
- Append-only updates.
- Record the first time a missing tool is encountered.
- Include date, command attempted, impact, and install steps.

## Missing Tools Seen In This Session

### 2026-06-22 - ripgrep (`rg`)
- Command attempted:
  - `rg -n "..." <paths>`
- Observed result:
  - `Command 'rg' not found`
- Impact:
  - Slower source search workflows (fallback to `grep -R`).
- Why useful:
  - Fast recursive search over large codebases.
  - Better ergonomics for code archaeology and backend option discovery.
- Install (Ubuntu/WSL):
  - `sudo apt update && sudo apt install -y ripgrep`
- Verify:
  - `rg --version`

### 2026-06-22 - `glslc` (Vulkan shader compiler)
- Command attempted:
  - Vulkan backend CMake configure with `-DGGML_VULKAN=ON`
- Observed result:
  - `Could NOT find Vulkan (missing: glslc)`
- Impact:
  - Vulkan backend cannot be configured/built.
- Why useful:
  - `llama.cpp` Vulkan backend compile path requires shader compilation tooling.
- Install (Ubuntu/WSL):
  - `sudo apt update && sudo apt install -y glslc vulkan-tools`
- Verify:
  - `glslc --version`

### 2026-06-22 - `clinfo` (OpenCL diagnostic tool)
- Command attempted:
  - environment diagnostics for compute runtime visibility
- Observed result:
  - `clinfo` missing
- Impact:
  - Reduced visibility into OpenCL/OpenVINO-capable runtime devices.
- Why useful:
  - Quick sanity checks for GPU/accelerator device exposure.
- Install (Ubuntu/WSL):
  - `sudo apt update && sudo apt install -y clinfo`
- Verify:
  - `clinfo | head -40`

### 2026-06-22 - OpenVINO CMake config package
- Command attempted:
  - OpenVINO backend CMake configure with `-DGGML_OPENVINO=ON`
- Observed result:
  - `Could not find OpenVINOConfig.cmake / openvino-config.cmake`
- Impact:
  - OpenVINO backend cannot be configured/built.
- Why useful:
  - `llama.cpp` OpenVINO backend requires OpenVINO C++ development package, not just Python runtime.
- Install path:
  - Install OpenVINO dev distribution (Intel package/archive), then set `OpenVINO_DIR`.
- Verify:
  - `find /opt -name OpenVINOConfig.cmake | head -5`

## Candidate Tools To Add If Needed (Not missing yet)

These are commonly useful for this repo, but have not been confirmed missing:
- `jq` for robust JSON parsing in shell scripts.
- `gdb` for segmentation fault stack traces.
- `clinfo` / `sycl-ls` for GPU runtime/device visibility diagnostics.

If any of these are missing during execution, add a timestamped section above in the same format.
