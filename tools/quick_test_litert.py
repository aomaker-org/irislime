#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/quick_test_litert.py
# Purpose:     Non-interactive CLI verification script reading targeted parameter
#              matrices natively from root matrix_control.json specifications.
# Type:        Executable Script
# Attribution: fekerr & Gemini (20260702_1938 / flash 3.5 extended)
# Timestamp:   20260702_1938
# ==============================================================================

import os
import sys
import json
import shutil
import subprocess

def run_litert_smoke_test():
    print("\n[+] Launching Automated LiteRT-LM Headless Quick-Test...")
    print("------------------------------------------------------------------")

    control_path = "matrix_control.json"
    
    # Establish canonical baseline system default definitions
    hf_repo = "litert-community/gemma-3n-E2B-it-litert-lm"
    model_alias = "gemma-3n-E2B-it-int4"
    prompt_string = "Verify agnostic user control hooks for LiteRT-LM."
    
    # Ingest data-driven overrides directly from the matrix input file
    if os.path.exists(control_path):
        try:
            with open(control_path, "r") as cf:
                control_data = json.load(cf)
            litert_config = control_data.get("backend_overrides", {}).get("litert", {})
            
            # Map input parameters safely if keys exist
            hf_repo = litert_config.get("hf_repo", hf_repo)
            model_alias = litert_config.get("model_alias", model_alias)
            prompt_string = litert_config.get("prompt_string", prompt_string)
            print("[Matrix Input] Successfully loaded test properties from matrix_control.json")
        except Exception as e:
            print(f"[-] Notice: Falling back to default targets. Matrix load skipped: {e}")

    # Establish scrubbed environment structures
    env = os.environ.copy()
    env["DEBUGINFOD_URLS"] = ""

    # Prioritize localized compiled execution targets to validate custom Debug setups
    local_bin_candidate = "build/litert_release/bin/litert-lm"
    if not os.path.exists(local_bin_candidate):
        local_bin_candidate = "build/litert_debug/bin/litert-lm"

    if os.path.exists(local_bin_candidate):
        print(f"[Config] Local tracking binary detected at: {local_bin_candidate}")
        print("[Param] Commencing on-device verification sequence...")
        
        args = [
            local_bin_candidate, "run",
            f"--model_path=../models/{model_alias}.bin",
            f"--prompt={prompt_string}"
        ]
    else:
        print("[-] Notice: Local binaries missing. Commencing remote packet layer fallback.")
        uv_path = shutil.which("uv")
        if not uv_path:
            print("[!] Abort: Astral 'uv' missing from active PATH. Cannot initialize test verification.")
            return False
            
        print(f"[Config] Routing via local uv execution core: {uv_path}")
        args = [
            "uv", "tool", "run", "litert-lm", "run",
            f"--from-huggingface-repo={hf_repo}",
            model_alias,
            "--backend=gpu",
            f"--prompt={prompt_string}"
        ]

    print(f"[Fetch] Container Instance : {hf_repo}")
    print(f"[Param] Targeted Model Name: {model_alias}")
    print(f"[Exec] Launching active inference pipeline sweep...")
    print("------------------------------------------------------------------")
    
    try:
        process = subprocess.run(args, env=env, text=True, capture_output=False)
        print("------------------------------------------------------------------")
        if process.returncode == 0:
            print("[+] LiteRT-LM Verification Pass: SUCCESS")
            return True
        else:
            print(f"[!] LiteRT-LM returned non-zero finalization exit code: {process.returncode}")
            return False

    except Exception as e:
        print(f"[!] Critical structural execution failure encountered: {e}")
        return False

if __name__ == "__main__":
    success = run_litert_smoke_test()
    sys.exit(0 if success else 1)

# --- END OF FILE: tools/quick_test_litert.py ---
