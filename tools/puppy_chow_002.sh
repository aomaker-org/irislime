./build/vulkan_debug/bin/llama-cli \
  -m ../models/qwen2.5-0.5b-instruct-q4_k_m.gguf \
  -h \
  -p "<|im_start|>system\nYou are puppy_chow, a log parser.<|im_end|>\n<|im_start|>user\nAnalyze: '[Watchdog Reset]'.<|im_end|>\n<|im_start|>assistant\n" \
  -n 10

./build/vulkan_debug/bin/llama-cli \
  -m ../models/qwen2.5-0.5b-instruct-q4_k_m.gguf \
  --logprobs 3 \
  -p "<|im_start|>system\nYou are puppy_chow, a log parser.<|im_end|>\n<|im_start|>user\nAnalyze: '[Watchdog Reset]'.<|im_end|>\n<|im_start|>assistant\n" \
  -n 10



