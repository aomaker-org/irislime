#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/matrix_test_runner.py
# Purpose:     Automated smoke-testing with proactive GDB and strace interception
# Type:        Executable Script
# Attribution: fekerr & Gemini (20260630_1256 / flash 3.5 extended)
# ==============================================================================

import sys
import os
import subprocess

def run_smoke_test():
    print("\n[+] Launching Non-Interactive OpenVINO Acceleration Smoke Test...")
    print("------------------------------------------------------------------")
    
    binary_path = "build/openvino/bin/llama-cli"
    model_path = os.environ.get("IRISLIME_TEST_MODEL", "../models/tinyllama-1.1b-chat-v1.0.Q4_0.gguf")
    
    if not os.path.exists(binary_path):
        print(f"[!] Error: Executable target missing at {binary_path}. Run builder first.")
        return False

    # Standard non-interactive generation command block
    base_args = [
        binary_path,
        "-m", model_path,
        "-p", "Compute the core matrix value:",
        "-n", "5",
        "-t", "2",
        "-co", "off"
    ]
    
    env = os.environ.copy()
    env["GGML_OPEN_VINO_DEVICE"] = "GPU"
    env["DEBUGINFOD_URLS"] = ""  # Force local tracking to prevent timeout hangs
    
    print("[Exec] Executing baseline smoke-test pass...")
    # Inject an implicit EOF stream to instantly bypass interactive prompt loops
    process = subprocess.run(base_args, env=env, stdin=subprocess.DEVNULL)
    
    if process.returncode != 0:
        print(f"\n[!] SMOKE TEST CRASHED (Exit Code: {process.returncode}). Initiating Deep Diagnostics...")
        run_automated_gdb(base_args, env)
        run_automated_strace(base_args, env)
        return False
        
    print("\n[+] SMOKE TEST SUCCESS: Binary evaluated tokens and exited normally.")
    return True

def run_automated_gdb(args, env):
    print("\n[Telemetry] Triggering Pre-emptive Automated GDB Backtrace Tracking...")
    gdb_cmd = [
        "gdb", 
        "-ex", "run", 
        "-ex", "bt", 
        "-ex", "quit", 
        "--args"
    ] + args
    
    # Execute and mirror traces directly to log destination files
    log_file = "logs/builds/openvino/gdb_crash_forensics.log"
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    
    with open(log_file, "w") as f:
        subprocess.run(gdb_cmd, env=env, stdin=subprocess.DEVNULL, stdout=f, stderr=subprocess.STDOUT)
    print(f"[Telemetry] GDB stack forensics captured successfully inside: {log_file}")

def run_automated_strace(args, env):
    print("[Telemetry] Triggering Interception Strace Syscall Profiling...")
    log_file = "logs/builds/openvino/strace_syscall_io.log"
    
    strace_cmd = [
        "strace", 
        "-e", "trace=openat,close,read,write,ioctl", 
        "-o", log_file
    ] + args
    
    subprocess.run(strace_cmd, env=env, stdin=subprocess.DEVNULL)
    print(f"[Telemetry] Syscall stream logs captured successfully inside: {log_file}")

if __name__ == "__main__":
    success = run_smoke_test()
    sys.exit(0 if success else 1)
