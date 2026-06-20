#!/bin/bash
# 20260620 fekerr
# Tool: run_demo_20260620-batch.sh
# Purpose: Benchmark matrix (Baseline, Patch-CPU, Patch-GPU) 

source config_env

run_batch() {
    local cmd="$1"
    local device_arg="$2"
    
    # Executing the command directly. 
    # record.sh wrapper will handle the piping to log.
    "$cmd" \
      -m models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
      -p "The future of AI is" \
      -n 50 \
      --no-display-prompt \
      $device_arg
}

echo "--- [1/3] Baseline: Original Build (CPU) ---"
run_batch "./llama.cpp/build/bin/llama-cli"

echo -e "\n--- [2/3] Patch Build: Default (CPU Fallback) ---\n"
(
  export LD_LIBRARY_PATH="$HOME/src/irislime/dummy_libs:$LD_LIBRARY_PATH"
  run_batch "./llama.cpp/build_iris/bin/llama-cli"
)

echo -e "\n--- [3/3] Patch Build: Hardware Accelerated (SYCL0) ---\n"
(
  export LD_LIBRARY_PATH="$HOME/src/irislime/dummy_libs:$LD_LIBRARY_PATH"
  export ZES_ENABLE_SYSMAN=1
  export ZET_ENABLE_LAYER_L0_TRACING=0
  export ZET_ENABLE_API_TRACING_LAYER=0
  
  run_batch "./llama.cpp/build_iris/bin/llama-cli" "--device SYCL0"
)

echo -e "\n--- Matrix Test Complete. ---"
