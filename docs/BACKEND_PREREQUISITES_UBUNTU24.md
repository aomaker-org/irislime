# Backend Prerequisites (Ubuntu 24.04 / WSL2)

Purpose: install and verify prerequisites for alternative backends in this repo (`Vulkan`, `OpenVINO`), then run backend-specific configure/build checks.

Environment context (this machine):
- Ubuntu 24.04 (WSL2)
- `vulkaninfo`: present
- `glslc`: missing
- `clinfo`: missing
- OpenVINO CMake package: missing (`OpenVINOConfig.cmake` not found)

## 1) Vulkan backend prerequisites

`llama.cpp` Vulkan configuration failed because `glslc` was missing.

### Install

```bash
sudo apt update
sudo apt install -y glslc vulkan-tools
```

Optional diagnostics:

```bash
sudo apt install -y clinfo
```

### Verify

```bash
glslc --version
vulkaninfo | head -40
```

### Configure/build probe

```bash
cd /home/fekerr/src/irislime1
mkdir -p build/vulkan_release
cd build/vulkan_release
cmake ../../llama.cpp \
  -DGGML_VULKAN=ON \
  -DGGML_SYCL=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF \
  -DGGML_BUILD_TESTS=OFF -DGGML_BUILD_EXAMPLES=OFF
make -j$(nproc)
```

## 2) OpenVINO backend prerequisites

`llama.cpp` OpenVINO configuration failed because CMake could not find:
- `OpenVINOConfig.cmake`
- `openvino-config.cmake`

Ubuntu default repos typically do not include the full OpenVINO C++ dev package required by this build.

### Option A (recommended): Intel OpenVINO archive install (dev)

1. Download OpenVINO archive for Linux from Intel.
2. Extract to a fixed path, e.g.:
   - `/opt/intel/openvino_2024`
3. Source environment:

```bash
source /opt/intel/openvino_2024/setupvars.sh
```

4. Verify CMake package visibility:

```bash
find /opt/intel/openvino_2024 -name "OpenVINOConfig.cmake" | head -5
```

5. Configure/build probe:

```bash
cd /home/fekerr/src/irislime1
mkdir -p build/openvino_release
cd build/openvino_release
cmake ../../llama.cpp \
  -DGGML_OPENVINO=ON \
  -DGGML_SYCL=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF \
  -DGGML_BUILD_TESTS=OFF -DGGML_BUILD_EXAMPLES=OFF \
  -DOpenVINO_DIR=/opt/intel/openvino_2024/runtime/cmake
make -j$(nproc)
```

Note: the exact `OpenVINO_DIR` subpath may vary by OpenVINO version. Use the `find` command result above.

### Option B: Explicit `CMAKE_PREFIX_PATH`

If you have OpenVINO in a custom path:

```bash
cmake ../../llama.cpp \
  -DGGML_OPENVINO=ON \
  -DCMAKE_PREFIX_PATH="/path/to/openvino"
```

## 3) Quick feasibility matrix (current state)

Before installing prerequisites:
- CPU backend: buildable and launches
- SYCL backend: buildable, runtime unstable in this environment
- Vulkan backend: blocked by missing `glslc`
- OpenVINO backend: blocked by missing OpenVINO CMake config

## 4) WSL-specific notes

- Prefer managing SDK installs from Windows host policy where practical.
- Keep build execution in WSL, but keep dependency state explicit and reproducible.
- Record final backend dependency choices in your forensic log.

## 5) Optional package list for convenience

```bash
sudo apt update
sudo apt install -y \
  build-essential cmake pkg-config git \
  glslc vulkan-tools clinfo
```

(Does not include OpenVINO dev package; that usually requires Intel-provided install.)
