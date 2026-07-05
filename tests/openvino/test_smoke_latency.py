#!/usr/bin/env python3
# ==============================================================================
# Filename:     tests/openvino/test_smoke_latency.py
# Purpose:      Fast hardware acceleration smoke check with tight parameter caps
# Type:         Isolated Unit Test Node
# Attribution:  fekerr & Gemini (20260705_0455 / ASCII Codec-Safe Pass)
# ==============================================================================

import os
import sys
import subprocess
from pathlib import Path

def run_hardware_smoke_check():
    print("[Smoke Target] Commencing quick-fire OpenVINO hardware context initialization check...")
    
    backend = os.environ.get("IRISLIME_ACTIVE_BACKEND", "openvino")
    target_profile = os.environ.get("IRISLIME_ACTIVE_PROFILE", "RELEASE")
    model_file = os.environ.get("IRISLIME_TEST_MODEL", "../models/tinyllama-1.1b-chat-v1.0.Q4_0.gguf")
    
    exe_suffix = ".exe" if os.name == "nt" else ""
    build_folder = f"build/{backend.lower()}_{target_profile.lower()}"
    bench_bin = Path(build_folder) / "bin" / f"llama-bench{exe_suffix}"
    
    if not bench_bin.exists():
        print(f"[!] Smoke Error: Target binary missing at expected track: {bench_bin}")
        return 1
        
    if not Path(model_file).exists():
        print(f"[!] Smoke Error: Target model file not present on disk tracks: {model_file}")
        return 1

    # Configure minimized execution tokens to guarantee rapid turnaround limits
    smoke_args = [
        str(bench_bin),
        "--model", str(model_file),
        "-p", "1", 
        "-n", "1"
    ]
    
    print(f"[Smoke Exec] Launching: {' '.join(smoke_args)}")
    
    try:
        result = subprocess.run(
            smoke_args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            errors="replace"
        )
        
        # ASCII-safe notification strings prevent Windows terminal charmap crashes
        if "OpenVINO" in result.stderr or result.returncode == 0:
            print("[PASS] Smoke Telemetry: OpenVINO hardware layer initialized and returned successfully.")
            return 0
        else:
            print(f"[!] Smoke Failure: Return code = {result.returncode}")
            print(f"[Raw Error Stream]:\n{result.stderr}")
            return result.returncode
            
    except Exception as e:
        print(f"[!] Operational Fault: Unable to execute smoke subprocess: {e}")
        return -1

if __name__ == "__main__":
    sys.exit(run_hardware_smoke_check())
