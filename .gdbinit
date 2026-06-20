# Specific to IrisLime project
# 1. Add specific paths for Intel SYCL symbol scripts
add-auto-load-safe-path /opt/intel/oneapi/compiler/2026.0/lib/

# 2. Set default arguments for the app so you don't type them
set args -m ../models/Llama-3.2-1B-Instruct-Q4_K_M.gguf -p "The future of AI is" -n 50 --device sycl:0

# 3. Define a custom command for your 'twins' to use
define run-sycl
  set environment ZET_ENABLE_API_TRACING_LAYER=0
  set environment ZET_ENABLE_PROGRAM_INSTRUMENTATION=0
  run
end
document run-sycl
  Runs llama-cli with the required SYCL safety environment variables.
end
