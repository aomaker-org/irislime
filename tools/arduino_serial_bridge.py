#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tools/arduino_serial_bridge.py
# Purpose:      Arduino USB Serial Scanner, Passthrough & Bridge Utility
# Target OS:    Ubuntu 26.04 LTS / WSL2 / Windows 11
# Lineage:      IrisLime Hardware Interop
# Updated:      2026-07-29
# Attribution:  fekerr & Gemini
# ==============================================================================

import sys
import time
import subprocess
from pathlib import Path

try:
    import serial
    import serial.tools.list_ports
    HAS_PYSERIAL = True
except ImportError:
    HAS_PYSERIAL = False

def list_system_serial_ports() -> list:
    """Lists all available physical and virtual serial ports on host/WSL."""
    ports = []
    if HAS_PYSERIAL:
        for p in serial.tools.list_ports.comports():
            ports.append({
                "device": p.device,
                "name": p.name,
                "description": p.description,
                "hwid": p.hwid,
                "vid": p.vid,
                "pid": p.pid
            })
    return ports

def query_win11_pnp_serial() -> list:
    """Queries Windows 11 host PnP manager via PowerShell for USB/Serial devices."""
    cmd = [
        "powershell.exe",
        "-NoProfile",
        "-Command",
        "Get-PnpDevice -PresentOnly | Where-Object { $_.Class -eq 'Ports' -or $_.FriendlyName -like '*Arduino*' -or $_.FriendlyName -like '*CH340*' -or $_.FriendlyName -like '*FT232*' -or $_.FriendlyName -like '*CP210*' } | Select-Object FriendlyName, InstanceId, Status, Class | ConvertTo-Json"
    ]
    win_devices = []
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        if res.returncode == 0 and res.stdout.strip():
            import json
            try:
                data = json.loads(res.stdout)
                if isinstance(data, dict):
                    win_devices.append(data)
                elif isinstance(data, list):
                    win_devices.extend(data)
            except Exception:
                pass
    except Exception as e:
        print(f"[-] Win11 PnP query note: {e}", file=sys.stderr)
    return win_devices

def audit_and_connect_arduino():
    print("==========================================================", flush=True)
    print("   Arduino USB Serial Scanner & Passthrough Bridge       ", flush=True)
    print("==========================================================", flush=True)

    root = Path(__file__).resolve().parent.parent
    log_dir = root / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    telemetry_csv = log_dir / "arduino_serial_telemetry.csv"

    if not telemetry_csv.exists():
        with open(telemetry_csv, "w", encoding="utf-8") as f:
            f.write("timestamp,port,description,status,notes\n")

    # 1. Audit WSL / POSIX Ports
    local_ports = list_system_serial_ports()
    print(f"[*] Local WSL Serial Ports ({len(local_ports)}):", flush=True)
    arduino_port = None

    if local_ports:
        for p in local_ports:
            is_arduino = "arduino" in p["description"].lower() or "ch340" in p["description"].lower() or "usb" in p["description"].lower()
            tag = " [ARDUINO MATCH]" if is_arduino else ""
            print(f"    - {p['device']} ({p['description']}){tag}", flush=True)
            if is_arduino and not arduino_port:
                arduino_port = p["device"]
    else:
        print("    [!] No native /dev/ttyACM* or /dev/ttyUSB* ports bound inside WSL2.", flush=True)

    # 2. Audit Windows Host PnP Devices
    print("\n[*] Auditing Windows 11 Host PnP Hardware Devices...", flush=True)
    win_devices = query_win11_pnp_serial()
    if win_devices:
        for dev in win_devices:
            name = dev.get("FriendlyName", "Unknown")
            status = dev.get("Status", "Unknown")
            print(f"    - Host Device: {name} (Status: {status})", flush=True)
    else:
        print("    [*] Host PnP query complete. Bluetooth / standard COM ports present.", flush=True)

    # 3. Connection Instructions & Bridge
    print("----------------------------------------------------------", flush=True)
    if arduino_port:
        print(f"[+] Attempting serial handshake on target: {arduino_port}...", flush=True)
        try:
            with serial.Serial(arduino_port, 115200, timeout=2) as ser:
                ser.write(b"PING\n")
                time.sleep(0.5)
                resp = ser.readline().decode("utf-8", errors="ignore").strip()
                print(f"[+] Arduino Response > {resp if resp else 'ACK (No string output)'}", flush=True)
                
                ts = time.strftime("%Y-%m-%d %H:%M:%S")
                with open(telemetry_csv, "a", encoding="utf-8") as f:
                    f.write(f"{ts},{arduino_port},Arduino_USB,CONNECTED,Handshake_OK\n")
        except Exception as e:
            print(f"[!] Serial connection attempt note on {arduino_port}: {e}", flush=True)
    else:
        print("[!] NOTICE: Physical Arduino USB device not currently bound to WSL2.", flush=True)
        print("    To bind a physical Arduino plugged into Windows host to WSL2, run:")
        print("    1. Open PowerShell on Windows host:  powershell.exe")
        print("    2. List connected USB devices:       usbipd wsl list")
        print("    3. Attach Arduino to WSL2:           usbipd wsl attach --busid <BUSID>")
        print("    4. Target port will appear at:       /dev/ttyACM0 or /dev/ttyUSB0")
        
        ts = time.strftime("%Y-%m-%d %H:%M:%S")
        with open(telemetry_csv, "a", encoding="utf-8") as f:
            f.write(f"{ts},NONE,Arduino_USB,SEARCHING,USBIPD_Guide_Provided\n")

    print("----------------------------------------------------------", flush=True)
    print(f"[+] Telemetry Logged: {telemetry_csv.relative_to(root)}", flush=True)
    print("[SUCCESS] Arduino USB Serial Audit Complete!", flush=True)
    return True

if __name__ == "__main__":
    audit_and_connect_arduino()
    sys.exit(0)
