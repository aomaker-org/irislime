#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/extract_telemetry.py
# Purpose:     Multi-target automated compilation lifespan telemetry extractor
# Type:        Utility Script
# Attribution: fekerr & Gemini (20260701_1652 / flash 3.5 extended)
# ==============================================================================

import os
import json
import sys
from datetime import datetime

def parse_birth_time_from_log(log_path):
    """Parses the log file header to find the exact shell invocation timestamp."""
    try:
        with open(log_path, "r", errors="ignore") as f:
            for _ in range(15):  # Scan the first 15 header lines
                line = f.readline()
                if not line:
                    break
                if "[Make Session] Launching Build at" in line:
                    # Extract the raw shell date string portion
                    date_part = line.split("Launching Build at")[-1].strip()
                    parts = date_part.split()
                    if len(parts) >= 6:
                        # parts format: ['Wed', 'Jul', '1', '12:38:09', 'PDT', '2026']
                        # Reconstruct a timezone-agnostic string to ensure cross-platform safety
                        clean_dt_str = f"{parts[1]} {parts[2]} {parts[3]} {parts[5]}"
                        return datetime.strptime(clean_dt_str, "%b %d %H:%M:%S %Y")
    except Exception as e:
        print(f"[!] Warning: Failed parsing log header for {log_path}: {e}")
    return None

def scan_and_extract_telemetry():
    print("\n[+] Initializing Multi-Target Forensic Telemetry Scan...")
    print("------------------------------------------------------------------")
    
    build_root = "build"
    telemetry_summary_path = os.path.join(build_root, "telemetry_history.json")
    
    if not os.path.exists(build_root) or not os.path.isdir(build_root):
        print(f"[!] Abort: Root '{build_root}' directory does not exist.")
        return False
        
    # Discover all valid build folders containing a live default log target
    target_dirs = []
    for item in os.listdir(build_root):
        item_path = os.path.join(build_root, item)
        if os.path.isdir(item_path):
            log_candidate = os.path.join(item_path, "logs", "build_default.log")
            if os.path.exists(log_candidate):
                target_dirs.append((item, log_candidate))
                
    if not target_dirs:
        print("[!] No active compilation logs discovered inside the build matrix topology.")
        return False
        
    print(f"[Discovery] Detected {len(target_dirs)} valid target compilation profiles.")
    
    new_records = []
    
    for folder_name, log_path in target_dirs:
        # Extract target and profile characteristics from folder naming boundaries
        # e.g., openvino_relwithdebinfo -> target: openvino, profile: relwithdebinfo
        folder_split = folder_name.split('_')
        target = folder_split[0]
        profile = folder_split[1] if len(folder_split) > 1 else "Default"
        
        # 1. Capture Death Time (Filesystem modification timestamp of active log)
        mtime_raw = os.path.getmtime(log_path)
        death_time = datetime.fromtimestamp(mtime_raw)
        
        # 2. Capture Birth Time (Parsed from textual internal file header)
        birth_time = parse_birth_time_from_log(log_path)
        
        if not birth_time:
            # Fallback to filesystem creation timestamps if header is corrupt/missing
            birth_time = datetime.fromtimestamp(os.path.getctime(log_path))
            print(f"[-] Warning: Falling back to OS descriptor timestamps for {folder_name}")
            
        # 3. Compute Delta-T Durations
        duration_delta = death_time - birth_time
        total_seconds = int(duration_delta.total_seconds())
        
        if total_seconds < 0:
            total_seconds = 0  # Guard rails against filesystem clock anomalies
            
        minutes, seconds = divmod(total_seconds, 60)
        hours, minutes = divmod(minutes, 60)
        duration_readable = f"{hours:02d}:{minutes:02d}:{seconds:02d}" if hours > 0 else f"{minutes:02d}:{seconds:02d}"
        
        payload = {
            "target": target,
            "profile": profile,
            "folder": folder_name,
            "birth_timestamp": birth_time.strftime("%Y-%m-%d %H:%M:%S"),
            "death_timestamp": death_time.strftime("%Y-%m-%d %H:%M:%S"),
            "total_execution_seconds": total_seconds,
            "elapsed_duration": duration_readable,
            "status": "COMPLETED"
        }
        new_records.append(payload)

    # Load persistent historical records to prevent duplicating session timestamps
    existing_history = []
    if os.path.exists(telemetry_summary_path):
        try:
            with open(telemetry_summary_path, "r") as hf:
                existing_history = json.load(hf)
        except json.JSONDecodeError:
            pass

    # Unique identity mapping using a composite key (folder profile + initialization time)
    history_keys = {(r.get("folder"), r.get("birth_timestamp")) for r in existing_history}
    
    for rec in new_records:
        key = (rec["folder"], rec["birth_timestamp"])
        if key not in history_keys:
            existing_history.append(rec)
            
    # Commit the updated persistent timeline matrix back to disk
    with open(telemetry_summary_path, "w") as hf:
        json.dump(existing_history, hf, indent=2)
        
    # Render the comparison matrix interface right to the console
    print("\n==========================================================================================")
    print(f"                         GLOBAL COMPILATION TELEMETRY COMPARISON MATRIX")
    print("==========================================================================================")
    print(f" {'TARGET PROFILE':25} | {'LAUNCH TIMESTAMP':19} | {'COMPLETED TIMESTAMP':19} | {'DURATION':10}")
    print("------------------------------------------------------------------------------------------")
    for rec in sorted(new_records, key=lambda x: x['total_execution_seconds']):
        prof_str = f"{rec['target']} ({rec['profile']})"
        print(f" {prof_str:25} | {rec['birth_timestamp']:19} | {rec['death_timestamp']:19} | {rec['elapsed_duration']:10}")
    print("==========================================================================================\n")
    return True

if __name__ == "__main__":
    scan_and_extract_telemetry()
