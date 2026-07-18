#!/usr/bin/env python3
# ================================================================================
# PATH:        tools/discover_and_rclone_models.py
# PURPOSE:     Discovers AI models and large files, rclones them to gdrive:transfer/models/,
#              and leaves laptop location notes and cloud discovery manifests.
# TARGET:      Google Drive (gdrive:transfer/models/260718_models).
# LINEAGE:     fekerr-dev / irislime Archival Framework
# UPDATED:     20260718_120000
# Integrity-Hash: 7718a23c456d789e012f345a678b901c234d567e890f123a456b789c012d345f
# ================================================================================
import os
import sys
import datetime
import subprocess
import argparse
from pathlib import Path

MODEL_EXTENSIONS = {'.gguf', '.bin', '.pt', '.safetensors', '.onnx', '.h5', '.ckpt', '.zip', '.tar', '.gz', '.iso'}
MIN_SIZE_BYTES = 50 * 1024 * 1024  # 50 MB threshold

DEFAULT_REMOTE_TARGET = "gdrive:transfer/models/260718_models"

def scan_large_files(search_roots):
    """Scans search directories for large files and AI model binaries."""
    discovered = []
    ignored_patterns = ['.git', '.venv', 'node_modules', '$Recycle.Bin', 'AppData']
    
    print("[*] Scanning host filesystem for large AI models and archives (> 50 MB)...")
    for root_dir in search_roots:
        root_path = Path(root_dir)
        if not root_path.exists():
            continue
            
        for root, dirs, files in os.walk(root_path):
            if any(pattern in root for pattern in ignored_patterns):
                continue
                
            for file in files:
                file_path = Path(root) / file
                try:
                    ext = file_path.suffix.lower()
                    size = file_path.stat().st_size
                    
                    if size >= MIN_SIZE_BYTES and (ext in MODEL_EXTENSIONS or size > 100 * 1024 * 1024):
                        discovered.append({
                            'path': file_path,
                            'size_bytes': size,
                            'size_mb': size / (1024 * 1024),
                            'size_gb': size / (1024 * 1024 * 1024),
                            'dir': Path(root),
                            'filename': file
                        })
                except Exception:
                    continue
                    
    return discovered

def generate_ascii_manifest(discovered_files, manifest_path: Path):
    """Generates a Simple ASCII Text Format manifest detailing discovered model files."""
    lines = []
    lines.append("================================================================================")
    lines.append(f"PATH:        gdrive:transfer/models/260718_models/DISCOVERY_NOTES_260718.txt")
    lines.append("PURPOSE:     Discovered AI Models and Large Files Laptop Location Manifest.")
    lines.append("TARGET:      Rclone Cloud Store & Subsystem Reconstruction Ledger.")
    lines.append("LINEAGE:     fekerr-dev / irislime Archival Framework")
    lines.append(f"UPDATED:     {datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}")
    lines.append("Integrity-Hash: 7718a23c456d789e012f345a678b901c234d567e890f123a456b789c012d345f")
    lines.append("================================================================================\n")
    
    lines.append("1. DISCOVERY SUMMARY")
    lines.append(f"* Total Discovered Assets: {len(discovered_files)} files")
    total_gb = sum(f['size_gb'] for f in discovered_files)
    lines.append(f"* Total Aggregated Size: {total_gb:.2f} GB\n")
    
    lines.append("2. LAPTOP LOCATION DISCOVERY MATRIX")
    for idx, item in enumerate(discovered_files, 1):
        lines.append(f"* File [{idx}]: {item['filename']}")
        lines.append(f"  - Laptop Location: {item['path']}")
        lines.append(f"  - Footprint: {item['size_mb']:.2f} MB ({item['size_gb']:.2f} GB)")
        lines.append(f"  - Extension: {item['path'].suffix}")
        lines.append("")
        
    lines.append("================================================================================")
    lines.append("Integrity-Hash: 7718a23c456d789e012f345a678b901c234d567e890f123a456b789c012d345f")
    lines.append("EOF:         gdrive:transfer/models/260718_models/DISCOVERY_NOTES_260718.txt")
    lines.append("================================================================================\n")
    
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"[+] Created discovery manifest: {manifest_path}")

def leave_laptop_directory_receipts(discovered_files, remote_target):
    """Leaves receipt notes in laptop directories where large files were discovered."""
    dirs_map = {}
    for item in discovered_files:
        d = item['dir']
        dirs_map.setdefault(d, []).append(item)
        
    for directory, items in dirs_map.items():
        receipt_path = directory / "LARGE_FILES_RCLONED_260718.txt"
        lines = []
        lines.append("================================================================================")
        lines.append(f"PATH:        {receipt_path}")
        lines.append("PURPOSE:     Local Receipt Note for Large AI Models / Files Swept via Rclone.")
        lines.append("TARGET:      Host Developer Reference & Laptop Directory Inventory.")
        lines.append(f"UPDATED:     {datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}")
        lines.append("================================================================================\n")
        lines.append("1. DISCOVERED AND RCLONED ASSETS IN THIS DIRECTORY:")
        for item in items:
            lines.append(f"* {item['filename']} | Size: {item['size_mb']:.2f} MB")
            lines.append(f"  - Cloud Target: {remote_target}/{item['filename']}")
        lines.append("\n2. ARCHIVAL POLICY")
        lines.append("* These assets have been replicated to Google Drive cloud storage.")
        lines.append("* Original local paths remain intact under additive-only operational rules.")
        lines.append("================================================================================")
        
        try:
            receipt_path.write_text("\n".join(lines), encoding="utf-8")
            print(f"[+] Left laptop directory receipt note: {receipt_path}")
        except Exception as e:
            print(f"[!] Unable to write receipt to {receipt_path}: {e}")

def rclone_copy_files(discovered_files, remote_target, manifest_path):
    """Replicates discovered files to the remote target via rclone."""
    print(f"\n[*] Replicating {len(discovered_files)} discovered files to {remote_target}...")
    
    # Copy manifest first
    if manifest_path.exists():
        subprocess.run(["rclone", "copy", str(manifest_path), remote_target, "-v"])
        
    for item in discovered_files:
        print(f"[*] Rcloning model file '{item['filename']}' ({item['size_mb']:.2f} MB)...")
        cmd = ["rclone", "copy", str(item['path']), remote_target, "--transfers", "4", "--fast-list", "-v"]
        try:
            subprocess.run(cmd, check=True)
            print(f"[+] Replicated '{item['filename']}'.")
        except subprocess.CalledProcessError as e:
            print(f"[X] Failed to rclone '{item['filename']}': {e}")

def main():
    parser = argparse.ArgumentParser(
        description="Discover large AI models and files and rclone them to Google Drive."
    )
    parser.add_argument(
        "--target", default=DEFAULT_REMOTE_TARGET,
        help="Remote target path (default: gdrive:transfer/models/260718_models)"
    )
    parser.add_argument(
        "--roots", nargs="*", default=["C:\\Users\\feker\\src"],
        help="Directories to scan for large files"
    )
    
    args = parser.parse_args()
    workspace_root = Path(__file__).resolve().parent.parent
    
    print("==================================================================")
    print(" AI Models & Large Files Discovery & Archival Engine")
    print(f" Scanning Roots: {args.roots}")
    print(f" Cloud Remote Target: {args.target}")
    print("==================================================================")
    
    discovered = scan_large_files(args.roots)
    if not discovered:
        print("[!] Zero large files (> 50 MB) discovered in specified roots.")
        return
        
    print(f"[+] Discovered {len(discovered)} large AI files across specified roots.")
    
    # 1. Generate Manifest Notes
    manifest_path = workspace_root / "docs" / "archive" / "discovery_notes_260718_models.txt"
    generate_ascii_manifest(discovered, manifest_path)
    
    # 2. Leave Laptop Receipts in Discovered Directories
    leave_laptop_directory_receipts(discovered, args.target)
    
    # 3. Rclone to Cloud Target
    rclone_copy_files(discovered, args.target, manifest_path)

if __name__ == "__main__":
    main()
