#!/usr/bin/env python3
import subprocess
import time
import os
import io

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

# The explicit non-interactive flag block
TEST_ARGS = [
    "-m", MODEL_PATH, 
    "-p", "The quick brown fox", 
    "-n", "1", 
    "--no-display-prompt",
    "--simple-io",
    "--gpu-layers", "99"
]

output_stream = io.StringIO()

def log_print(message=""):
    print(message)
    output_stream.write(message + "\n")

log_print("============================================================")
log_print("S_LAUNCH: IRISLIME SANITY CHECK RUNNER & TELEMETRY LOG (v005)")
log_print(f"Project Root: {PROJECT_ROOT}")
log_print(f"Model Location: {os.path.relpath(MODEL_PATH, PROJECT_ROOT)}")
log_print("============================================================\n")

log_print("| Target Configuration | Status  | Latency | Log Details / Error Trace Snippet |")
log_print("| :--- | :--- | :--- | :--- |")

if not os.path.exists(MODEL_PATH):
    log_print(f"[ERROR]: Cannot find '{MODEL_FILENAME}' inside models folder.")

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
    start_time = time.time()
    
    try:
        # Explicitly pipe stdin out to force standard EOF semantics on generation completion
        result = subprocess.run(
            [exe_path] + TEST_ARGS,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=10
        )
        elapsed = int((time.time() - start_time) * 1000)
        
        if result.returncode == 0:
            log_print(f"| {name:<20} | PASSED  | {elapsed:>5}ms | {display_exe} |")
        else:
            err_lines = [line.strip() for line in result.stderr.strip().split('\n') if line.strip()]
            err_log = " | ".join(err_lines[-3:]) if err_lines else "Non-zero exit status"
            err_clean = err_log.replace('`','').replace('\'','').replace('"','')
            log_print(f"| {name:<20} | CRASHED | {elapsed:>5}ms | {err_clean[:65]}... |")
            
    except subprocess.TimeoutExpired:
        log_print(f"| {name:<20} | TIMEOUT | N/A     | Process exceeded runtime ceiling |")
    except Exception as e:
        log_print(f"| {name:<20} | ERROR   | N/A     | Exception: {str(e)[:45]} |")

log_print("\n============================================================")

timestamp = time.strftime("%Y%m%d_%H%M%S")
log_filename = f"smoke_test_{timestamp}.log"
log_filepath = os.path.join(LOGS_DIR, log_filename)

captured_text = output_stream.getvalue()

with open(log_filepath, "w") as log_file:
    log_file.write(captured_text)
print(f"\nTelemetry saved to: ./logs/{log_filename}")

try:
    if any(os.path.exists(os.path.join(p, "clip.exe")) for p in os.environ.get("PATH", "").split(os.pathsep)):
        process = subprocess.Popen(["clip.exe"], stdin=subprocess.PIPE, text=True)
        process.communicate(input=captured_text)
        print("Results successfully copied to host Windows clipboard via clip.exe!")
    else:
        print("clip.exe not found in path. Bypassing clipboard operation.")
except Exception as e:
    print(f"Could not interface with host clipboard: {e}")

output_stream.close()
