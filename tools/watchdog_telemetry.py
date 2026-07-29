#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tools/watchdog_telemetry.py
# Purpose:      Resource-Aware Process Counter Watchdog & Telemetry Daemon (Task 160)
# Target OS:    Ubuntu 26.04 LTS / WSL2 / Windows 11
# Lineage:      IrisLime Infrastructure (Task 160)
# Updated:      2026-07-29
# Attribution:  fekerr & Gemini
# ==============================================================================

import os
import sys
import time
import datetime
import subprocess
from pathlib import Path

def get_system_load():
    """Reads Linux /proc/stat CPU load and /proc/meminfo memory usage."""
    cpu_user, cpu_system, cpu_idle = 0, 0, 0
    try:
        with open("/proc/stat", "r") as f:
            line = f.readline()
            if line.startswith("cpu"):
                parts = [int(x) for x in line.split()[1:8]]
                cpu_user = parts[0] + parts[1]
                cpu_system = parts[2]
                cpu_idle = parts[3]
    except Exception:
        pass

    ram_total_mb, ram_free_mb = 0, 0
    try:
        with open("/proc/meminfo", "r") as f:
            lines = f.readlines()
            for l in lines:
                if l.startswith("MemTotal:"):
                    ram_total_mb = int(l.split()[1]) // 1024
                elif l.startswith("MemAvailable:"):
                    ram_free_mb = int(l.split()[1]) // 1024
    except Exception:
        pass

    return cpu_user, cpu_system, cpu_idle, ram_total_mb, ram_free_mb

def count_active_build_processes():
    """Scans process list for active build/compiler/llama binaries."""
    active_count = 0
    proc_names = ["llama", "llama-bench", "llama-cli", "cl", "gmake", "cmake", "icx"]
    try:
        res = subprocess.run(["ps", "-ax"], capture_output=True, text=True)
        if res.returncode == 0:
            for line in res.stdout.splitlines():
                if any(p in line for p in proc_names) and "watchdog" not in line:
                    active_count += 1
    except Exception:
        pass
    return active_count

def sample_watchdog():
    root = Path(__file__).resolve().parent.parent
    log_dir = root / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    csv_file = log_dir / "watchdog_telemetry.csv"

    if not csv_file.exists():
        with open(csv_file, "w", encoding="utf-8") as f:
            f.write("timestamp,ram_total_mb,ram_free_mb,active_build_procs,status\n")

    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    _, _, _, ram_total, ram_free = get_system_load()
    procs = count_active_build_processes()

    status = "RUNNING_BUILD" if procs > 0 else "IDLE"
    log_line = f"{timestamp},{ram_total},{ram_free},{procs},{status}\n"

    with open(csv_file, "a", encoding="utf-8") as f:
        f.write(log_line)

    print("==========================================================")
    print("  Resource-Aware Watchdog Monitor & Telemetry (Task 160)  ")
    print("==========================================================")
    print(f"Timestamp          : {timestamp}")
    print(f"RAM Footprint      : {ram_free} MB available / {ram_total} MB total")
    print(f"Active Build Procs : {procs}")
    print(f"Watchdog Status    : {status}")
    print(f"[+] Telemetry logged to: {csv_file}")
    print("==========================================================")
    return True

if __name__ == "__main__":
    sample_watchdog()
    sys.exit(0)
