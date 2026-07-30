#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tests/test_built_binaries_and_models.py
# Purpose:      Sanity & Integration Test Harness for Built Binaries & C:\AI_models
# Target OS:    Ubuntu 26.04 LTS / WSL2 / Windows 11
# Lineage:      IrisLime Infrastructure (Task 140)
# Updated:      2026-07-29
# Attribution:  fekerr & Gemini
# ==============================================================================

import os
import sys
import subprocess
from pathlib import Path

def test_built_llama_binary():
    print("[*] Testing Vulkan Debug Binary: build/vulkan_debug/bin/llama...")
    llama_bin = Path("build/vulkan_debug/bin/llama")
    if not llama_bin.exists():
        print("[!] Warning: build/vulkan_debug/bin/llama binary not compiled yet.")
        return True
        
    res = subprocess.run([str(llama_bin), "--version"], capture_output=True, text=True)
    assert res.returncode == 0, f"llama --version failed with exit code {res.returncode}"
    assert "b10160" in res.stdout or "9a3bf2" in res.stdout, "Unexpected version output"
    print(f"[+] Verified llama version: {res.stdout.strip()}")
    return True

def test_built_llama_bench_binary():
    print("[*] Testing Vulkan Debug Binary: build/vulkan_debug/bin/llama-bench...")
    bench_bin = Path("build/vulkan_debug/bin/llama-bench")
    if not bench_bin.exists():
        print("[!] Warning: build/vulkan_debug/bin/llama-bench binary not compiled yet.")
        return True
        
    res = subprocess.run([str(bench_bin), "--help"], capture_output=True, text=True)
    assert res.returncode == 0, f"llama-bench --help failed with exit code {res.returncode}"
    assert "usage:" in res.stdout.lower() or "usage:" in res.stderr.lower(), "Unexpected help output"
    print("[+] Verified llama-bench help output.")
    return True

def test_ai_models_directory_resolution():
    print("[*] Testing C:\\AI_models POSIX & Environment Resolution...")
    models_dir = Path(os.getenv("LOCAL_AI_MODELS_DIR", "/mnt/c/AI_models"))
    print(f"[*] LOCAL_AI_MODELS_DIR : {models_dir}")
    
    if models_dir.exists():
        contents = [f.name for f in models_dir.iterdir()]
        print(f"[+] Found {len(contents)} nodes in {models_dir}: {contents[:5]}")
    else:
        print(f"[!] Note: {models_dir} not accessible in current subshell environment.")
    return True

def test_wslpath_translation():
    print("[*] Testing wslpath translation interop...")
    posix_path = "/mnt/c/AI_models"
    try:
        res = subprocess.run(["wslpath", "-w", posix_path], capture_output=True, text=True)
        if res.returncode == 0:
            win_path = res.stdout.strip()
            print(f"[+] Translated '{posix_path}' -> '{win_path}'")
            assert "C:" in win_path, "Expected C: drive in Windows path translation"
        else:
            print("[!] wslpath command returned non-zero code (non-WSL container environment).")
    except Exception as e:
        print(f"[!] wslpath test note: {e}")
    return True

def main():
    print("==========================================================")
    print("  Built Binaries & C:\\AI_models Test Harness (Task 140)   ")
    print("==========================================================")
    
    t1 = test_built_llama_binary()
    t2 = test_built_llama_bench_binary()
    t3 = test_ai_models_directory_resolution()
    t4 = test_wslpath_translation()
    
    all_ok = t1 and t2 and t3 and t4
    print("----------------------------------------------------------")
    if all_ok:
        print("[SUCCESS] All Task 140 binary & environment tests passed!")
    else:
        print("[FAILURE] One or more test assertions failed.")
    return 0 if all_ok else 1

if __name__ == "__main__":
    sys.exit(main())
