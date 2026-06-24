#!/bin/bash
# 20260620 fekerr
# Tool: run_demo_20260620-batch.sh
# Purpose: Benchmark matrix (Baseline, Patch-CPU, Patch-GPU) in non-interactive batch mode.
# Dependency: config_env

source config_env

# Function to run inference in strict batch mode
run_batch_0() {
    local cmd="$1"
    # Ensure stdin is completely disconnected
    "$cmd" \
      -m models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
      -p "The future of AI is" \
      -n 50 \
      --no-display-prompt \
      --no-interactive < /dev/null
}

# the filter should probably be a python script that says when multiple repeats are detected and filtered... collect data for 5-10 sec before spamming console?
#
run_batch_1() {
    local cmd="$1"
    # Create a temporary pipe or just use grep -v to filter out the known noise
    # We send EVERYTHING to the log, but only clean output to the screen
    "$cmd" \
      -m models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
      -p "The future of AI is" \
      -n 50 \
      --no-display-prompt \
      --no-interactive 2> >(tee -a "$LOG_FILE" >&2) | tee -a "$LOG_FILE" | grep -v "get_memory_info"
}

# wrapper filters?
run_batch() {
    local cmd="$1"
    # Execute without the pipe to avoid 'tee' errors. 
    # The 'record.sh' wrapper will handle the logging.
    "$cmd" \
      -m models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
      -p "The future of AI is" \
      -n 50 \
      --no-display-prompt 2>&1
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
  
  # Note: Adding --device SYCL0 here for GPU acceleration
  echo "" | ./llama.cpp/build_iris/bin/llama-cli \
    -m models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
    -p "The future of AI is" \
    -n 50 \
    --no-display-prompt \
    --device SYCL0
)

echo -e "\n--- Matrix Test Complete. ---"
