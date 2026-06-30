#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/build_runner.py
# Purpose:     Decoupled build manager running explicit profile switches
# Type:        Executable Script
# Attribution: fekerr & Gemini (20260630_1502 / flash 3.5 extended)
# ==============================================================================

import sys
import os
import shutil
import subprocess
import datetime

def verify_workspace_storage(min_free_gb=5.0):
    _, _, free = shutil.disk_usage(".")
    free_gb = free / (1024 ** 3)
    print(f"[Storage Check] Active free capacity: {free_gb:.2f} GB")
    return free_gb >= min_free_gb

def invoke_compilation_pass(target):
    backend = target["backend"]
    jobs = target["parallel_jobs"]
    profile = target["profile"]
    
    # Generate timestamp matching your upstream Makefile convention
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = f"build/{backend}/logs/build_{timestamp}.log"
    
    print(f"\n[+] Executing System Build Target: {backend.upper()} ({profile.upper()})")
    print(f"==================================================================")
    print(f"[+] Log Target Destination: {log_file}")
    print(f"==================================================================")
    
    make_cmd = ["make", f"build-{backend}", f"NUM_BUILD_JOBS={jobs}"]
    
    env_override = os.environ.copy()
    env_override["CMAKE_BUILD_TYPE"] = profile
    
    if backend == "openvino":
        env_override["CMAKE_CXX_FLAGS"] = (
            "-DCL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KHR=0x406E "
            "-DCL_EXTERNAL_MEMORY_HANDLE_D3D11_TEXTURE_KMT_KHR=0x406F "
            "-DCL_EXTERNAL_MEMORY_HANDLE_D3D12_HEAP_KHR=0x4070 "
            "-DCL_EXTERNAL_MEMORY_HANDLE_D3D12_RESOURCE_KHR=0x4071"
        )
        
    process = subprocess.run(make_cmd, env=env_override)
    
    # Echo log details back to user right before exiting thread hooks
    print(f"\n==================================================================")
    print(f"[+] COMPILATION PASS COMPLETE")
    print(f"[-] Final Log Location: {log_file}")
    print(f"==================================================================")
    
    return process.returncode == 0

if __name__ == "__main__":
    active_blueprint_targets = [
        {"backend": "openvino", "profile": "RelWithDebInfo", "parallel_jobs": 1, "enabled": True}
    ]
    
    for target in active_blueprint_targets:
        if not target["enabled"]:
            continue
        if not verify_workspace_storage():
            sys.exit(2)
        if not invoke_compilation_pass(target):
            sys.exit(1)

# --- END OF FILE: tools/build_runner.py ---
