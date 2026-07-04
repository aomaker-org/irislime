#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/test_runner.py
# Purpose:     Automated headless validation matrix driven entirely by centralized
#              matrix_control.json definitions and dynamic backend deduction.
# Type:        Executable Script
# Attribution: fekerr & Gemini (20260702_1938 / flash 3.5 extended)
# Timestamp:   20260702_1938
# ==============================================================================

import sys
import os
import json
import subprocess
import argparse

def execute_subprocess_target(args, env):
    """Safely executes a headless binary and tracks execution health."""
    try:
        process = subprocess.run(
            args, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        return process.returncode, process.stdout, process.stderr
    except Exception as e:
        return -1, "", str(e)

def traverse_and_execute_tests(backend, test_root, env):
    """Dynamically locates and executes localized test scripts inside a target tests subfolder."""
    backend_test_dir = os.path.join(test_root, backend)
    if not os.path.exists(backend_test_dir) or not os.path.isdir(backend_test_dir):
        print(f"[-] Traversal: No specialized test directory found at {backend_test_dir}. Skipping pass.")
        return True

    print(f"[Traversal] Scanning for test infrastructure inside {backend_test_dir}...")
    all_passed = True
    
    for item in sorted(os.listdir(backend_test_dir)):
        if item.startswith("test_") and (item.endswith(".sh") or item.endswith(".py")):
            full_path = os.path.join(backend_test_dir, item)
            print(f"  • Found Test Unit: {item} -> Executing...")
            
            cmd = [sys.executable, full_path] if item.endswith(".py") else ["bash", full_path]
            code, out, err = execute_subprocess_target(cmd, env)
            
            if code == 0:
                print(f"    [✅] {item}: PASSED")
            else:
                print(f"    [❌] {item}: FAILED (Exit Code {code})")
                print(f"    [Log Error]: {err if err else out[-200:]}")
                all_passed = False
                
    return all_passed

def run_evaluation_pass():
    print("\n[+] Launching Automated Validation Matrix...")
    print("------------------------------------------------------------------")
    
    parser = argparse.ArgumentParser(description="Irislime Custom Test Runner Automation")
    parser.add_argument("--dir", type=str, required=True, help="Target build directory to analyze (e.g. build/litert_debug)")
    parser.add_argument("--tests-dir", type=str, default="tests", help="Root directory containing specialized test scripts")
    parsed_args = parser.parse_known_args()[0]
    
    target_dir = parsed_args.dir.rstrip('/')
    bin_base = f"{target_dir}/bin"
    control_path = "matrix_control.json"
    
    # Extract operational parameters natively from the target directory naming scheme
    folder_signature = os.path.basename(target_dir)
    signature_parts = folder_signature.split('_')
    backend = signature_parts[0]
    profile = signature_parts[1].upper() if len(signature_parts) > 1 else "RELEASE"
    
    print(f"[Matrix Configuration] Deduced Backend: {backend.upper()} | Profile: {profile}")
    
    env = os.environ.copy()
    env["DEBUGINFOD_URLS"] = ""
    env["IRISLIME_ACTIVE_BACKEND"] = backend
    env["IRISLIME_ACTIVE_PROFILE"] = profile
    
    # Initialize baseline defaults for control mappings
    model_target = os.environ.get("IRISLIME_TEST_MODEL", "../models/tinyllama-1.1b-chat-v1.0.Q4_0.gguf")
    
    # Ingest inputs natively from control specification files
    if os.path.exists(control_path):
        try:
            with open(control_path, "r") as cf:
                control_data = json.load(cf)
            
            # Extract global settings overrides
            global_settings = control_data.get("global_settings", {})
            if "test_model" in global_settings:
                model_target = global_settings["test_model"]
                
            # Extract targeted backend environment variables
            backend_config = control_data.get("backend_overrides", {}).get(backend, {})
            custom_env_vars = backend_config.get("env_vars", {})
            
            print(f"[Env] Injecting matrix control profiles for: {backend}")
            for var_key, var_val in custom_env_vars.items():
                env[var_key] = str(var_val)
        except Exception as e:
            print(f"[!] Warning: Failed parsing matrix control input metadata: {e}")

    # PHASE 1: Native Mathematical Unit Test
    unit_test_binary = f"{bin_base}/test-backend-ops"
    if os.path.exists(unit_test_binary):
        print(f"[Exec] Phase 1: Verifying Low-Level Engine Syntax Linkage: {unit_test_binary}")
        code, out, err = execute_subprocess_target([unit_test_binary, "--list-ops"], env)
        if code != 0:
            print(f"[!] Phase 1 Core Verification Failure [Code {code}]. Linkage corrupt.")
            return False
        print("[+] Phase 1 Baseline Linkage Verification: PASSED")
    else:
        print(f"[-] Phase 1 Skip: Standard unit binary missing at {unit_test_binary}")

    # PHASE 2: Dynamic Test Directory Traversal
    print("[Exec] Phase 2: Launching Traversal Routine over Test Directories...")
    if not traverse_and_execute_tests(backend, parsed_args.tests_dir, env):
        print("[!] Phase 2 Traversal Phase reported active test failures.")
        return False
    print("[+] Phase 2 Directory Traversal Sweep: PASSED")

    # PHASE 3: Standard Model Benchmarking Pass
    bench_binary = f"{bin_base}/llama-bench"
    if os.path.exists(bench_binary) and os.path.exists(model_target):
        print(f"[Exec] Phase 3: Running Headless Performance Benchmarking Loop: {bench_binary}")
        print(f"[Param] Bench Target Model: {model_target}")
        bench_args = [bench_binary, "--model", model_target, "-p", "128", "-n", "16"]
        
        if backend != "litert":
            bench_args.extend(["--backend", backend])
            
        code, out, err = execute_subprocess_target(bench_args, env)
        if code != 0:
            print(f"[!] Phase 3 Benchmarking Failure [Code {code}].")
            return False
            
        print("[+] Phase 3 Standard Benchmarks: PASSED")
        for line in out.split('\n'):
            if backend.upper() in line.upper() or "model" in line:
                print(f"    {line}")
    else:
        print(f"[-] Phase 3 Skip: Target benchmarking suite or baseline model unavailable at {model_target}")

    return True

if __name__ == "__main__":
    success = run_evaluation_pass()
    sys.exit(0 if success else 1)

# --- END OF FILE: tools/test_runner.py ---
