#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/distclean.py
# Purpose:     Strict, environment-aware workspace deep purge tool
# Type:        Executable Script
# Attribution: fekerr & Gemini (20260630_1712 / flash 3.5 extended)
# ==============================================================================

import os
import sys
import shutil
import subprocess

def assert_environment_active():
    """Enforces the strict dependency on config_env being sourced."""
    if not os.environ.get("IRISLIME_READY"):
        print("[X] CRITICAL ERROR: IrisLime toolchain environment not detected.")
        print("    You must SOURCE the environment before running a distclean pass:")
        print("    $ source config_env")
        sys.exit(1)

def run_purge_sequence():
    assert_environment_active()
    
    # Dynamically resolve project root relative to this script's location (tools/../)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    
    print("\n[!] WARNING: Initiating Absolute Repository Distclean Protocol...")
    print(f"[*] Target Workspace Anchor: {project_root}")
    print("------------------------------------------------------------------")
    
    # 1. Purge out-of-tree isolated build directories completely
    build_dir = os.path.join(project_root, "build")
    if os.path.exists(build_dir):
        print("[-] Purging dynamic build matrix folder trees...")
        try:
            shutil.rmtree(build_dir)
            print("[+] Build matrix directory trees wiped.")
        except Exception as e:
            print(f"[!] Warning: Exception encountered clearing build target: {e}")
            
    # 2. Purge persistent runtime log cache structures
    log_dir = os.path.join(project_root, "logs", "builds")
    if os.path.exists(log_dir):
        print("[-] Purging runtime build log files...")
        try:
            shutil.rmtree(log_dir)
            print("[+] Target build log archives cleared.")
        except Exception as e:
            print(f"[!] Warning: Exception encountered clearing logs: {e}")

    # 3. Clear global compiler object cache frameworks via ccache
    if shutil.which("ccache"):
        print("[-] Clearing global ccache token footprint maps...")
        try:
            subprocess.run(["ccache", "--clear"], check=True)
            print("[+] ccache object metrics dropped to zero.")
        except subprocess.CalledProcessError:
            print("[!] Warning: ccache clearance call returned an anomalous exit state.")
    else:
        print("[*] ccache binary absent on host layer. Skipping token metrics flush.")

    print("------------------------------------------------------------------")
    print("[+] SUCCESS: Workspace successfully returned to a clean upstream state.")

if __name__ == "__main__":
    run_purge_sequence()

# --- END OF FILE: tools/distclean.py ---
