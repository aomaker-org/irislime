#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/build_runner.py
# Purpose:     Format-agnostic build manager reading root matrix_control.json
# Type:        Executable Script
# Attribution: fekerr & Gemini (20260630_1625 / flash 3.5 extended)
# ==============================================================================

import sys
import os
import shutil
import subprocess
import datetime
import json

def load_matrix_control():
    """Ingests the root user-configured control specification file."""
    control_path = "matrix_control.json"
    if not os.path.exists(control_path):
        print(f"[!] Critical Error: Missing control file at {control_path}")
        sys.exit(3)
    with open(control_path, "r") as f:
        return json.load(f)

def verify_workspace_storage(min_free_gb):
    """Monitors workspace capacity ceilings before dropping into compiler passes."""
    _, _, free = shutil.disk_usage(".")
    free_gb = free / (1024 ** 3)
    print(f"[Storage Check] Active free capacity: {free_gb:.2f} GB (Required: {min_free_gb} GB)")
    return free_gb >= min_free_gb

def invoke_compilation_pass(backend, profile, settings):
    jobs = settings.get("parallel_jobs", 1)
    cxx_flags = settings.get("cmake_cxx_flags", "")
    cmake_flags = settings.get("cmake_flags", "")
    
    # Establish dynamic, isolated target path boundaries
    target_dir = f"build/{backend}_{profile.lower()}"
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Isolate log architectures outside the volatile build folders
    log_dir = f"logs/builds/{backend}_{profile.lower()}"
    os.makedirs(log_dir, exist_ok=True)
    log_file = f"{log_dir}/build_{timestamp}.log"
    
    print(f"\n[+] Executing Isolated Target: {backend.upper()} | Profile: {profile}")
    print(f"==================================================================")
    print(f"[+] Isolated Target Folder: {target_dir}")
    print(f"[+] Persistent Log Target:  {log_file}")
    print(f"==================================================================")
    
    make_cmd = [
        "make", 
        f"build-{backend}", 
        f"BUILD_DIR={target_dir}",
        f"NUM_BUILD_JOBS={jobs}"
    ]
    
    # Inject both standard environment maps and user custom overrides natively
    env_override = os.environ.copy()
    env_override["CMAKE_BUILD_TYPE"] = profile
    
    if cxx_flags:
        env_override["CMAKE_CXX_FLAGS"] = cxx_flags
    if cmake_flags:
        env_override["CMAKE_FLAGS"] = cmake_flags
        
    # Map any user-specified execution environment variable mappings straight into the subprocess block
    custom_env_vars = settings.get("env_vars", {})
    for var_key, var_val in custom_env_vars.items():
        env_override[var_key] = str(var_val)
        
    process = subprocess.run(make_cmd, env=env_override)
    build_success = (process.returncode == 0)
    
    # Document state telemetry manifest maps
    status_payload = {
        "last_built_target": backend,
        "profile": profile,
        "timestamp": timestamp,
        "target_directory": target_dir,
        "log_file_location": log_file,
        "status": "SUCCESS" if build_success else "FAILED"
    }
    
    os.makedirs("build", exist_ok=True)
    status_file_path = "build/build_status.json"
    with open(status_file_path, "w") as sf:
        json.dump(status_payload, sf, indent=2)
        
    print(f"\n==================================================================")
    print(f"[+] PROFILE PASS RESOLVED: {status_payload['status']}")
    print(f"[-] Root Manifest Updated: {status_file_path}")
    print(f"[-] Final Log Location:    {log_file}")
    print(f"==================================================================")
    
    return build_success

if __name__ == "__main__":
    control_config = load_matrix_control()
    
    global_limits = control_config.get("global_settings", {})
    min_space = global_limits.get("min_required_disk_space_gb", 5.0)
    
    if not verify_workspace_storage(min_space):
        print("[!] ABORT: Insufficient host disk tracks to proceed safely.")
        sys.exit(2)
        
    backend_grid = control_config.get("backend_overrides", {})
    
    print("[Infra Dev] Processing control file execution matrices...")
    for backend, settings in backend_grid.items():
        if not settings.get("enabled", False):
            print(f"[Matrix] Skipping disabled backend layout target: {backend}")
            continue
            
        profiles_to_build = settings.get("profiles", ["Release"])
        for profile in profiles_to_build:
            if not invoke_compilation_pass(backend, profile, settings):
                print(f"[!] COMPILER FAULT: Pipeline broken at target {backend} ({profile})")
                sys.exit(1)
                
    print("\n[+] BUILD ENGINE METRICS: Control file compilation sweep complete.")

# --- END OF FILE: tools/build_runner.py ---
