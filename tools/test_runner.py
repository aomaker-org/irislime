#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/test_runner.py
# Purpose:     Decoupled non-interactive validation and automated tracking dumps
# Type:        Executable Script
# Attribution: fekerr & Gemini (20260630_1351 / flash 3.5 extended)
# ==============================================================================

import sys
import os
import subprocess

def run_evaluation_pass():
    print("\n[+] Launching Non-Interactive Acceleration Smoke Test...")
    print("------------------------------------------------------------------")
    
    binary_target = "build/openvino/bin/llama-cli"
    model_target = os.environ.get("IRISLIME_TEST_MODEL", "models/tinyllama-1.1b-chat-v1.0.Q4_0.gguf")
    
    if not os.path.exists(binary_target):
        print(f"[!] Target Verification Failed: Binary missing at {binary_target}.")
        return False

    args = [
        binary_target,
        "--model", model_target,
        "--simple-io",
        "--n-predict", "16",
        "--ctx-size", "256"
    ]
    
    env = os.environ.copy()
    env["GGML_OPEN_VINO_DEVICE"] = "GPU"
    env["DEBUGINFOD_URLS"] = "" 
    
    prompt_stream_payload = "Verify framework register initialization.\n/exit\n"
    
    print("[Exec] Dispatching prompt sequences and control termination vectors...")
    process = subprocess.run(
        args, 
        env=env, 
        input=prompt_stream_payload, 
        text=True, 
        capture_output=False
    )
    
    if process.returncode != 0:
        print(f"\n[!] ANOMALY DETECTED: Execution step returned error code: {process.returncode}")
        return False
        
    print("\n[+] INFERENCE SUCCESS: Target process resolved execution blocks normally.")
    return True

if __name__ == "__main__":
    success = run_evaluation_pass()
    sys.exit(0 if success else 1)

# --- END OF FILE: tools/test_runner.py ---
