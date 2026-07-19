#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# IDENTIFIER:  tools/xfer.py
# AUTHOR:      fekerr & Gemini
# VERSION:     1.7.0
# TIMESTAMP:   20260714_0850
# ==============================================================================

import os
import sys
import argparse
import subprocess
import hashlib
import re
from datetime import datetime
from pathlib import Path

import clip_helper

__version__ = "1.7.0"

def find_workspace_root() -> Path:
    current = Path(__file__).resolve().parent
    for parent in [current] + list(current.parents):
        if (parent / ".git").exists() or (parent / "pyproject.toml").exists():
            return parent
    return current.parent

WORKSPACE_ROOT = find_workspace_root()

def get_git_branch() -> str:
    try:
        res = subprocess.run(["git", "branch", "--show-current"], capture_output=True, text=True, check=True, cwd=WORKSPACE_ROOT)
        return res.stdout.strip() if res.stdout.strip() else "Detached HEAD"
    except Exception:
        return "Unknown Branch"

def compute_string_hash(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()

def extract_prompt_tokens(content: str) -> str:
    matches = re.findall(r"\b\d{4}_\d{4}_\d{4}\b", content)
    return ", ".join(matches) if matches else "none"

def get_rclone_base_cmd() -> list:
    hypervisor = os.environ.get("HYPERVISOR_DETECTED", "")
    if hypervisor == "native_win11" or sys.platform == "win32":
        return ["rclone.exe"]
    base_cmd = ["rclone"]
    fallback_path = os.environ.get("RCLONE_CONFIG_FALLBACK", "/mnt/c/Users/feker/AppData/Roaming/rclone/rclone.conf")
    if os.path.exists(fallback_path):
        base_cmd.extend(["--config", fallback_path])
    return base_cmd

def ensure_sandbox_identity(sandbox_dir: Path):
    try:
        res = subprocess.run(["git", "config", "user.name"], cwd=sandbox_dir, capture_output=True, text=True)
        if not res.stdout.strip():
            subprocess.run(["git", "config", "local", "user.name", "Fred Kerr (AIO Sandbox)"], cwd=sandbox_dir, check=True)
            subprocess.run(["git", "config", "local", "user.email", "fekerr@users.noreply.github.com"], cwd=sandbox_dir, check=True)
    except Exception:
        pass

def commit_to_local_sandbox(sandbox_dir: Path, commit_msg: str) -> bool:
    """Commits sandbox changes and returns True if modifications were actually committed."""
    is_new = not (sandbox_dir / ".git").exists()
    if is_new:
        try:
            subprocess.run(["git", "init", "-b", "scratch"], cwd=sandbox_dir, capture_output=True, check=True)
            (sandbox_dir / ".gitignore").write_text("blobs/\nrclone_bg_sync.log\n", encoding="utf-8")
        except Exception:
            try:
                subprocess.run(["git", "init"], cwd=sandbox_dir, capture_output=True, check=True)
                subprocess.run(["git", "checkout", "-b", "scratch"], cwd=sandbox_dir, capture_output=True, check=True)
                (sandbox_dir / ".gitignore").write_text("blobs/\nrclone_bg_sync.log\n", encoding="utf-8")
            except Exception:
                return False

    ensure_sandbox_identity(sandbox_dir)

    try:
        subprocess.run(["git", "add", "."], cwd=sandbox_dir, capture_output=True, check=True)
        # Check if there are actual changes to commit
        status_res = subprocess.run(["git", "status", "--porcelain"], cwd=sandbox_dir, capture_output=True, text=True)
        if not status_res.stdout.strip():
            return False # No changes to commit
            
        subprocess.run(["git", "commit", "-m", commit_msg], cwd=sandbox_dir, capture_output=True)
        return True
    except Exception:
        return False

def transmit_via_rclone_background(local_aio_dir: Path, rclone_destination: str):
    base_cmd = get_rclone_base_cmd()
    log_file = local_aio_dir / "rclone_bg_sync.log"
    is_windows = (sys.platform == "win32" or os.environ.get("HYPERVISOR_DETECTED") == "native_win11")
    
    if is_windows:
        rclone_bin = "rclone.exe"
        shell_cmd = (
            f'"{rclone_bin}" sync "{local_aio_dir}" "{rclone_destination}/state" --exclude "blobs/**" --exclude ".git/**" '
            f'&& "{rclone_bin}" copy "{local_aio_dir}/blobs" "{rclone_destination}/blobs" --immutable'
        )
    else:
        rclone_bin = " ".join(base_cmd)
        shell_cmd = (
            f"{rclone_bin} sync '{local_aio_dir}' '{rclone_destination}/state' --exclude 'blobs/**' --exclude '.git/**' "
            f"&& {rclone_bin} copy '{local_aio_dir}/blobs' '{rclone_destination}/blobs' --immutable"
        )
        
    try:
        with open(log_file, "a") as log_out:
            subprocess.Popen(
                shell_cmd,
                shell=True,
                stdout=log_out,
                stderr=log_out,
                preexec_fn=None if is_windows else os.setpgrp
            )
    except Exception:
        pass

def log_transaction_to_cas(action_type: str, raw_payload: str) -> str:
    aio_env = os.environ.get("IRISLIME_AIO", "scratch/aio")
    local_aio_path = WORKSPACE_ROOT / aio_env
    blobs_dir = local_aio_path / "blobs"
    tx_dir = local_aio_path / "transactions"
    
    blobs_dir.mkdir(parents=True, exist_ok=True)
    tx_dir.mkdir(parents=True, exist_ok=True)
    
    payload_hash = compute_string_hash(raw_payload)
    blob_file = blobs_dir / f"{payload_hash}.txt"
    if not blob_file.exists():
        blob_file.write_text(raw_payload, encoding="utf-8")
        
    prompt_metadata = extract_prompt_tokens(raw_payload)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    tx_file = tx_dir / f"tx_{timestamp}_{action_type}.txt"
    tx_content = f"""# ==============================================================================
# TRANSACTION POINTER: {tx_file.name}
# TIMESTAMP:           {datetime.now().isoformat()}
# SYSTEM VERSION:      {__version__}
# ==============================================================================
[transaction]
action_type  = "{action_type}"
git_branch   = "{get_git_branch()}"
os_release   = "{os.uname().release if hasattr(os, 'uname') else sys.platform}"
prompt_tokens = "{prompt_metadata}"

[cas_pointer]
blob_sha256  = "{payload_hash}"
blob_path    = "blobs/{payload_hash}.txt"
size_chars   = {len(raw_payload)}
# ==============================================================================
"""
    tx_file.write_text(tx_content, encoding="utf-8")
    return payload_hash

def execute_sweep():
    print("[*] Initiating Active Context Clean Sweep...")
    aio_env = os.environ.get("IRISLIME_AIO", "scratch/aio")
    local_aio_path = WORKSPACE_ROOT / aio_env
    
    scratch_files = list(WORKSPACE_ROOT.glob("scratch/*.txt")) + list(WORKSPACE_ROOT.glob("scratch/*.md"))
    root_status_files = list(WORKSPACE_ROOT.glob("gemini_status_*.txt"))
    
    target_items = [x for x in (scratch_files + root_status_files) if x.is_file()]
    if not target_items:
        print("    [+] Sweep complete: No misplaced files identified.")
        return
        
    for item in target_items:
        content = item.read_text(encoding="utf-8")
        blob_hash = log_transaction_to_cas("swept_file", content)
        print(f"    [+] Swept and archived: {item.name} -> blobs/{blob_hash[:16]}...")
        item.unlink()
        
    committed = commit_to_local_sandbox(local_aio_path, f"Sweep executed: {len(target_items)} files archived (v{__version__})")
    
    rclone_remote = os.environ.get("GDRIVE_REMOTE_PATH", "gdrive:xfer_260713")
    if committed and rclone_remote:
        transmit_via_rclone_background(local_aio_path, rclone_remote)

def verify_system_status():
    aio_env = os.environ.get("IRISLIME_AIO", "scratch/aio")
    local_aio_path = WORKSPACE_ROOT / aio_env
    rclone_remote = os.environ.get("GDRIVE_REMOTE_PATH", "gdrive:xfer_260713")
    
    print("==================================================================")
    print(f"[+] IRISLIME CAS SYSTEM TELEMETRY SUMMARY (v{__version__})")
    print(f"[*] Execution Path : {Path.cwd()}")
    print(f"[*] Repository Root: {WORKSPACE_ROOT} [Branch: {get_git_branch()}]")
    print("==================================================================")
    
    # 1. Inspect Clipboard Payload
    clip_data = clip_helper.get_host_clipboard()
    print(f"[*] Host Clipboard Status Buffer: {len(clip_data)} characters detected.")
    
    has_footprint = "session_" in clip_data or "EOR" in clip_data
    
    # Render Head/Tail Clipboard Preview if payload has content
    if len(clip_data) > 0:
        lines = clip_data.splitlines()
        print("[i] Clipboard Content Preview:")
        if len(lines) <= 6:
            for line in lines:
                print(f"    | {line}")
        else:
            for line in lines[:3]:
                print(f"    | {line}")
            print("    | ... [omitted lines] ...")
            for line in lines[-3:]:
                print(f"    | {line}")
                
    # 2. Idempotence Check
    if not has_footprint:
        # Check if local files have mutated
        status_res = subprocess.run(["git", "status", "--porcelain"], cwd=local_aio_path, capture_output=True, text=True)
        if not status_res.stdout.strip():
            print("[i] No workspace mutations or clipboard payloads detected. Sync skipped.")
            print("==================================================================")
            return

    # Log telemetry probe only if we are actually committing workspace mutations
    log_transaction_to_cas("status_probe", f"Telemetry sweep (v{__version__})")
    committed = commit_to_local_sandbox(local_aio_path, f"Telemetry check (v{__version__})")
    
    if committed and rclone_remote:
        transmit_via_rclone_background(local_aio_path, rclone_remote)
        
    if has_footprint:
        print("[!] Detected active AI UI response footprint. Ingesting automatically...")
        blob_hash = log_transaction_to_cas("clipboard_ingest", clip_data)
        print(f"[+] Payload saved cleanly to CAS blob: blobs/{blob_hash[:16]}...")
        
        committed_ingest = commit_to_local_sandbox(local_aio_path, f"Auto-ingested blob: {blob_hash[:8]}")
        clip_helper.format_and_prime_handshake(len(clip_data), "incremental_slice_complete")
        
        if committed_ingest and rclone_remote:
            transmit_via_rclone_background(local_aio_path, rclone_remote)
            
    print("==================================================================")

def main():
    parser = argparse.ArgumentParser(description="IrisLime CAS Transport Interface (v1.7.0)")
    parser.add_argument("--sweep", action="store_true", help="Execute context directory clean sweep")
    
    args = parser.parse_args()
    if args.sweep:
        execute_sweep()
    else:
        verify_system_status()

if __name__ == "__main__":
    main()
# ==============================================================================
# END OF FILE: tools/xfer.py
# ==============================================================================
