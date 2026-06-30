# Refactored sycl_run_test.sh
./build/sycl/bin/llama-completion \
  -m "$IRISLIME_MODELS_DIR/Llama-3.2-1B-Instruct-Q4_K_M.gguf" \
  -p "The future of open-source edge AI acceleration is" \
  -n 30 \
  -t 2 \
  -ngl 99
