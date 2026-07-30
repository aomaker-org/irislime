#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tools/branch_audit.py
# Purpose:      Git Branch Consolidation & Lineage Auditor (Task 230)
# Target OS:    Ubuntu 26.04 LTS / WSL2 / Windows 11
# Lineage:      IrisLime Infrastructure (Task 230)
# Updated:      2026-07-29
# Attribution:  fekerr & Gemini
# ==============================================================================

import sys
import subprocess
from pathlib import Path

def run_git_cmd(args):
    try:
        res = subprocess.run(["git"] + args, capture_output=True, text=True, check=True)
        return res.stdout.strip()
    except Exception as e:
        return f"Error: {e}"

def audit_branches():
    print("==========================================================", flush=True)
    print("  Git Branch Consolidation & Lineage Auditor (Task 230)   ", flush=True)
    print("==========================================================", flush=True)
    
    current_branch = run_git_cmd(["rev-parse", "--abbrev-ref", "HEAD"])
    head_commit = run_git_cmd(["rev-parse", "--short", "HEAD"])
    print(f"[*] Active Working Branch : {current_branch} ({head_commit})", flush=True)
    
    raw_branches = run_git_cmd(["branch", "-a"])
    branches = [b.strip().replace("* ", "") for b in raw_branches.splitlines() if b.strip()]
    
    local_branches = [b for b in branches if not b.startswith("remotes/")]
    remote_branches = [b for b in branches if b.startswith("remotes/")]
    
    print(f"[*] Total Local Branches  : {len(local_branches)} ({', '.join(local_branches)})", flush=True)
    print(f"[*] Total Remote Tracking : {len(remote_branches)} feature/tracking branches", flush=True)
    
    root = Path(__file__).resolve().parent.parent
    log_dir = root / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    report_file = log_dir / "branch_audit_report.txt"
    
    with open(report_file, "w", encoding="utf-8") as f:
        f.write("==================================================================\n")
        f.write("IRISLIME BRANCH CONSOLIDATION & LINEAGE REPORT\n")
        f.write(f"Timestamp      : {subprocess.run(['date', '-u'], capture_output=True, text=True).stdout.strip()}\n")
        f.write(f"Active Branch  : {current_branch} ({head_commit})\n")
        f.write(f"Local Count    : {len(local_branches)}\n")
        f.write(f"Remote Count   : {len(remote_branches)}\n")
        f.write("==================================================================\n\n")
        f.write("ALL DISCOVERED BRANCHES:\n")
        for b in branches:
            f.write(f"  - {b}\n")
            
    print(f"[+] Audit Report Generated: {report_file}", flush=True)
    print("----------------------------------------------------------", flush=True)
    print("[SUCCESS] Branch Consolidation Audit Complete!", flush=True)
    return True

if __name__ == "__main__":
    audit_branches()
    sys.exit(0)
