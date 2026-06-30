#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/matrix_build_runner.py
# Purpose:     Format-agnostic compilation matrix driver with storage guardrails
# Type:        Executable Script
# Attribution: fekerr & Gemini (20260630_1256 / flash 3.5 extended)
# ==============================================================================

import sys
import os
import shutil
import subprocess

def check_storage(min_free_gb=5.0):
    total, used, free = shutil.disk_usage(".")
    free_gb = free / (1024 ** 3)
    print(f"[Telemetry] Workspace Free Space: {free_gb:.2f} GB")
    return free_gb >= min_free_gb

def execute_build(target):
    backend = target["backend"]
    profile = target["profile"]
    jobs = target["parallel_jobs"]
    
    print(f"\n[+] Triggering Build Matrix Variant: {backend.upper()} ({profile.upper()})")
    print(f"------------------------------------------------------------------")
    
    # Map high-level profiles directly to standard Make orchestration hooks
    make_cmd = ["make", f"build-{backend}", f"NUM_BUILD_JOBS={jobs}"]
    
    env_override = os.environ.copy()
    if backend == "openvino":
        # Pass our verified Khronos preprocessor bypass flags explicitly
        env_override["CMAKE_CXX_FLAGS"] = (
            "-DCL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KHR=0x406E "
            "-DCL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KMT_KHR=0x406F "
            "-DCL_EXTERNAL_MEMORY_HANDLE_D3D12_HEAP_KHR=0x4070 "
            "-DCL_EXTERNAL_MEMORY_HANDLE_D3D12_RESOURCE_KHR=0x4071"
        )
    
    process = subprocess.run(make_cmd, env=env_override)
    return process.returncode == 0

if __name__ == "__main__":
    # Inline configuration targets array 
    build_matrix = [
        {"backend": "openvino", "profile": "release", "parallel_jobs": 1, "enabled": True}
    ]
    
    print("[Matrix Engine] Starting matrix_build_runner processing loop...")
    for target in build_matrix:
        if not target["enabled"]:
            continue
            
        if not check_storage():
            print("[!] CRITICAL ABORT: Insufficient disk space to proceed safely.")
            sys.exit(2)
            
        if not execute_build(target):
            print(f"[!] MATRIX FAILURE: Build compilation stepped down at {target['backend']}.")
            sys.exit(1)
            
    print("\n[+] MATRIX SUCCESS: All active compilation variants completed successfully.")
