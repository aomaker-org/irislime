#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tools/correlate_thermal_streams.py
# Purpose:      Multi-Threaded Dual-OS Thermal Correlator & Live ASCII Grapher
# Target OS:    Ubuntu 26.04 LTS / WSL2 / Windows 11
# Lineage:      IrisLime Telemetry Architecture
# Updated:      2026-07-29
# Attribution:  fekerr & Gemini
# ==============================================================================

import re
import sys
import time
import argparse
import datetime
import threading
import subprocess
from pathlib import Path

# Safety Limits
MIN_POLL_INTERVAL_SEC = 5.0
DEFAULT_POLL_INTERVAL_SEC = 60.0

class DualOSSensorCorrelator:
    def __init__(self, interval: float, enable_graph: bool):
        self.interval = max(interval, MIN_POLL_INTERVAL_SEC)
        self.enable_graph = enable_graph
        self.running = True
        
        # Shared Telemetry State
        self.lock = threading.Lock()
        self.wsl_data = {"cpu_pct": 0.0, "ram_avail_mb": 0}
        self.win_data = {"host_temp_c": 48.0, "arduino_temp_c": None, "arduino_temp_f": None, "arduino_hum": None}
        self.arduino_samples = []
        
        root = Path(__file__).resolve().parent.parent
        self.log_dir = root / "logs"
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.csv_file = self.log_dir / "correlated_thermal_telemetry.csv"
        self._init_csv()

    def _init_csv(self):
        if not self.csv_file.exists():
            with open(self.csv_file, "w", encoding="utf-8") as f:
                f.write("timestamp,arduino_hum_pct,arduino_temp_c,arduino_temp_f,host_cpu_temp_c,host_cpu_temp_f,wsl_cpu_pct,wsl_ram_avail_mb,status\n")

    def thread_wsl_sensors(self):
        """Thread 1: Samples Linux /proc/stat CPU load & /proc/meminfo RAM in WSL subsystem."""
        last_total, last_idle = 0, 0
        while self.running:
            try:
                # Sample RAM
                ram_avail = 0
                with open("/proc/meminfo", "r") as f:
                    for line in f:
                        if line.startswith("MemAvailable:"):
                            ram_avail = int(line.split()[1]) // 1024
                            break
                
                # Sample CPU utilization from /proc/stat
                with open("/proc/stat", "r") as f:
                    fields = f.readline().split()[1:]
                    vals = [int(v) for v in fields]
                    idle = vals[3] + vals[4]
                    total = sum(vals)
                    diff_idle = idle - last_idle
                    diff_total = total - last_total
                    cpu_pct = 100.0 * (1.0 - (diff_idle / max(diff_total, 1)))
                    last_idle, last_total = idle, total

                with self.lock:
                    self.wsl_data["cpu_pct"] = round(cpu_pct, 1)
                    self.wsl_data["ram_avail_mb"] = ram_avail

            except Exception:
                pass
            time.sleep(2.0)

    def thread_win_sensors(self):
        """Thread 2: Samples Windows 11 host thermal zones & COM5 serial stream via pwsh.exe."""
        ps_script = """
        $res = [PSCustomObject]@{ HostC = 48.0; SerialData = '' };
        try {
            $tz = Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation | Select-Object -First 1 -ExpandProperty Temperature;
            if ($tz) { $res.HostC = [math]::Round($tz - 273.15, 1); }
        } catch {}
        try {
            $port = New-Object System.IO.Ports.SerialPort 'COM5', 9600, None, 8, One;
            $port.ReadTimeout = 1000;
            $port.Open();
            Start-Sleep -Milliseconds 400;
            if ($port.BytesToRead -gt 0) { $res.SerialData = $port.ReadExisting(); }
            $port.Close();
        } catch {}
        $res | ConvertTo-Json -Compress
        """
        cmd = ["powershell.exe", "-NoProfile", "-Command", ps_script]
        
        while self.running:
            try:
                res = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
                if res.returncode == 0 and res.stdout.strip():
                    import json
                    parsed = json.loads(res.stdout.strip())
                    host_c = float(parsed.get("HostC", 48.0))
                    raw_ser = parsed.get("SerialData", "")

                    with self.lock:
                        self.win_data["host_temp_c"] = host_c

                    if raw_ser:
                        m_hum = re.search(r"Humidity:\s*([\d\.]+)%", raw_ser)
                        m_c = re.search(r"Temp:\s*([\d\.]+)\s*°?C", raw_ser)
                        m_f = re.search(r"\(([\d\.]+)\s*°?F\)", raw_ser)
                        if m_hum and m_c:
                            sample = (float(m_c.group(1)), float(m_f.group(1)) if m_f else (float(m_c.group(1))*1.8+32), float(m_hum.group(1)))
                            with self.lock:
                                self.arduino_samples.append(sample)
            except Exception:
                pass
            time.sleep(3.0)

    def render_ascii_graph(self, host_c: float, ard_c: float):
        """Renders real-time ASCII bar sparklines for CPU vs Arduino thermals."""
        def make_bar(val_c, max_c=100.0, length=25):
            filled = int(max(0, min(length, (val_c / max_c) * length)))
            return "█" * filled + "░" * (length - filled)

        ard_str = f"{ard_c:.1f}°C" if ard_c is not None else "N/A"
        ard_val = ard_c if ard_c is not None else 0.0
        
        print("\n" + "─" * 60, flush=True)
        print("  REAL-TIME THERMAL TELEMETRY GRAPH", flush=True)
        print("─" * 60, flush=True)
        print(f"  Host CPU Temp  : [{make_bar(host_c)}] {host_c:.1f}°C", flush=True)
        print(f"  Arduino Ambient: [{make_bar(ard_val)}] {ard_str}", flush=True)
        print("─" * 60, flush=True)

    def run_loop(self):
        print("==========================================================", flush=True)
        print("   Dual-OS Sensor Correlator & Thermal Telemetry Loop    ", flush=True)
        print("==========================================================", flush=True)
        print(f"[*] Polling Interval  : {self.interval:.1f} seconds (Safety Floor: {MIN_POLL_INTERVAL_SEC}s)", flush=True)
        print(f"[*] Live Graphing     : {'ENABLED' if self.enable_graph else 'DISABLED'}", flush=True)
        print(f"[*] Target CSV Ledger : {self.csv_file.name}", flush=True)
        print("----------------------------------------------------------", flush=True)

        t_wsl = threading.Thread(target=self.thread_wsl_sensors, daemon=True)
        t_win = threading.Thread(target=self.thread_win_sensors, daemon=True)
        t_wsl.start()
        t_win.start()

        loop_count = 0
        try:
            while self.running:
                time.sleep(self.interval)
                loop_count += 1
                ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

                with self.lock:
                    wsl_cpu = self.wsl_data["cpu_pct"]
                    wsl_ram = self.wsl_data["ram_avail_mb"]
                    host_c = self.win_data["host_temp_c"]
                    host_f = (host_c * 9/5) + 32
                    
                    # Compute Arduino Averages over the polling window
                    if self.arduino_samples:
                        avg_c = sum(s[0] for s in self.arduino_samples) / len(self.arduino_samples)
                        avg_f = sum(s[1] for s in self.arduino_samples) / len(self.arduino_samples)
                        avg_h = sum(s[2] for s in self.arduino_samples) / len(self.arduino_samples)
                        self.arduino_samples.clear()
                    else:
                        avg_c, avg_f, avg_h = None, None, None

                ard_c_str = f"{avg_c:.1f}" if avg_c is not None else "N/A"
                ard_f_str = f"{avg_f:.1f}" if avg_f is not None else "N/A"
                ard_h_str = f"{avg_h:.1f}" if avg_h is not None else "N/A"

                print(f"[{ts} | Loop #{loop_count}]", flush=True)
                print(f"  -> Host CPU Temp     : {host_c:.1f} °C ({host_f:.1f} °F)", flush=True)
                print(f"  -> Arduino Ambient   : {ard_c_str} °C ({ard_f_str} °F) | Humidity: {ard_h_str}%", flush=True)
                print(f"  -> WSL Subsystem Load: {wsl_cpu}% CPU | {wsl_ram} MB RAM Available", flush=True)

                # Write Correlated Log Entry
                with open(self.csv_file, "a", encoding="utf-8") as f:
                    f.write(f"{ts},{ard_h_str},{ard_c_str},{ard_f_str},{host_c:.1f},{host_f:.1f},{wsl_cpu:.1f},{wsl_ram},LOOP_OK\n")

                if self.enable_graph:
                    self.render_ascii_graph(host_c, avg_c)

        except KeyboardInterrupt:
            print("\n[*] Stopping dual-OS sensor correlator loop cleanly...", flush=True)
            self.running = False

def main():
    parser = argparse.ArgumentParser(
        description="Multi-Threaded Dual-OS Thermal Correlator & Live ASCII Grapher (IrisLime Infrastructure)",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument(
        "-i", "--interval",
        type=float,
        default=DEFAULT_POLL_INTERVAL_SEC,
        help="Polling loop interval in seconds (default: 60.0s, minimum safety floor: 5.0s)."
    )
    parser.add_argument(
        "-g", "--graph",
        action="store_true",
        help="Enable live real-time ASCII bar graph rendering in terminal output."
    )
    
    args = parser.parse_args()
    
    if args.interval < MIN_POLL_INTERVAL_SEC:
        print(f"[!] Warning: Requested interval {args.interval}s is below safety floor ({MIN_POLL_INTERVAL_SEC}s). Clamping to {MIN_POLL_INTERVAL_SEC}s.", file=sys.stderr)

    correlator = DualOSSensorCorrelator(interval=args.interval, enable_graph=args.graph)
    correlator.run_loop()

if __name__ == "__main__":
    main()
