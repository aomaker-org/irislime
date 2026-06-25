import subprocess
import time
import os

# Define the paths to your compiled binaries
BUILD_DIR = "./" # Adjust this to your root build directory
MODEL_PATH = "./tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"

# The test matrix mapping target names to their specific executable files
TARGETS = {
    "CPU (Debug)":        os.path.join(BUILD_DIR, "cpu_debug", "llama-cli"),
    "CPU (Release)":      os.path.join(BUILD_DIR, "cpu_release", "llama-cli"),
    "OpenVINO":           os.path.join(BUILD_DIR, "openvino_release", "llama-cli"),
    "SYCL (Release)":     os.path.join(BUILD_DIR, "sycl_release", "llama-cli"),
    "SYCL (DebugInfo)":   os.path.join(BUILD_DIR, "sycl_relwithdebinfo", "llama-cli"),
    "Vulkan":             os.path.join(BUILD_DIR, "vulkan_release", "llama-cli"),
}

# Simple prompt instruction to load, generate 1 token, and exit
TEST_ARGS = ["-m", MODEL_PATH, "-p", "Test", "-n", "1", "--gpu-layers", "99"]

print(f"| Target Name | Status | Latency (ms) | Notes / Error Snippet |")
print(f"| :--- | :--- | :--- | :--- |")

for name, exe_path in TARGETS.items():
    if not os.path.exists(exe_path):
        print(f"| {name} | ❌ Missing | N/A | Executable not found at path |")
        continue

    start_time = time.time()
    try:
        # Run the binary with a strict 15-second timeout to catch hangs
        result = subprocess.run(
            [exe_path] + TEST_ARGS,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=15
        )
        
        elapsed = int((time.time() - start_time) * 1000)
        
        if result.returncode == 0:
            print(f"| {name} |  Passed | {elapsed}ms | Natively executed successfully |")
        else:
            # Grab the last line of stderr to see if it failed on a missing driver or BF16 error
            err_line = result.stderr.strip().split('\n')[-1] if result.stderr else "Unknown Exit Code"
            print(f"| {name} | 💥 Crashed | {elapsed}ms | Code {result.returncode}: {err_line[:40]}... |")
            
    except subprocess.TimeoutExpired:
        print(f"| {name} | ⏳ Timeout | N/A | Process hung (likely driver deadlock) |")
    except Exception as e:
        print(f"| {name} | ❓ Failed | N/A | Execution error: {str(e)[:40]} |")
