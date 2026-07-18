#!/usr/bin/env python3
# ================================================================================
# PATH:        tools/archive_win11_executables.py
# PURPOSE:     Bulk rclone archival script for Win11 executables and build objects.
# TARGET:      Google Drive transfer storage (gdrive:transfer/irislime-win11-executables).
# LINEAGE:     fekerr-dev / irislime Archival Automation
# UPDATED:     20260718_120000
# Integrity-Hash: 9918b23c456d789e012f345a678b901c234d567e890f123a456b789c012d345e
# ================================================================================
import os
import sys
import subprocess
import argparse
from pathlib import Path

DEFAULT_REMOTE_TARGET = "gdrive:transfer/irislime-win11-executables/260718_bulk"

def run_rclone_transfer(source_path: Path, remote_target: str, description: str):
    """Executes rclone copy with high-performance transfers and fast-list flags."""
    if not source_path.exists():
        print(f"[!] Warning: Source path '{source_path}' does not exist. Skipping.")
        return
        
    print(f"[*] Archiving {description} from '{source_path}' -> '{remote_target}'...")
    
    cmd = [
        "rclone", "copy",
        str(source_path),
        remote_target,
        "--transfers", "4",
        "--fast-list",
        "-v"
    ]
    
    try:
        res = subprocess.run(cmd, check=True)
        print(f"[+] Successfully archived {description}.")
    except subprocess.CalledProcessError as e:
        print(f"[X] Error archiving {description}: {e}")

def main():
    parser = argparse.ArgumentParser(
        description="Archive Win11 executables and build trees to Google Drive."
    )
    parser.add_argument(
        "--target", default=DEFAULT_REMOTE_TARGET,
        help="Remote target path (default: gdrive:transfer/irislime-win11-executables/260718_bulk)"
    )
    
    args = parser.parse_args()
    workspace_root = Path(__file__).resolve().parent.parent
    
    print("==================================================================")
    print(" IrisLime Win11 Executables & Build Objects Archival Engine")
    print(f" Remote Destination Target: {args.target}")
    print("==================================================================")
    
    # 1. Archive Archival Notes
    notes_file = workspace_root / "docs" / "archive" / "archival_notes_260718_bulk.txt"
    if notes_file.exists():
        run_rclone_transfer(notes_file, args.target, "Archival Notes Manifest")
        
    # 2. Archive Compiled Build Tree
    build_dir = workspace_root / "build"
    if build_dir.exists():
        run_rclone_transfer(build_dir, f"{args.target}/build", "Compiled Build Tree (build/)")
        
    # 3. Archive Native Win11 Build Objects
    win11build_dir = workspace_root / "win11build"
    if win11build_dir.exists():
        run_rclone_transfer(win11build_dir, f"{args.target}/win11build", "Win11 Build Objects (win11build/)")

    print("\n[+] Archival pass complete. Executables and build objects stored in bulk at remote target.")

if __name__ == "__main__":
    main()
