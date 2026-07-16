#!/usr/bin/env python3
# ==============================================================================
# Path:        aggressive_telemetry_builder/builder.py
# Purpose:     A dependency-free WSL2/Linux-optimized build orchestrator featuring
#              dynamic resource throttling and high-precision telemetry logging.
# Attribution: Antigravity & fekerr
# ==============================================================================

import os
import sys
import json
import time
import subprocess
import threading
import csv
from pathlib import Path
import glob

# Constants
WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = WORKSPACE_ROOT / "matrix_control.json"
LOG_DIR = WORKSPACE_ROOT / "logs"
TELEMETRY_CSV = LOG_DIR / "aggressive_telemetry.csv"
REPORT_MD = LOG_DIR / "aggressive_telemetry_report.md"

# Global states
tracking_active = False
telemetry_data = []

# ==============================================================================
# Low-Cost / Zero-Dependency Linux Sensor Harvesters
# ==============================================================================

def get_cpu_ticks():
    """Reads /proc/stat to fetch raw cpu ticks for idle and total calculations."""
    try:
        with open("/proc/stat", "r") as f:
            for line in f:
                if line.startswith("cpu "):
                    parts = [float(x) for x in line.split()[1:]]
                    idle = parts[3] + parts[4]  # idle + iowait
                    total = sum(parts)
                    return idle, total
    except Exception:
        return 0.0, 0.0

def get_cpu_utilization(sample_duration=0.5):
    """Measures CPU usage percentage over a short sample window (very cheap in WSL)."""
    idle1, total1 = get_cpu_ticks()
    time.sleep(sample_duration)
    idle2, total2 = get_cpu_ticks()
    
    delta_total = total2 - total1
    delta_idle = idle2 - idle1
    if delta_total > 0:
        return (1.0 - (delta_idle / delta_total)) * 100.0
    return 0.0

def get_memory_info():
    """Parses /proc/meminfo to retrieve RAM and Swap space metrics."""
    meminfo = {}
    try:
        with open("/proc/meminfo", "r") as f:
            for line in f:
                parts = line.split()
                if len(parts) >= 2:
                    key = parts[0].strip(":")
                    val = float(parts[1]) / 1024.0  # Convert KB to MB
                    meminfo[key] = val
    except Exception:
        pass
    
    mem_total = meminfo.get("MemTotal", 0.0)
    mem_free = meminfo.get("MemFree", 0.0)
    mem_avail = meminfo.get("MemAvailable", mem_free)
    mem_used = mem_total - mem_avail
    
    swap_total = meminfo.get("SwapTotal", 0.0)
    swap_free = meminfo.get("SwapFree", 0.0)
    swap_used = swap_total - swap_free
    
    return {
        "mem_total_mb": mem_total,
        "mem_used_mb": mem_used,
        "mem_free_mb": mem_free,
        "swap_total_mb": swap_total,
        "swap_used_mb": swap_used,
        "swap_free_mb": swap_free
    }

def get_cpu_temp():
    """Queries virtual sysfs nodes to extract CPU core temperatures."""
    thermal_patterns = [
        "/sys/class/thermal/thermal_zone*/temp",
        "/sys/class/hwmon/hwmon*/temp*_input"
    ]
    for pattern in thermal_patterns:
        for path in glob.glob(pattern):
            try:
                with open(path, "r") as f:
                    val = float(f.read().strip())
                    if val > 1000:
                        val /= 1000.0  # Convert millidegrees C
                    if 0 < val < 150:
                        return val
            except Exception:
                continue
    return None

def get_disk_stats():
    """Reads /proc/diskstats to count completed IO operations."""
    try:
        with open("/proc/diskstats", "r") as f:
            reads, writes = 0, 0
            for line in f:
                parts = line.split()
                if len(parts) >= 14:
                    reads += int(parts[5])
                    writes += int(parts[9])
            return reads, writes
    except Exception:
        return 0, 0

# ==============================================================================
# Telemetry Collector Thread
# ==============================================================================

def telemetry_collector_loop(interval=1.0):
    global tracking_active, telemetry_data
    
    # Pre-populate CSV header
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    file_exists = TELEMETRY_CSV.exists()
    
    with open(TELEMETRY_CSV, "a", newline="", buffering=1) as f:
        writer = csv.writer(f)
        if not file_exists or os.path.getsize(TELEMETRY_CSV) == 0:
            writer.writerow([
                "Timestamp", "CPU_Pct", "RAM_Used_MB", "RAM_Free_MB", 
                "Swap_Used_MB", "Swap_Free_MB", "CPU_Temp_C", "Disk_Reads", "Disk_Writes"
            ])
            
        while tracking_active:
            # Measure CPU %
            cpu_pct = get_cpu_utilization(sample_duration=0.2)
            mem = get_memory_info()
            temp = get_cpu_temp()
            temp_str = f"{temp:.1f}" if temp is not None else "N/A"
            reads, writes = get_disk_stats()
            
            timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
            row = [
                timestamp, round(cpu_pct, 1), round(mem["mem_used_mb"], 2), round(mem["mem_free_mb"], 2),
                round(mem["swap_used_mb"], 2), round(mem["swap_free_mb"], 2), temp_str, reads, writes
            ]
            
            writer.writerow(row)
            telemetry_data.append(row)
            time.sleep(interval)

# ==============================================================================
# Build Engine Orchestrator
# ==============================================================================

def load_matrix_control():
    if not CONFIG_PATH.exists():
        print(f"[!] Error: Configuration file not found at {CONFIG_PATH}")
        sys.exit(1)
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)

def run_build_command(command, backend, profile):
    print(f"\n[Build Exec] Starting: {' '.join(command)}")
    print(f"             Backend:  {backend.upper()} | Profile: {profile}")
    
    start_time = time.time()
    try:
        process = subprocess.Popen(
            command,
            cwd=str(WORKSPACE_ROOT),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )
        
        # Stream compilation output to terminal stdout
        if process.stdout:
            for line in process.stdout:
                sys.stdout.write(f"  [CC] > {line}")
                sys.stdout.flush()
                
        return_code = process.wait()
        duration = time.time() - start_time
        return return_code == 0, duration
    except Exception as e:
        print(f"[!] Compilation process crashed: {e}")
        return False, 0.0

def traverse_build_matrix():
    global tracking_active
    
    config = load_matrix_control()
    overrides = config.get("backend_overrides", {})
    
    enabled_targets = []
    for backend, properties in overrides.items():
        if properties.get("enabled", False):
            enabled_targets.append((backend, properties))
            
    if not enabled_targets:
        print("[!] Notice: No targets are enabled under backend_overrides in matrix_control.json.")
        sys.exit(0)
        
    print(f"[+] Loaded {len(enabled_targets)} enabled acceleration backends.")
    print("------------------------------------------------------------------")
    
    # Launch background telemetry collector
    tracking_active = True
    tracker_thread = threading.Thread(target=telemetry_collector_loop, daemon=True)
    tracker_thread.start()
    
    results = []
    throttling_events = []
    
    for backend, properties in enabled_targets:
        profiles = properties.get("ordered_profiles", [])
        
        for p in profiles:
            profile_name = p.get("name")
            
            # --- CPU UTILIZATION THROTTLER GATE ---
            while True:
                current_cpu = get_cpu_utilization(sample_duration=0.5)
                if current_cpu > 50.0:
                    event = {
                        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
                        "backend": backend,
                        "profile": profile_name,
                        "cpu_util": current_cpu
                    }
                    throttling_events.append(event)
                    print(f"\n[⚠️ CPU Throttling Gate Triggered] Current CPU usage is {current_cpu:.1f}% (> 50%).")
                    print("                                Sleeping for 10 seconds to allow cooldown...")
                    time.sleep(10)
                else:
                    break
            
            # Build commands mapping
            if backend == "litert":
                if profile_name.lower() == "debug":
                    cmd = ["make", "litert-debug"]
                else:
                    cmd = ["make", "litert-all"]
            else:
                cmd = ["make", f"build-{backend}", f"PROFILE={profile_name}"]
                
            success, elapsed = run_build_command(cmd, backend, profile_name)
            results.append({
                "backend": backend,
                "profile": profile_name,
                "success": success,
                "elapsed_sec": round(elapsed, 2)
            })
            
    # Stop background tracker
    tracking_active = False
    tracker_thread.join()
    
    generate_markdown_report(results, throttling_events)

# ==============================================================================
# Markdown Report Generation
# ==============================================================================

def generate_markdown_report(results, throttling_events):
    print("\n[+] Compilation Matrix Swept successfully. Generating Telemetry Report...")
    
    # Calculate peak RAM & CPU
    peak_cpu = 0.0
    peak_ram = 0.0
    peak_swap = 0.0
    temps = []
    
    for row in telemetry_data:
        # row layout: [timestamp, cpu, ram_used, ram_free, swap_used, swap_free, temp, reads, writes]
        cpu = float(row[1])
        ram = float(row[2])
        swap = float(row[4])
        temp_val = row[6]
        
        if cpu > peak_cpu:
            peak_cpu = cpu
        if ram > peak_ram:
            peak_ram = ram
        if swap > peak_swap:
            peak_swap = swap
        if temp_val != "N/A":
            temps.append(float(temp_val))
            
    avg_temp = sum(temps) / len(temps) if temps else 0.0
    max_temp = max(temps) if temps else 0.0
    
    report_content = f"""# Aggressive Telemetry Build Runner Report

Generated at: {time.strftime("%Y-%m-%d %H:%M:%S")}

## 1. Build Verification Results Ledger

| Backend | Profile | Elapsed (s) | Status |
|---|---|---|---|
"""
    for r in results:
        status_icon = "✅ SUCCESS" if r["success"] else "❌ FAILED"
        report_content += f"| {r['backend'].upper()} | {r['profile']} | {r['elapsed_sec']}s | {status_icon} |\n"
        
    report_content += f"""
## 2. Resource Telemetry Peak Performance Bounds

* **Peak Global CPU Utilization**: {peak_cpu:.1f}%
* **Peak Memory Allocation**: {peak_ram:.2f} MB
* **Peak Swap space usage**: {peak_swap:.2f} MB
* **Peak Core Thermal Level**: {max_temp:.1f}°C
* **Average Thermal Level**: {avg_temp:.1f}°C

> [!NOTE]
> All sensor queries were harvested dynamically from local filesystem descriptors `/proc` and `/sys` to keep WSL performance penalties negligible.

## 3. CPU Utilization Throttling Log ({len(throttling_events)} Events)

"""
    if not throttling_events:
        report_content += "*No CPU throttling triggers were encountered (utilization remained below 50.0% boundary).* \n"
    else:
        report_content += "| Timestamp | Target Backend | Profile | Measured CPU % | Action |\n"
        report_content += "|---|---|---|---|---|\n"
        for te in throttling_events:
            report_content += f"| {te['timestamp']} | {te['backend'].upper()} | {te['profile']} | {te['cpu_util']:.1f}% | 10s Sleep Throttled |\n"
            
    with open(REPORT_MD, "w") as f:
        f.write(report_content)
        
    print(f"[✅] Telemetry report successfully exported: {REPORT_MD}")

if __name__ == "__main__":
    traverse_build_matrix()
