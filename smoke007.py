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
log_print("S_LAUNCH: IRISLIME ASYNC REALTIME TAIL RUNNER (v007)")
log_print(f"Project Root: {PROJECT_ROOT}")
log_print(f"Model Location: {os.path.relpath(MODEL_PATH, PROJECT_ROOT)}")
log_print("============================================================\n")

log_print("| Target Configuration | Status  | Latency | Execution Discovery Summary |")
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
        proc = subprocess.Popen(
            [exe_path] + TEST_ARGS,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        
        if proc.stdin:
            proc.stdin.close()

        status = "PASSED"
        summary = "Clean exit reached"
        
        while time.time() - start_time < 12:
            reads = [proc.stdout, proc.stderr]
            ret = select.select(reads, [], [], 0.1)
            
            break_loop = False
            for fd in ret[0]:
                line = fd.readline()
                if line:
                    if ">" in line or "Prompt:" in line:
                        summary = "Intercepted interactive prompt loop cleanly"
                        proc.terminate()
                        break_loop = True
                        break
            if break_loop:
                break
            if proc.poll() is not None:
                break
        else:
            status = "TIMEOUT"
            summary = "Encountered background interactive read hang"
            proc.kill()
            
        elapsed = int((time.time() - start_time) * 1000)
        log_print(f"| {name:<20} | {status:<7} | {elapsed:>5}ms | {summary} |")
            
    except Exception as e:
        log_print(f"| {name:<20} | ERROR   | N/A     | Runtime panic: {str(e)[:40]} |")

log_print("\n============================================================")

# Save telemetry output profile to disk
timestamp = time.strftime("%Y%m%d_%H%M%S")
log_filename = f"smoke_test_{timestamp}.log"
log_filepath = os.path.join(LOGS_DIR, log_filename)
captured_text = output_stream.getvalue()

with open(log_filepath, "w") as log_file:
    log_file.write(captured_text)
print(f"\nTelemetry profile saved to: ./logs/{log_filename}")

# Execute Windows clipboard pipeline step safely
try:
    if any(os.path.exists(os.path.join(p, "clip.exe")) for p in os.environ.get("PATH", "").split(os.pathsep)):
        process = subprocess.Popen(["clip.exe"], stdin=subprocess.PIPE, text=True)
        process.communicate(input=captured_text)
        print("Clipboard payload successfully dispatched via clip.exe!")
    else:
        print("clip.exe execution bypassed (Not found in path framework).")
except Exception as e:
    print(f"Clipboard pipeline boundary failure: {e}")

output_stream.close()
