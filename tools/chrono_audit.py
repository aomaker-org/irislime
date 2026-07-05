#!/usr/bin/env python3
# ==============================================================================
# Filename:     tools/chrono_audit.py
# Purpose:      Forensic Timeline Reconstruction & Engineering Time Auditor
# Type:         Analytical Utility Script
# Attribution:  fekerr & Gemini (July 4, 2026)
# ==============================================================================

import subprocess
import re
import os
import glob
from datetime import datetime

def extract_reflog_timestamps():
    """Extracts raw ISO timestamps from the local Git Reflog matrix."""
    timestamps = []
    try:
        # Pull every state change event with strict ISO 8601 formatting
        cmd = ["git", "reflog", "--date=iso"]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        # Parse standard ISO strings: 2026-07-04 16:30:07 -0700
        pattern = r'\{(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+-]\d{4})\}'
        for line in result.stdout.splitlines():
            match = re.search(pattern, line)
            if match:
                dt = datetime.strptime(match.group(1)[:-6], "%Y-%m-%d %H:%M:%S")
                timestamps.append(dt)
    except Exception as e:
        print(f"[-] Warning: Failed to fully traverse git reflog: {e}")
    return timestamps

def extract_filename_timestamps():
    """Scrapes explicit timestamp metadata tokens straight from loose file paths."""
    timestamps = []
    # Scan project root and scratch directories for your explicit timestamp loops
    search_paths = ["scratch/*", "*.*", "logs/builds/*/*.log"]
    
    # Matches patterns like 20260627_1027 or build_20260704_164402
    pattern = r'(\d{8})_(\d{6})'
    
    for path_glob in search_paths:
        for filepath in glob.glob(path_glob):
            filename = os.path.basename(filepath)
            match = re.search(pattern, filename)
            if match:
                try:
                    dt = datetime.strptime(f"{match.group(1)}_{match.group(2)}", "%Y%m%d_%H%M%S")
                    timestamps.append(dt)
                except ValueError:
                    continue
    return timestamps

def calculate_engineering_metrics(timestamps, session_gap_minutes=60, active_padding_minutes=30):
    """
    Groups discrete timestamp markers into continuous session bursts 
    to reconstruct estimated real-world active engineering spans.
    """
    if not timestamps:
        return 0, []
        
    # Sort timeline monotonically from past to present
    ordered_timeline = sorted(list(set(timestamps)))
    
    sessions = []
    session_start = ordered_timeline[0]
    last_event = ordered_timeline[0]
    
    for event in ordered_timeline[1:]:
        delta = (event - last_event).total_seconds() / 60.0
        
        if delta > session_gap_minutes:
            # Boundary broken: Close out the current active session canvas
            duration = (last_event - session_start).total_seconds() / 60.0
            # Apply standard padding for the initial startup and cognitive ramp-up
            duration += active_padding_minutes
            sessions.append((session_start, last_event, duration))
            
            # Open a fresh session tracking slot
            session_start = event
        
        last_event = event
        
    # Flush the final trailing execution slice remaining in the loop
    final_duration = (last_event - session_start).total_seconds() / 60.0 + active_padding_minutes
    sessions.append((session_start, last_event, final_duration))
    
    total_hours = sum(s[2] for s in sessions) / 60.0
    return total_hours, sessions

if __name__ == "__main__":
    print("==================================================================")
    print(" IrisLime Forensic Repository Chrono-Audit System")
    print("==================================================================")
    
    print("[*] Traversing local Git cryptographic reflog layers...")
    reflog_times = extract_reflog_timestamps()
    
    print("[*] Scraping chronological filename metadata patterns...")
    filename_times = extract_filename_timestamps()
    
    combined_timeline = reflog_times + filename_times
    print(f"[+] Total Forensic Time Tokens Recovered: {len(combined_timeline)}")
    
    total_hours, session_manifest = calculate_engineering_metrics(combined_timeline)
    
    print("\nReconstructed Active Engineering Sessions Summary:")
    print("------------------------------------------------------------------")
    for idx, (start, end, duration) in enumerate(session_manifest, start=1):
        print(f"  Session {idx:02d}: {start.strftime('%Y-%m-%d %H:%M')} -> {end.strftime('%H:%M')} | Estimated Span: {duration/60.0:.2f} Hours")
        
    print("==================================================================")
    print(f" TOTAL ESTIMATED ACTIVE DEVELOPMENT FOOTPRINT: {total_hours:.2f} Hours")
    print("==================================================================")
