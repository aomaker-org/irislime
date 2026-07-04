#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/extract_telemetry.py
# Purpose:     Multi-target automated compilation lifespan telemetry extractor
#              Upgraded with a 60-second minimum duration noise floor filter.
# Type:        Utility Script
# Attribution: fekerr & Gemini (20260702_1932 / flash 3.5 extended)
# Timestamp:   20260702_1932
# ==============================================================================

import os
import json
import sys
import re
from datetime import datetime

def parse_birth_time_from_log(log_path):
    """Parses the legacy log file header to find the exact shell invocation timestamp."""
    try:
        with open(log_path, "r", errors="ignore") as f:
            for _ in range(15):  # Scan the first 15 header lines
                line = f.readline()
                if not line:
                    break
                if "[Make Session] Launching Build at" in line:
                    date_part = line.split("Launching Build at")[-1].strip()
                    parts = date_part.split()
                    if len(parts) >= 6:
                        # Reconstruct a timezone-agnostic string for cross-platform safety
                        clean_dt_str = f"{parts[1]} {parts[2]} {parts[3]} {parts[5]}"
                        return datetime.strptime(clean_dt_str, "%b %d %H:%M:%S %Y")
    except Exception as e:
        print(f"[!] Warning: Failed parsing log header for {log_path}: {e}")
    return None

def extract_metadata_from_folder(folder_name):
    """Deduces target and profile parameters safely from an isolated folder signature."""
    folder_split = folder_name.split('_')
    target = folder_split[0]
    profile = folder_split[1].capitalize() if len(folder_split) > 1 else "Default"
    return target, profile

def scan_and_extract_telemetry():
    print("\n[+] Initializing Unified Multi-Target Forensic Telemetry Scan...")
    print("[+] Noise Floor Active: Ignoring builds shorter than 60 seconds.")
    print("------------------------------------------------------------------")
    
    build_root = "build"
    log_root = os.path.join("logs", "builds")
    telemetry_summary_path = os.path.join(build_root, "telemetry_history.json")
    
    os.makedirs(build_root, exist_ok=True)
    discovered_logs = []  # Elements structured as: (target, profile, folder, log_path, birth_time)

    # ==========================================================================
    # PASS 1: Scan Legacy In-Tree Build Layout Targets
    # ==========================================================================
    if os.path.exists(build_root) and os.path.isdir(build_root):
        for item in os.listdir(build_root):
            item_path = os.path.join(build_root, item)
            if os.path.isdir(item_path):
                for log_name in ["build_default.log", "build_manual.log"]:
                    log_candidate = os.path.join(item_path, "logs", log_name)
                    if os.path.exists(log_candidate):
                        target, profile = extract_metadata_from_folder(item)
                        birth_time = parse_birth_time_from_log(log_candidate)
                        if not birth_time:
                            birth_time = datetime.fromtimestamp(os.path.getctime(log_candidate))
                        discovered_logs.append((target, profile, item, log_candidate, birth_time))

    # ==========================================================================
    # PASS 2: Scan Modern Orchestrated Out-Of-Tree Runner Log Trees
    # ==========================================================================
    if os.path.exists(log_root) and os.path.isdir(log_root):
        for item in os.listdir(log_root):
            item_path = os.path.join(log_root, item)
            if os.path.isdir(item_path):
                target, profile = extract_metadata_from_folder(item)
                for log_file in os.listdir(item_path):
                    if log_file.startswith("build_") and log_file.endswith(".log"):
                        full_log_path = os.path.join(item_path, log_file)
                        
                        time_match = re.search(r"build_(\d{8}_\d{6})", log_file)
                        if time_match:
                            try:
                                birth_time = datetime.strptime(time_match.group(1), "%Y%m%d_%H%M%S")
                            except ValueError:
                                birth_time = datetime.fromtimestamp(os.path.getctime(full_log_path))
                        else:
                            birth_time = datetime.fromtimestamp(os.path.getctime(full_log_path))
                            
                        discovered_logs.append((target, profile, item, full_log_path, birth_time))

    if not discovered_logs:
        print("[!] No active compilation logs discovered inside the build matrix topology.")
        return False
    
    new_records = []
    for target, profile, folder_name, log_path, birth_time in discovered_logs:
        mtime_raw = os.path.getmtime(log_path)
        death_time = datetime.fromtimestamp(mtime_raw)
        
        duration_delta = death_time - birth_time
        total_seconds = int(duration_delta.total_seconds())
        if total_seconds < 0:
            total_seconds = 0  # Clock skew protection
            
        # Noise Floor Filter: Ignore any session executing for less than 60 seconds
        if total_seconds < 60:
            continue
            
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

    if not new_records:
        print("[*] Scan complete. All discovered logs fell below the 60-second noise floor threshold.")
        return True

    print(f"[Discovery] Detected {len(new_records)} significant target execution metrics.")

    # Ingest historical data to prevent duplicate record entries
    existing_history = []
    if os.path.exists(telemetry_summary_path):
        try:
            with open(telemetry_summary_path, "r") as hf:
                existing_history = json.load(hf)
        except json.JSONDecodeError:
            pass

    history_keys = {(r.get("folder"), r.get("birth_timestamp")) for r in existing_history}
    
    for rec in new_records:
        key = (rec["folder"], rec["birth_timestamp"])
        if key not in history_keys:
            existing_history.append(rec)
            
    with open(telemetry_summary_path, "w") as hf:
        json.dump(existing_history, hf, indent=2)
        
    print("\n==========================================================================================")
    print(f"                        GLOBAL COMPILATION TELEMETRY COMPARISON MATRIX")
    print("==========================================================================================")
    print(f" {'TARGET PROFILE':25} | {'LAUNCH TIMESTAMP':19} | {'COMPLETED TIMESTAMP':19} | {'DURATION':10}")
    print("------------------------------------------------------------------------------------------")
    for rec in sorted(new_records, key=lambda x: x['birth_timestamp']):
        prof_str = f"{rec['target']} ({rec['profile']})"
        print(f" {prof_str:25} | {rec['birth_timestamp']:19} | {rec['death_timestamp']:19} | {rec['elapsed_duration']:10}")
    print("==========================================================================================\n")
    return True

if __name__ == "__main__":
    scan_and_extract_telemetry()
