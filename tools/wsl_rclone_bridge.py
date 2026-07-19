#!/usr/bin/env python3
"""
Path:        tools/wsl_rclone_bridge.py
Purpose:     Transparent WSL-to-Win11 rclone bridge.
             Translates POSIX path arguments into Windows-compatible paths via wslpath
             and executes host Windows-native rclone.exe.
Lineage:     irislime / fekerr-dev Integration
Updated:     20260718 (fekerr & Antigravity)
"""

import os
import sys
import shutil
import subprocess

CANDIDATE_PATHS = [
    "/mnt/c/Users/feker/AppData/Local/Microsoft/WinGet/Links/rclone.exe",
    "/mnt/c/Users/feker/AppData/Local/Microsoft/WinGet/Packages/Rclone.Rclone_Microsoft.Winget.Source_8wekyb3d8bbwe/rclone-v1.74.3-windows-amd64/rclone.exe",
]

def find_windows_rclone() -> str:
    # 1. Check WinGet link or package paths
    for p in CANDIDATE_PATHS:
        if os.path.exists(p):
            return p

    # 2. Check PATH for rclone.exe
    rclone_exe = shutil.which("rclone.exe")
    if rclone_exe:
        return rclone_exe

    # 3. Fallback: check which rclone
    rclone_any = shutil.which("rclone")
    if rclone_any and os.path.abspath(rclone_any) != os.path.abspath(__file__):
        return rclone_any

    raise FileNotFoundError("Windows-native rclone.exe not found on host system.")

def convert_arg(arg: str) -> str:
    # If flag or option starting with -, leave intact
    if arg.startswith("-"):
        return arg
    
    # If remote path specification (e.g. gdrive:folder or remote:path), leave intact
    if ":" in arg and not arg.startswith("/") and not arg.startswith("."):
        return arg

    # Check if argument is a local filesystem path that exists or can be resolved
    if os.path.exists(arg) or arg.startswith("/") or arg.startswith("."):
        try:
            res = subprocess.run(["wslpath", "-w", arg], capture_output=True, text=True, check=True)
            win_path = res.stdout.strip()
            if win_path:
                return win_path
        except Exception:
            pass
    return arg

def main():
    try:
        rclone_bin = find_windows_rclone()
    except FileNotFoundError as err:
        print(f"[!] Error: {err}", file=sys.stderr)
        sys.exit(1)

    translated_args = [convert_arg(a) for a in sys.argv[1:]]
    cmd = [rclone_bin] + translated_args

    try:
        result = subprocess.run(cmd)
        sys.exit(result.returncode)
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"[!] Error executing rclone bridge: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
