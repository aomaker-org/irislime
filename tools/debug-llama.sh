#!/usr/bin/env bash
# tools/debug-llama.sh
# Centralized debug launcher with environment bypasses

# Safety flags to prevent SYCL/LevelZero segfaults
export ZET_ENABLE_API_TRACING_LAYER=0
export ZET_ENABLE_PROGRAM_INSTRUMENTATION=0

# Ensure we have the build directory
BUILD_DIR="build_iris"

if [ ! -d "$BUILD_DIR" ]; then
    echo "[!] Error: Build directory '$BUILD_DIR' not found."
    exit 1
fi

echo "[+] Launching GDB with safety flags..."

gdb -iex "set auto-load safe-path /" \
    --args ./$BUILD_DIR/bin/llama-cli \
    -m ../models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
    -p "The future of AI is" \
    -n 50 \
    --device sycl:0
