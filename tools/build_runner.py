#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/build_runner.py
# Purpose:     Lightweight decoupled build manager running hybrid debug symbols
# Type:        Executable Script
# Attribution: fekerr & Gemini (20260630_1350 / flash 3.5 extended)
# ==============================================================================

import sys
import os
import shutil
import subprocess

def verify_workspace_storage(min_free_gb=5.0):
    """Monitors workspace capacity ceilings before dropping into compiler passes."""
    _, _, free = shutil.disk_usage(".")
    free_gb = free / (1024 ** 3)
    print(f"[Storage Check] Active free capacity: {free_gb:.2f} GB")
    return free_gb >= min_free_gb

def invoke_compilation_pass(target):
    backend = target["backend"]
    jobs = target["parallel_jobs"]
    
    print(f"\n[+] Executing Hybrid System Build Target: {backend.upper()}")
    print(f"------------------------------------------------------------------")
    
    # Force the out-of-tree engine to compile with high speed optimizations AND debug lines
    make_cmd = [
        "make", 
        f"build-{backend}", 
        f"NUM_BUILD_JOBS={jobs}"
    ]
    
    env_override = os.environ.copy()
    
    # Global environment configuration switches to override monolithic target build types
    # Injecting RelWithDebInfo lets us preserve precise tracking stack frames
    env_override["CMAKE_BUILD_TYPE"] = "RelWithDebInfo"
    
    if backend == "openvino":
        # Pass native Khronos preprocessor bypass blocks
        env_override["CMAKE_CXX_FLAGS"] = (
            "-DCL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KHR=0x406E "
            "-DCL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KMT_KHR=0x406F "
            "-DCL_EXTERNAL_MEMORY_HANDLE_D3D12_HEAP_KHR=0x4070 "
            "-DCL_EXTERNAL_MEMORY_HANDLE_D3D12_RESOURCE_KHR=0x4071"
        )
        
    process = subprocess.run(make_cmd, env=env_override)
    return process.returncode == 0

if __name__ == "__main__":
    # Normalized flat configuration array structure 
    active_blueprint_targets = [
        {"backend": "openvino", "parallel_jobs": 1, "enabled": True}
    ]
    
    print("[Infra Dev] Initializing build_runner execution loops...")
    for target in active_blueprint_targets:
        if not target["enabled"]:
            continue
            
        if not verify_workspace_storage():
            print("[!] ABORT: Insufficient local disk tracks to build cleanly.")
            sys.exit(2)
            
        if not invoke_compilation_pass(target):
            print(f"[!] COMPILER FAULT: Build pass broken inside backend target: {target['backend']}")
            sys.exit(1)
            
    print("\n[+] BUILD ENGINE METRICS: Target compilation passes processing complete.")
