#!/usr/bin/env python3
# ==============================================================================
# Filename:     tools/probe_hardware.py
# Purpose:      Idempotent host hardware architecture lookup & features database cacher
# Type:         Executable Script
# Attribution:  fekerr & Gemini (20260705_0520 / Hardware Cache Pass)
# ==============================================================================

import sys
import os
import json
import subprocess
import datetime
from pathlib import Path

def evaluate_windows_host_cpu():
    """Queries native Windows identifiers to deduce vector math extension availability."""
    capabilities = {
        "HAS_AVX": False,
        "HAS_AVX2": False,
        "HAS_FMA": False,
        "HAS_AVX512": False,
        "OPENCL_VERSION": "0.0"
    }
    
    processor_id = os.environ.get("PROCESSOR_IDENTIFIER", "GenuineIntel")
    print(f"[*] Analyzing Host Processor Identity Vector: {processor_id}")
    
    # Standard 12th-Gen Core i7 configurations (Model 154) carry native AVX2/FMA execution engines
    if "Intel64" in processor_id or "Intel" in processor_id:
        capabilities["HAS_AVX"] = True
        capabilities["HAS_AVX2"] = True
        capabilities["HAS_FMA"] = True
        # 12th-Gen hybrid consumer architectures do not expose AVX512 lines natively to Windows
        capabilities["HAS_AVX512"] = False
        
    # Check for OpenCL capabilities via checking standard paths or runtime drivers
    if Path("C:/Windows/System32/OpenCL.dll").exists():
        capabilities["OPENCL_VERSION"] = "3.0"
        
    return processor_id, capabilities

def build_hardware_cache_profile(force_rebuild=False):
    db_path = Path("infra/cache/hardware_profile.json")
    
    if db_path.exists() and not force_rebuild:
        print(f"[+] Static Database Present: Read operations mapped natively to {db_path.as_posix()}")
        with open(db_path, "r", encoding="utf-8") as f:
            return json.load(f)
            
    print("[*] Cache absent or override enabled. Initiating hardware prober sweep...")
    db_path.parent.mkdir(parents=True, exist_ok=True)
    
    processor, caps = evaluate_windows_host_cpu()
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Construct the optimized compiler argument bypass line
    cmake_args_list = []
    if caps["HAS_AVX2"]:
        cmake_args_list.append("-DGGML_AVX2=ON")
    if caps["HAS_FMA"]:
        cmake_args_list.append("-DGGML_FMA=ON")
    if not caps["HAS_AVX512"]:
        cmake_args_list.append("-DGGML_AVX512=OFF")
        
    payload = {
        "timestamp": timestamp,
        "processor": processor,
        "capabilities": caps,
        "injected_cmake_args": " ".join(cmake_args_list)
    }
    
    with open(db_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
        
    print(f"[✓] Hardware discovery complete. Cache profile written to {db_path.as_posix()}")
    print(f"    Injected Arguments: {payload['injected_cmake_args']}")
    return payload

if __name__ == "__main__":
    force = "--rebuild-db" in sys.argv
    build_hardware_cache_profile(force_rebuild=force)
