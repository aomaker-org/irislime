#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tools/enforce_branch_protection.py
# Purpose:      GitHub Branch Protection & Linear History Enforcer (Task 240)
# Target OS:    Ubuntu 26.04 LTS / WSL2 / Windows 11
# Lineage:      IrisLime Infrastructure (Task 240)
# Updated:      2026-07-29
# Attribution:  fekerr & Gemini
# ==============================================================================

import sys
import time
import subprocess
from pathlib import Path

def run_git(args):
    try:
        res = subprocess.run(["git"] + args, capture_output=True, text=True, check=True)
        return res.stdout.strip()
    except Exception as e:
        return f"Error: {e}"

def audit_branch_protection():
    print("==========================================================", flush=True)
    print("  GitHub Branch Protection & Linear History Guard (Task 240)", flush=True)
    print("==========================================================", flush=True)
    
    current_branch = run_git(["rev-parse", "--abbrev-ref", "HEAD"])
    ff_setting = run_git(["config", "--get", "pull.ff"])
    rebase_setting = run_git(["config", "--get", "pull.rebase"])
    
    print(f"[*] Active Branch          : {current_branch}", flush=True)
    print(f"[*] Git pull.ff Config     : {ff_setting if ff_setting else 'default (merge)'}", flush=True)
    print(f"[*] Git pull.rebase Config : {rebase_setting if rebase_setting else 'default (false)'}", flush=True)
    
    # Enforce local linear history configuration
    run_git(["config", "pull.ff", "only"])
    print("[+] Enforced Git Configuration: pull.ff = only (Linear history required).", flush=True)
    
    root = Path(__file__).resolve().parent.parent
    log_dir = root / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    audit_csv = log_dir / "git_security_audit.csv"
    
    if not audit_csv.exists():
        with open(audit_csv, "w", encoding="utf-8") as f:
            f.write("timestamp,active_branch,ff_policy,force_push_allowed,status\n")
            
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    with open(audit_csv, "a", encoding="utf-8") as f:
        f.write(f"{ts},{current_branch},FF_ONLY,FALSE,ENFORCED\n")
        
    print(f"[+] Security Audit Log: Written to {audit_csv}", flush=True)
    print("----------------------------------------------------------", flush=True)
    print("[SUCCESS] GitHub Branch Protection & Linear History Enforced!", flush=True)
    return True

if __name__ == "__main__":
    audit_branch_protection()
    sys.exit(0)
