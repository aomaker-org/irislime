#!/bin/sh
''''which python3 >/dev/null 2>&1 && exec "$(dirname "$0")/../venv/bin/python3" "$0" "$@" # '''
# --- PORTABLE ENCAPSULATED SNAPSHOT GENERATOR ---
# This script creates an emergency/interim remote checkpoint branch
# and safely stages all untracked and modified prototyping artifacts.
#
# Execution Architecture: Runs in high-verbosity debug mode by default.
# Muting Hook: Export IRISLIME_HUSH=1 to suppress trace telemetry.

import os
import sys
import subprocess
from datetime import datetime

# Evaluate the execution visibility boundary variable natively
IS_HUSHED = os.environ.get("IRISLIME_HUSH") == "1"

def log_debug(message):
    """Outputs granular system tracking messages if the environment is not hushed."""
    if not IS_HUSHED:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] [DEBUG/TRACE] {message}")

def log_info(message):
    """Outputs critical milestones regardless of minor trace hushing constraints."""
    print(f"[+] {message}")

def run_cmd(cmd, check=True):
    """Executes a system subcommand with complete logging attribution."""
    log_debug(f"Invoking subprocess pipeline: {' '.join(cmd)}")
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=check)
        
        # Log internal output telemetry if populated
        if res.stdout and res.stdout.strip():
            log_debug(f"Command stdout payload block:\n---\n{res.stdout.strip()}\n---")
        if res.stderr and res.stderr.strip():
            log_debug(f"Command stderr payload block:\n---\n{res.stderr.strip()}\n---")
            
        return res.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"[!] Critical Execution Failure on Command: {' '.join(cmd)}", file=sys.stderr)
        print(f"[!] Exit Code Returned: {e.returncode}", file=sys.stderr)
        print(f"[!] Error Telemetry Context:\n{e.stderr.strip()}", file=sys.stderr)
        if check:
            sys.exit(1)
        return None

def main():
    log_debug("Initializing Context Framework for public repository development tracking.")
    
    # Verify execution happens inside a valid repository tree
    repo_root = run_cmd(["git", "rev-parse", "--show-toplevel"])
    log_debug(f"Canonical repository tracking root confirmed at: {repo_root}")
    os.chdir(repo_root)
    
    # 1. Gather Base Branch Context Metrics
    current_branch = run_cmd(["git", "branch", "--show-current"])
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    checkpoint_branch = f"checkpoint/irislime1-{timestamp}"
    
    log_info(f"Active Base Tracking Branch Identified: {current_branch}")
    log_info(f"Target Checkpoint Branch Initializing: {checkpoint_branch}")
    
    # 2. Check for Working Tree Modifications
    log_debug("Analyzing current git status layout to evaluate change density...")
    status_raw = run_cmd(["git", "status", "--porcelain"])
    if not status_raw:
        log_info("Working tree completely clean. No custom prototyping modifications found to track.")
    else:
        log_debug(f"Volatile modifications detected:\n{status_raw}")

    # 3. Spawn Isolated Checkpoint Branch
    log_debug(f"Executing local branch fork transition to: {checkpoint_branch}")
    run_cmd(["git", "checkout", "-b", checkpoint_branch])
    
    # 4. Stage All Working Tree State (Inclusive Staging Mode)
    log_info("Staging all volatile working tree elements and sandbox artifacts...")
    run_cmd(["git", "add", "-A"])
    
    # 5. Generate High-Attribution Commit Metadata
    commit_msg = (
        f"Design-Checkpoint: Interim Sandbox Snapshot ({timestamp})\n\n"
        f"Origin Directory: {repo_root}\n"
        f"Forked From Base Branch: {current_branch}\n"
        f"Automated extraction for fast prototyping preservation prior to workspace re-cloning."
    )
    
    log_debug("Committing state baseline to tracking index...")
    run_cmd(["git", "commit", "-m", commit_msg])
    
    # 6. Push Checkpoint Intact to Upstream Remote Authority
    log_info("Synchronizing checkpoint branch with remote origin tracking infrastructure...")
    run_cmd(["git", "push", "-u", "origin", checkpoint_branch])
    
    # 7. Revert Local State Context to Prevent Workspace Disruption
    log_debug(f"Restoring prior terminal branch environment to: {current_branch}")
    run_cmd(["git", "checkout", current_branch])
    
    log_info("Interim stable state successfully preserved on remote infrastructure.")
    log_info(f"Remote target path tracking active on upstream branch: '{checkpoint_branch}'")

if __name__ == "__main__":
    main()
