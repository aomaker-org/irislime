#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/test_runner.py
# Purpose:     Profile and control-aware dynamic validation engine
# Type:        Executable Script
# Attribution: fekerr & Gemini (20260630_1625 / flash 3.5 extended)
# ==============================================================================

import sys
import os
import json
import subprocess

def run_evaluation_pass():
    print("\n[+] Launching Control-Aware Dynamic Smoke Test...")
    print("------------------------------------------------------------------")
    
    status_path = "build/build_status.json"
    control_path = "matrix_control.json"
    
    if not os.path.exists(status_path) or not os.path.exists(control_path):
        print("[!] Abort: Missing build status or control config targets.")
        return False
        
    with open(status_path, "r") as sf, open(control_path, "r") as cf:
        status_data = json.load(sf)
        control_data = json.load(cf)
        
    backend = status_data.get("last_built_target", "openvino")
    target_dir = status_data.get("target_directory")
    binary_target = f"{target_dir}/bin/llama-cli"
    model_target = os.environ.get("IRISLIME_TEST_MODEL", "models/tinyllama-1.1b-chat-v1.0.Q4_0.gguf")
    
    if not os.path.exists(binary_target):
        print(f"[!] Verification Error: Expected binary missing at {binary_target}.")
        return False

    args = [
        binary_target,
        "--model", model_target,
        "--simple-io",
        "--n-predict", "16",
        "--ctx-size", "256"
    ]
    
    env = os.environ.copy()
    env["DEBUGINFOD_URLS"] = ""
    
    # Pull dynamic runtime variables straight out of user control file parameters
    backend_settings = control_data.get("backend_overrides", {}).get(backend, {})
    custom_env_vars = backend_settings.get("env_vars", {})
    
    print(f"[Env] Injecting user-defined variables for backend: {backend}")
    for var_key, var_val in custom_env_vars.items():
        env[var_key] = str(var_val)
        
    prompt_stream_payload = f"Verify agnostic user control hooks for {backend}.\n/exit\n"
    
    print(f"[Exec] Testing target binary: {binary_target}")
    process = subprocess.run(
        args, env=env, input=prompt_stream_payload, text=True, capture_output=False
    )
    
    return process.returncode == 0

if __name__ == "__main__":
    success = run_evaluation_pass()
    sys.exit(0 if success else 1)

# --- END OF FILE: tools/test_runner.py ---
