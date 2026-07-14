#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# IDENTIFIER:  tools/aio_monitor.py
# AUTHOR:      fekerr & Gemini
# VERSION:     1.6.0
# TIMESTAMP:   20260714_0854
# DESCRIPTION: Dual Git inspector with default multi-repo scanning
# ==============================================================================

import os
import sys
import argparse
import subprocess
import time
from pathlib import Path

def run_cmd(args, cwd=None):
    try:
        res = subprocess.run(args, capture_output=True, text=True, check=True, cwd=cwd)
        return res.stdout.strip(), None
    except subprocess.CalledProcessError as e:
        return "", e.stderr.strip() if e.stderr else str(e)
    except Exception as e:
        return "", str(e)

def render_repo_status(path: Path, name: str):
    print(f"[+] {name} (Location: {path})")
    git_dir = path / ".git"
    if git_dir.exists():
        logs, err = run_cmd(["git", "log", "-n", "3", "--oneline", "--decorate"], cwd=path)
        if err:
            print(f"    [!] Git status issue: {err}")
        else:
            for line in logs.splitlines():
                print(f"    {line}")
    else:
        print("    [!] Repository is not initialized yet.")

def run_dashboard_loop(root: Path, aio_path: Path):
    try:
        while True:
            os.system('cls' if os.name == 'nt' else 'clear')
            print("==================================================================")
            print(f"[+] IRISLIME LIVE DASHBOARD MONITOR (Press Ctrl+C to Exit)")
            print(f"[*] Local Time : {time.strftime('%Y-%m-%d %H:%M:%S')}")
            print("==================================================================")
            
            render_repo_status(root, "PRIMARY CODEBASE (Main)")
            print("-" * 66)
            render_repo_status(aio_path, "SCRATCHPAD SANDBOX (AIO)")
            print("-" * 66)
            
            log_file = aio_path / "rclone_bg_sync.log"
            if log_file.exists():
                print("[*] Cloud Transfer Log Tail (Last 3 Lines):")
                lines = log_file.read_text(encoding="utf-8").splitlines()
                for line in lines[-3:]:
                    print(f"    | {line}")
            else:
                print("[*] Cloud Transfer Log: No background syncs registered yet.")
                
            time.sleep(3)
    except KeyboardInterrupt:
        print("\n[*] Exiting Dashboard Mode.")

def main():
    parser = argparse.ArgumentParser(description="IrisLime Multi-Repo Inspector")
    parser.add_argument("--main", action="store_true", help="Inspect primary project repository only")
    parser.add_argument("--scratch", action="store_true", help="Inspect local scratchpad git sandbox only")
    parser.add_argument("--tail", action="store_true", help="Run in continuous dashboard monitor mode")
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    aio_env = os.environ.get("IRISLIME_AIO", "scratch/aio")
    aio_path = root / aio_env

    if args.tail:
        run_dashboard_loop(root, aio_path)
        return

    # Default to displaying BOTH repositories side-by-side if no specific flag is provided
    show_main = args.main or not args.scratch
    show_scratch = args.scratch or not args.main

    print("==================================================================")
    print(f"[+] IRISLIME STATE INSPECTOR (v1.6.0)")
    print("==================================================================")

    if show_main:
        render_repo_status(root, "PRIMARY CODEBASE (Main)")
        print("-" * 66)
        
    if show_scratch:
        render_repo_status(aio_path, "SCRATCHPAD SANDBOX (AIO)")
        blobs_dir = aio_path / "blobs"
        tx_dir = aio_path / "transactions"
        blobs_count = len(list(blobs_dir.glob("*.txt"))) if blobs_dir.exists() else 0
        txs_count = len(list(tx_dir.glob("*.txt"))) if tx_dir.exists() else 0
        print(f"    - Unique Content Blobs : {blobs_count}")
        print(f"    - Transaction Records  : {txs_count}")
        print("-" * 66)

    log_file = aio_path / "rclone_bg_sync.log"
    if log_file.exists():
        print("[*] Background Sync Diagnostic Summary:")
        size = log_file.stat().st_size
        print(f"    - Log File Size : {size} bytes")
        if size > 0:
            tail_lines = log_file.read_text(encoding="utf-8").splitlines()[-2:]
            for line in tail_lines:
                print(f"      | {line}")
    print("==================================================================")

if __name__ == "__main__":
    main()
