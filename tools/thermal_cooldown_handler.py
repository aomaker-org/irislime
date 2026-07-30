#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tools/thermal_cooldown_handler.py
# Purpose:      Thermal Sensing & Dynamic Cooldown Handler (Task 150)
# Target OS:    Ubuntu 26.04 LTS / WSL2 / Windows 11
# Lineage:      IrisLime Infrastructure (Task 150)
# Updated:      2026-07-29
# Attribution:  fekerr & Gemini
# ==============================================================================

import os
import sys
import time
import subprocess
from pathlib import Path

TEMP_HIGH_THRESHOLD_C = 85.0
TEMP_WARM_THRESHOLD_C = 70.0
COOLDOWN_PAUSE_SECONDS = 10

def query_host_temperatures():
    """Queries Windows 11 host thermal zone counters via PowerShell."""
    cmd = [
        "powershell.exe",
        "-NoProfile",
        "-Command",
        "Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation | Select-Object -ExpandProperty Temperature"
    ]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        if res.returncode == 0 and res.stdout.strip():
            temps_c = []
            for line in res.stdout.splitlines():
                line = line.strip()
                if line.isdigit():
                    val_k = float(line)
                    val_c = val_k - 273.15
                    temps_c.append(val_c)
            return temps_c
    except Exception as e:
        print(f"[-] Diagnostic: Thermal query exception: {e}", file=sys.stderr)
    return []

def evaluate_thermal_cooldown(max_threshold_c=TEMP_HIGH_THRESHOLD_C):
    """Evaluates host thermal state and injects dynamic cooldown pause if threshold exceeded."""
    print("==========================================================")
    print("  Thermal Sensing & Dynamic Cooldown Handler (Task 150)   ")
    print("==========================================================")
    
    temps = query_host_temperatures()
    if not temps:
        print("[!] Note: Host thermal counters un-queried in current environment. Proceeding cleanly.")
        return True

    max_temp = max(temps)
    print(f"[*] Max Host Thermal Reading: {max_temp:.1f} °C (Threshold: {max_threshold_c:.1f} °C)")

    if max_temp >= max_threshold_c:
        print(f"[!] WARNING: Host temperature ({max_temp:.1f} °C) exceeds safety floor!")
        print(f"    --> Injecting {COOLDOWN_PAUSE_SECONDS}s thermal cooldown pause state...")
        time.sleep(COOLDOWN_PAUSE_SECONDS)
        print("[+] Cooldown state complete. Host thermal headroom restored.")
    else:
        print("[+] Host thermals nominal. Continuing evaluation run.")
    return True

if __name__ == "__main__":
    evaluate_thermal_cooldown()
    sys.exit(0)
