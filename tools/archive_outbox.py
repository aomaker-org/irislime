#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tools/archive_outbox.py
# Purpose:      Automated Outbox Lifecycle Archiver & Buffer Purge Utility
# Target OS:    Ubuntu 26.04 LTS / WSL2 / Windows 11
# Lineage:      IrisLime Infrastructure (Turn 14 Protocol Specification)
# Updated:      2026-07-29
# Attribution:  fekerr & Gemini
# ==============================================================================

import os
import sys
import glob
import shutil
import datetime
from pathlib import Path

def archive_outbox_reports(keep_latest: int = 1):
    root = Path(__file__).resolve().parent.parent
    outbox_dir = root / "outbox"
    archive_dir = outbox_dir / "archive"
    archive_dir.mkdir(parents=True, exist_ok=True)
    (archive_dir / ".gitkeep").touch(exist_ok=True)

    # Gather all markdown status reports in ./outbox/
    md_files = sorted([f for f in outbox_dir.glob("*.md") if f.is_file()])
    if len(md_files) <= keep_latest:
        print(f"[*] Outbox buffer nominal: {len(md_files)} file(s) present (Keep limit: {keep_latest}).")
        return

    # Keep the latest 'keep_latest' files active; archive the rest
    to_archive = md_files[:-keep_latest] if keep_latest > 0 else md_files
    print(f"[*] Sweeping {len(to_archive)} processed outbox report(s) into {archive_dir.relative_to(root)}...")

    archived_count = 0
    for file_path in to_archive:
        dest_path = archive_dir / file_path.name
        
        # Collision protection
        if dest_path.exists():
            ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            base, ext = os.path.splitext(file_path.name)
            dest_path = archive_dir / f"{base}_{ts}{ext}"

        try:
            shutil.move(str(file_path), str(dest_path))
            os.chmod(str(dest_path), 0o444)
            archived_count += 1
            print(f"  - Archived ({dest_path.name}): {file_path.name} -> chmod 444")
        except Exception as e:
            print(f"  [!] Failed to archive {file_path.name}: {e}")

    print(f"[+] Outbox sweep complete! Archived {archived_count} file(s). Active buffer size: {len(md_files) - archived_count}")

if __name__ == "__main__":
    archive_outbox_reports(keep_latest=1)
    sys.exit(0)
