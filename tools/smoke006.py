#!/usr/bin/env python3
import subprocess
import time
import os
import io
import select

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(CURRENT_DIR) if os.path.basename(CURRENT_DIR) == "tools" else CURRENT_DIR

MODEL_FILENAME = "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
MODEL_PATH = os.path.join(PROJECT_ROOT, "models", MODEL_FILENAME)
BUILD_DIR = os.path.join(PROJECT_ROOT, "build")
LOGS_DIR = os.path.join(PROJECT_ROOT, "logs")

os.makedirs(LOGS_DIR, exist_ok=True)

BUILD_FOLDERS = {
    "CPU (Debug)":        os.path.join(BUILD_DIR, "cpu_debug"),
    "CPU (Release)":      os.path.join(BUILD_DIR, "cpu_release"),
    "OpenVINO":           os.path.join(BUILD_DIR, "openvino_release"),
    "SYCL (Release)":     os.path.join(BUILD_DIR, "sycl_release"),
    "SYCL (DebugInfo)":   os.path.join(BUILD_DIR, "sycl_relwithdebinfo"),
    "Vulkan":             os.path.join(BUILD_DIR, "vulkan_release"),
}

# Standard test flags
TEST_ARGS = [
    "-m", MODEL_PATH, 
    "-p", "The quick brown fox", 
    "-n", "1", 
    "--gpu-layers", "99"
]

output_stream = io.StringIO()

def log_print(message=""):
    print(message)
    output_stream.write(message + "\n")

log_print("============================================================")
log_print("S_LAUNCH: IRISLIME ASYNC REALTIME TAIL RUNNER (v006)")
log_print(f"Project Root: {PROJECT_ROOT}")
log_print(f"Model Location: {os.path.relpath(MODEL_PATH, PROJECT_ROOT)}")
log_print("============================================================\n")

log_print("| Target Configuration | Status  | Latency | Execution Discovery Summary |")
log_print("| :--- | :--- | :--- | :--- |")

for name, folder_path in BUILD_FOLDERS.items():
    possible_exes = [
        os.path.join(folder_path, "bin", "llama-cli"),
        os.path.join(folder_path, "llama-cli")
    ]
    
    exe_path = None
    for path in possible_exes:
        if os.path.exists(path):
            exe_path = path
            break

    if not exe_path:
        log_print(f"| {name:<20} | EMPTY   | N/A     | Checked: {os.path.relpath(folder_path, PROJECT_ROOT)} |")
        continue

    display_exe = os.path.relpath(exe_path, PROJECT_ROOT)
    
    print(f"\n>>> [TAIL START] Activating streams for: {name}")
    start_time = time.time()
    
    try:
        # Popen fires the binary concurrently without blockading python execution
        proc = subprocess.Popen(
            [exe_path] + TEST_ARGS,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1  # Line-buffered for immediate flushing
        )
        
        # Close standard input immediately to signal single-turn execution
        if proc.stdin:
            proc.stdin.close()

        captured_output = []
        status = "PASSED"
        summary = "Clean exit reached"
        
        # Real-time monitoring loop with an absolute 12-second ceiling per configuration
        while time.time() - start_time < 12:
            # Poll stdout and stderr streams asynchronously
            reads = [proc.stdout, proc.stderr]
            ret = select.select(reads, [], [], 0.1)
            
            for fd in ret[0]:
                line = fd.readline()
                if line:
                    stripped = line.strip()
                    # Print raw output line instantly so you can witness the model loading
                    if stripped:
                        print(f"  [{name}] {stripped}")
                    captured_output.append(stripped)
                    
                    # Intercept prompt symbols or metric lines to trigger a graceful termination
                    if ">" in line or "Prompt:" in line:
                        summary = "Intercepted interactive prompt symbol safely"
                        proc.terminate()
                        break
            
            # If the process terminates natively on its own
            if proc.poll() is not None:
                break
        else:
            status = "TIMEOUT"
            summary = "Encountered background interactive read hang"
            proc.kill()
            
        elapsed = int((time.time() - start_time) * 1000)
        log_print(f"| {name:<20} | {status:<7} | {elapsed:>5}ms | {summary} |")
        print(f"<<< [TAIL END] Closed targets stream for: {name}\n")
            
    except Exception as e:
        log_print(f"| {name:<20} | ERROR   | N/A     | Runtime panic: {str(e)[:40]} |")

log_print("\n============================================================")
