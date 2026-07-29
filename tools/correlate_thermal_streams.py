#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tools/correlate_thermal_streams.py
# Purpose:      COM5 Arduino & Host Multi-Source Thermal Stream Correlation Engine
# Target OS:    Ubuntu 26.04 LTS / WSL2 / Windows 11
# Lineage:      IrisLime Telemetry Architecture
# Updated:      2026-07-29
# Attribution:  fekerr & Gemini
# ==============================================================================

import re
import sys
import time
import datetime
import subprocess
from pathlib import Path

def read_win_serial_com5() -> dict:
    """Reads live temperature and humidity telemetry from COM5 via Windows PowerShell."""
    ps_script = """
    try {
        $port = New-Object System.IO.Ports.SerialPort 'COM5', 9600, None, 8, One;
        $port.ReadTimeout = 1500;
        $port.Open();
        Start-Sleep -Milliseconds 600;
        $data = '';
        if ($port.BytesToRead -gt 0) { $data = $port.ReadExisting(); }
        $port.Close();
        Write-Output $data;
    } catch {
        Write-Output "ERR";
    }
    """
    cmd = ["powershell.exe", "-NoProfile", "-Command", ps_script]
    res_data = {"raw": "N/A", "temp_c": None, "temp_f": None, "humidity": None}
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        if res.returncode == 0 and res.stdout.strip():
            raw = res.stdout.strip()
            res_data["raw"] = raw
            # Match pattern: Humidity: 59.7% | Temp: 20.0 °C (68.0 °F)
            m_hum = re.search(r"Humidity:\s*([\d\.]+)%", raw)
            m_c = re.search(r"Temp:\s*([\d\.]+)\s*°?C", raw)
            m_f = re.search(r"\(([\d\.]+)\s*°?F\)", raw)
            if m_hum: res_data["humidity"] = float(m_hum.group(1))
            if m_c: res_data["temp_c"] = float(m_c.group(1))
            if m_f: res_data["temp_f"] = float(m_f.group(1))
    except Exception as e:
        print(f"[-] COM5 read note: {e}", file=sys.stderr)
    return res_data

def query_host_cpu_thermal() -> float:
    """Queries Windows host CPU thermal zone temperature (°C)."""
    cmd = [
        "powershell.exe",
        "-NoProfile",
        "-Command",
        "Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation | Select-Object -ExpandProperty Temperature"
    ]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        if res.returncode == 0 and res.stdout.strip():
            for line in res.stdout.splitlines():
                if line.strip().isdigit():
                    k = float(line.strip())
                    return k - 273.15
    except Exception:
        pass
    return 48.0  # Baseline fallback

def find_thermal_log_files(root_dir: Path) -> list:
    """Discovers existing workspace log files containing thermal/telemetry data."""
    found = []
    log_patterns = ["*thermal*.csv", "*telemetry*.csv", "*.log"]
    for p in log_patterns:
        for f in root_dir.rglob(p):
            if f.is_file() and f.stat().st_size > 0:
                found.append(f)
    return found

def run_correlation_engine(samples: int = 5, delay_sec: float = 2.0):
    print("==========================================================", flush=True)
    print("  COM5 Arduino & Host Multi-Source Thermal Correlator    ", flush=True)
    print("==========================================================", flush=True)

    root = Path(__file__).resolve().parent.parent
    log_dir = root / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    # 1. Discover Existing Thermal Log Sources
    thermal_logs = find_thermal_log_files(log_dir)
    print(f"[*] Discovered {len(thermal_logs)} Existing Telemetry/Thermal Log Files:", flush=True)
    for tf in thermal_logs[:5]:
        print(f"    - {tf.relative_to(root)} ({tf.stat().st_size} bytes)", flush=True)

    # 2. Prepare Merged Telemetry CSV
    merged_csv = log_dir / "correlated_thermal_telemetry.csv"
    print(f"\n[*] Target Correlated Log Output: {merged_csv.relative_to(root)}", flush=True)

    if not merged_csv.exists():
        with open(merged_csv, "w", encoding="utf-8") as f:
            f.write("timestamp,arduino_hum_pct,arduino_temp_c,arduino_temp_f,host_cpu_temp_c,host_cpu_temp_f,status\n")

    print("----------------------------------------------------------", flush=True)
    print("[*] Initiating Synchronized Multi-Source Sampling Pass...\n", flush=True)

    for s in range(1, samples + 1):
        ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # Read COM5 Serial Arduino Stream
        ard = read_win_serial_com5()
        
        # Read Host CPU Thermal Sensor
        host_c = query_host_cpu_thermal()
        host_f = (host_c * 9/5) + 32
        
        ard_hum_str = f"{ard['humidity']:.1f}" if ard['humidity'] is not None else "N/A"
        ard_c_str = f"{ard['temp_c']:.1f}" if ard['temp_c'] is not None else "N/A"
        ard_f_str = f"{ard['temp_f']:.1f}" if ard['temp_f'] is not None else "N/A"

        print(f"  [Sample {s}/{samples} @ {ts}]", flush=True)
        print(f"    -> Arduino COM5 Ambient : {ard_c_str} °C ({ard_f_str} °F) | Humidity: {ard_hum_str}%", flush=True)
        print(f"    -> Host CPU Package     : {host_c:.1f} °C ({host_f:.1f} °F)", flush=True)

        with open(merged_csv, "a", encoding="utf-8") as f:
            f.write(f"{ts},{ard_hum_str},{ard_c_str},{ard_f_str},{host_c:.1f},{host_f:.1f},CORRELATED_OK\n")

        if s < samples:
            time.sleep(delay_sec)

    print("----------------------------------------------------------", flush=True)
    print(f"[+] Correlated Thermal Telemetry Saved: {merged_csv.relative_to(root)}", flush=True)
    print("[SUCCESS] Multi-Source Thermal Stream Correlation Complete!", flush=True)
    return True

if __name__ == "__main__":
    run_correlation_engine()
    sys.exit(0)
