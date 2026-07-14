#!/usr/bin/env python3
# ==============================================================================
# Path:        ai_io/ai_io.py
# Purpose:     Symmetrical AI/Human Context Harvester & Hardened Path Sandbox Manager
# Target OS:   Ubuntu 26.04 LTS / WSL2 Subsystem
# Lineage:     IrisLime Core AI Sandbox Engine
# Attribution: fekerr & Gemini (20260713_0705 Path Hardening Pass)
# ==============================================================================

import os
import sys
import argparse
import subprocess
from datetime import datetime
from pathlib import Path

def find_workspace_root() -> Path:
    """Traverses upward to identify the authoritative repository anchor."""
    current = Path(__file__).resolve().parent
    for parent in [current] + list(current.parents):
        if (parent / ".git").exists() or (parent / "pyproject.toml").exists():
            return parent
    return current.parent

# Globally enforce the hardened path boundary location
WORKSPACE_ROOT = find_workspace_root()

def generate_session_id(slug: str) -> str:
    """Generates a clean, scannable chronological session identity token."""
    timestamp = datetime.now().strftime("%y%m%d_%H%M")
    clean_slug = slug.strip().lower().replace(" ", "_").replace("-", "_")
    return f"session_{timestamp}_{clean_slug}" if clean_slug else f"session_{timestamp}_active"

def extract_git_status() -> str:
    """Safely extracts raw git telemetry metrics natively from the index."""
    try:
        res = subprocess.run(["git", "status", "-s"], capture_output=True, text=True, check=True, cwd=WORKSPACE_ROOT)
        return res.stdout if res.stdout.strip() else "Git index is completely clean."
    except Exception as e:
        return f"Failed to gather repository indexing details: {e}"

def write_agent_io(target_dir: Path, session_id: str, slug: str):
    """Generates the unified human/AI readable asset mirror boundary."""
    agent_file = target_dir / "agent_io.txt"
    git_status_snapshot = extract_git_status()
    timestamp_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    content = f"""==============================================================================
IRISLIME AGENT OVERVIEW: METADATA CONTEXT MATRIX
==============================================================================
Session ID   : {session_id}
Generated At : {timestamp_str}
Context Slug : {slug}
Target Path  : {target_dir}
Repo Root    : {WORKSPACE_ROOT}
==============================================================================

[ACTIVE WORK ENVIRONMENT DIRECTIVES]
* Current task focus: Local infrastructure optimization & user preference mapping.
* Working directory bounds: Isolated via scratch tracking arrays.
* Clipboard rule: Use clean, raw string segments to prevent browser crashes.

[LOCAL COMPILATION & GIT STATUS TELEMETRY]
{git_status_snapshot}

==============================================================================
END OF AGENT OVERVIEW FOR MIGRATION ROUTING
==============================================================================
"""
    agent_file.write_text(content, encoding="utf-8")
    print(f"[+] Symmetrical context signature written to: {agent_file.relative_to(WORKSPACE_ROOT)}")

def bootstrap_session(slug: str):
    """Provisions isolated scratch blocks, session metadata, and tracking states."""
    session_id = generate_session_id(slug)
    scratch_dir = WORKSPACE_ROOT / "scratch" / "sessions" / session_id
    scratch_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"\n[+] Initializing tracking loop: {session_id}")
    print(f"|-- Allocated temporary staging layout at: scratch/sessions/{session_id}/")
    
    write_agent_io(scratch_dir, session_id, slug)
    
    metadata_file = WORKSPACE_ROOT / "ai_io" / "metadata" / "active_session.txt"
    metadata_file.write_text(session_id, encoding="utf-8")

def main():
    parser = argparse.ArgumentParser(description="IrisLime Workspace Agent Interop Interface")
    parser.add_argument("--start", type=str, metavar="SLUG", help="Spawn an isolated tracking session with a workspace label")
    parser.add_argument("--sync", action="store_true", help="Refresh active session metadata logs and git status targets")
    
    args = parser.parse_args()
    
    if args.start:
        bootstrap_session(args.start)
    elif args.sync:
        metadata_file = WORKSPACE_ROOT / "ai_io" / "metadata" / "active_session.txt"
        if not metadata_file.exists():
            print("[X] Execution Halted: No active tracking loop found. Spin one up via --start first.")
            sys.exit(1)
        session_id = metadata_file.read_text().strip()
        scratch_dir = WORKSPACE_ROOT / "scratch" / "sessions" / session_id
        if scratch_dir.exists():
            write_agent_io(scratch_dir, session_id, "synchronized_update")
        else:
            print(f"[X] Directory error: Active target path scratch/sessions/{session_id} was removed.")

if __name__ == "__main__":
    main()
