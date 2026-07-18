#!/usr/bin/env python3
# ==============================================================================
# IrisLime Engineering Subsystem Utility
# Filename:    tools/track_profile.py
# Purpose:     Tree-aware process resource telemetry harvester (Aggregated)
# Type:        Python 3 Execution Script (Run via uv run or python3)
# Context:     Requires active process tracking privileges under Linux (/proc)
# Attribution: fekerr & Gemini (20260706_0550 / Tree Traversal Calibration)
# Timestamp:   20260706_0550
# ==============================================================================

import os
import sys
import time
import csv
import argparse

def parse_arguments():
    parser = argparse.ArgumentParser(
        description="High-precision tree-aggregating telemetry tracker."
    )
    parser.add_argument("--pid", type=int, required=True, help="Root Parent PID to trace.")
    parser.add_argument("--out", type=str, default="logs/resource_telemetry.csv", help="Output path.")
    parser.add_argument("--interval", type=float, default=1.0, help="Polling interval.")
    return parser.parse_args()

def get_system_clktck():
    try:
        return os.sysconf(os.sysconf_names['SC_CLK_TCK'])
    except (AttributeError, ValueError, KeyError):
        return 100.0

def get_system_pagesize():
    try:
        return os.sysconf(os.sysconf_names['SC_PAGESIZE'])
    except (AttributeError, ValueError, KeyError):
        return 4096

def aggregate_process_tree(root_pid):
    """
    Scans /proc in a single optimized pass, maps parent-child processes,
    and sums memory and CPU tick metrics for the root and all descendants.
    """
    ppid_map = {}
    process_metrics = {}
    
    try:
        for pid_dir in os.listdir("/proc"):
            if not pid_dir.isdigit():
                continue
            pid = int(pid_dir)
            try:
                with open(f"/proc/{pid}/stat", "r") as f:
                    stat_raw = f.read()
                with open(f"/proc/{pid}/statm", "r") as f:
                    statm_raw = f.read().split()
                
                # Safely split strings around process names that contain spaces or parentheses
                rpar_idx = stat_raw.rfind(')')
                after_comm = stat_raw[rpar_idx+2:].split()
                
                ppid = int(after_comm[1])
                utime = int(after_comm[11])
                stime = int(after_comm[12])
                
                virt_pages = int(statm_raw[0])
                rss_pages = int(statm_raw[1])
                
                ppid_map[pid] = ppid
                process_metrics[pid] = {
                    'ticks': utime + stime,
                    'virt_pages': virt_pages,
                    'rss_pages': rss_pages
                }
            except (FileNotFoundError, ProcessLookupError, IndexError, ValueError):
                continue
    except OSError:
        return None

    # Reconstruct the process tree downwards from our root parent PID
    descendants = set()
    to_check = [root_pid]
    while to_check:
        current = to_check.pop()
        for child_pid, ppid in ppid_map.items():
            if ppid == current and child_pid not in descendants:
                descendants.add(child_pid)
                to_check.append(child_pid)
                
    all_pids = descendants | {root_pid}
    
    total_ticks = 0
    total_virt = 0
    total_rss = 0
    any_alive = False
    
    for pid in all_pids:
        if pid in process_metrics:
            any_alive = True
            total_ticks += process_metrics[pid]['ticks']
            total_virt += process_metrics[pid]['virt_pages']
            total_rss += process_metrics[pid]['rss_pages']
            
    if not any_alive:
        return None
        
    return total_ticks, total_virt, total_rss

def monitor_process(root_pid, output_path, interval):
    out_dir = os.path.dirname(output_path)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)
        
    clk_tck = get_system_clktck()
    page_size = get_system_pagesize()
    
    print(f"==> [TELEMETRY] Tracking tree metrics rooted at PID {root_pid}...")
    
    file_exists = os.path.exists(output_path)
    with open(output_path, "a", newline="", buffering=1) as csv_file:
        writer = csv.writer(csv_file)
        if not file_exists or os.path.getsize(output_path) == 0:
            writer.writerow(["Timestamp", "Elapsed_Sec", "RSS_MB", "VIRT_MB", "Delta_CPU_Pct"])
            
        start_time = time.time()
        prev_tree_ticks = None
        prev_time = None
        
        try:
            while True:
                current_time = time.time()
                tree_data = aggregate_process_tree(root_pid)
                
                if tree_data is None:
                    print(f"==> [TELEMETRY] Complete process tree for root {root_pid} terminated.")
                    break
                
                total_ticks, virt_pages, rss_pages = tree_data
                
                rss_mb = (rss_pages * page_size) / (1024 * 1024)
                virt_mb = (virt_pages * page_size) / (1024 * 1024)
                
                cpu_pct = 0.0
                if prev_tree_ticks is not None and prev_time is not None:
                    delta_ticks = total_ticks - prev_tree_ticks
                    delta_time = current_time - prev_time
                    if delta_time > 0:
                        cpu_pct = (delta_ticks / clk_tck) / delta_time * 100.0
                
                elapsed_sec = round(current_time - start_time, 2)
                timestamp = time.strftime("%Y%m%d_%H%M%S")
                
                writer.writerow([
                    timestamp, 
                    elapsed_sec, 
                    round(rss_mb, 2), 
                    round(virt_mb, 2), 
                    round(cpu_pct, 1)
                ])
                
                prev_tree_ticks = total_ticks
                prev_time = current_time
                
                time.sleep(interval)
                
        except KeyboardInterrupt:
            print("\n==> [TELEMETRY] Interrupted by user.")
        except Exception as e:
            print(f"\n[!] Telemetry Error: {str(e)}", file=sys.stderr)

if __name__ == "__main__":
    args = parse_arguments()
    monitor_process(args.pid, args.out, args.interval)
