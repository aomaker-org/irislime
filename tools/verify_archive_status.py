#!/usr/bin/env python3
"""
IrisLime WSL Handshake Verification Tool

Checks for the cross-host handshake receipt (tools/windows_rclone_receipt.json)
written by Windows-native rclone engine to verify cloud delivery from WSL.
"""

import json
import os
import sys
from pathlib import Path

def get_workspace_root() -> Path:
    return Path(__file__).resolve().parent.parent

def check_handshake():
    root = get_workspace_root()
    receipt_path = root / "tools" / "windows_rclone_receipt.json"
    manifest_path = root / "tools" / "windows_rclone_manifest.json"

    print("==========================================================")
    print("  IrisLime Cross-Host Log Archival Handshake Monitor     ")
    print("==========================================================")

    if not manifest_path.exists():
        print("[!] No active archival manifest found (tools/windows_rclone_manifest.json).")
        return False

    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    print(f"Target Package : {manifest.get('zip_package')}")
    print(f"Remote Target  : {manifest.get('remote_destination')}")
    print("----------------------------------------------------------")

    win_receipt = Path("/mnt/c/Users/feker/src/irislime/tools/windows_rclone_receipt.json")
    if not receipt_path.exists() and win_receipt.exists():
        receipt_path = win_receipt
        try:
            import shutil
            shutil.copy2(win_receipt, root / "tools" / "windows_rclone_receipt.json")
        except Exception:
            pass

    if not receipt_path.exists():
        print("[STATUS] PENDING: Windows rclone transfer has not completed yet.")
        print("         Waiting for tools/windows_rclone_receipt.json handshake receipt.")
        return False

    with open(receipt_path, "r", encoding="utf-8") as f:
        receipt = json.load(f)

    if receipt.get("status") == "SUCCESS" and receipt.get("verified"):
        print("[SUCCESS] HANDSHAKE CONFIRMED!")
        print(f"  Status        : {receipt.get('status')}")
        print(f"  Package       : {receipt.get('package')}")
        print(f"  Remote        : {receipt.get('remote_destination')}")
        print(f"  Transferred At: {receipt.get('transferred_at_utc')}")
        print("\n[+] WSL environment has verified that Windows host completed cloud transfer.")
        return True
    else:
        print(f"[!] Receipt found, but transfer status is: {receipt.get('status')}")
        return False

if __name__ == "__main__":
    success = check_handshake()
    sys.exit(0 if success else 1)
