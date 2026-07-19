#!/bin/bash
set -e
echo "Building llama.cpp for Raspberry Pi (ARM64 CPU)..."
cd llama.cpp
mkdir -p build_rpi
cd build_rpi
cat <<CMAKE_TOOLCHAIN_EOF > toolchain-aarch64.cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
CMAKE_TOOLCHAIN_EOF
cmake .. -DCMAKE_TOOLCHAIN_FILE=toolchain-aarch64.cmake -DCMAKE_BUILD_TYPE=Release -DGGML_NATIVE=OFF -DGGML_CPU_ARM_ARCH=armv8-a
make -j$(nproc)
echo "Raspberry Pi build complete in llama.cpp/build_rpi/"
