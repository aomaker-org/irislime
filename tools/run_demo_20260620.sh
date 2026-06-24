#!/bin/bash
# run_demo.sh - Automated benchmark comparison

source config_env

# 1. CPU Run
echo "--- Starting CPU Inference Demo ---"
# Note: Try '--device cpu' or just omitting the --device flag if it defaults to CPU
./llama.cpp/build_iris/bin/llama-cli \
  -m models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
  -p "The future of AI is" \
  -n 50 --no-display-prompt

echo -e "\n--- CPU Demo Complete. Switching to GPU... ---\n"

# 2. GPU Run (Sub-shell for environment isolation)
(
  export LD_LIBRARY_PATH="$HOME/src/irislime/dummy_libs:$LD_LIBRARY_PATH"
  export ZES_ENABLE_SYSMAN=1
  export ZET_ENABLE_LAYER_L0_TRACING=0
  export ZET_ENABLE_API_TRACING_LAYER=0
  
  ./llama.cpp/build_iris/bin/llama-cli \
    -m models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
    -p "The future of AI is" \
    -n 50 --no-display-prompt --device SYCL0
)

echo -e "\n--- Demo Complete. ---"

