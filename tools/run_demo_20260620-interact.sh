#!/bin/bash
# 20260620 fekerr
# Tool: run_demo_20260620.sh
# Purpose: Benchmark matrix: Baseline CPU, Patch Build (CPU), Patch Build (SYCL)
# Dependency: config_env

source config_env

# 1. Baseline: Original CPU Build
echo "--- [1/3] Baseline: Original Build (CPU) ---"
./llama.cpp/build/bin/llama-cli \
  -m models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
  -p "The future of AI is" -n 50 --no-display-prompt

# 2. Patch Build: Default/No-Device (CPU Fallback)
echo -e "\n--- [2/3] Patch Build: Default (CPU Fallback) ---\n"
(
  export LD_LIBRARY_PATH="$HOME/src/irislime/dummy_libs:$LD_LIBRARY_PATH"
  ./llama.cpp/build_iris/bin/llama-cli \
    -m models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
    -p "The future of AI is" -n 50 --no-display-prompt
)

# 3. Patch Build: Hardware Accelerated
echo -e "\n--- [3/3] Patch Build: Hardware Accelerated (SYCL0) ---\n"
(
  export LD_LIBRARY_PATH="$HOME/src/irislime/dummy_libs:$LD_LIBRARY_PATH"
  export ZES_ENABLE_SYSMAN=1
  export ZET_ENABLE_LAYER_L0_TRACING=0
  export ZET_ENABLE_API_TRACING_LAYER=0
  
  ./llama.cpp/build_iris/bin/llama-cli \
    -m models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
    -p "The future of AI is" -n 50 --no-display-prompt --device SYCL0
)

echo -e "\n--- Demo Matrix Complete. ---"
