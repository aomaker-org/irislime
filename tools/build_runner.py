#!/usr/bin/env python3
# ==============================================================================
# Path:        tools/build_runner.py
# Purpose:     Unified Profile Build Orchestrator & Parameterized Watchdog
# Target OS:   Ubuntu 26.04 LTS / WSL2 Subsystem (Core12 Workstation Platform)
# Lineage:     Unified Asset Specification
# Author:      IrisLime Core Engine Integration
# Updated:     20260710_0543 (Parameterized Back-Channel Override Processing)
# ==============================================================================

import os
import sys
import json
import time
import subprocess
import argparse
from pathlib import Path
from threading import Thread
from queue import Queue, Empty

# ==============================================================================
# Global Configuration & Boundary Markers
# ==============================================================================
HEARTBEAT_FILE = Path(".irislime_heartbeat").resolve()
MANIFEST_FILE = Path("build/build_status.json").resolve()
DEFAULT_SILENCE_BUDGET = 600  # 10-Minute Operational Safety Gate Baseline
REPORT_THRESHOLD = 15.0       # Ticker interval and log verification gate

class BuildOrchestrator:
    def __init__(self, target: str, profile: str, silence_budget: int):
        self.target = target.lower()
        self.profile = profile.capitalize() if profile.lower() != "relwithdebinfo" else "RelWithDebInfo"
        self.silence_budget = silence_budget
        
        self.target_dir = Path(f"build/{self.target}_{self.profile.lower()}").resolve()
        self.timestamp = time.strftime("%Y%m%d_%H%M%S")
        self.log_dir = Path(f"logs/builds/{self.target}_{self.profile.lower()}").resolve()
        self.log_file = self.log_dir / f"build_{self.timestamp}.log"
        
        # Telemetry State Tracking Inodes
        self.last_known_size = 0
        self.last_heartbeat_ts = 0
        self.ticker_active = False
        
    def pre_flight_setup(self):
        """Ensure clean directories exist and touch the signaling layers."""
        self.log_dir.mkdir(parents=True, exist_ok=True)
        Path("build").mkdir(parents=True, exist_ok=True)
        
        HEARTBEAT_FILE.touch(exist_ok=True)
        self.last_heartbeat_ts = HEARTBEAT_FILE.stat().st_mtime
        
        print("==================================================================")
        print(f"[+] Executing Isolated Target: {self.target.upper()} | Profile: {self.profile}")
        print("==================================================================")
        print(f"[+] Isolated Target Folder: {self.target_dir}")
        print(f"[+] Persistent Log Target:  {self.log_file}")
        print(f"[Watchdog Init] Activity monitoring initialized. Silence Budget: {self.silence_budget}s")
        print("==================================================================\n")

    def update_manifest(self, status: str):
        """Atomically update the workspace root build_status.json manifest file."""
        manifest_data = {
            "last_built_target": self.target,
            "profile": self.profile,
            "timestamp": self.timestamp,
            "target_directory": str(self.target_dir),
            "log_file_location": str(self.log_file),
            "status": status
        }
        with open(MANIFEST_FILE, "w") as f:
            json.dump(manifest_data, f, indent=2)

    def _stream_reader(self, pipe, queue: Queue):
        """Background thread worker reading text strings line-by-line natively."""
        try:
            for line in iter(pipe.readline, ''):
                queue.put(line)
        except Exception:
            pass
        finally:
            pipe.close()

    def execute_build(self) -> bool:
        """Core execution block managing compilation forks and tracking metrics."""
        self.pre_flight_setup()
        
        cmd = ["make", f"build-{self.target}", f"PROFILE={self.profile}", f"LOG_FILE_PATH={str(self.log_file)}"]
        
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            bufsize=1,
            text=True,
            close_fds=True
        )
        
        stdout_queue = Queue()
        reader_thread = Thread(target=self._stream_reader, args=(process.stdout, stdout_queue), daemon=True)
        reader_thread.start()
        
        silence_counter = 0.0
        poll_interval = 1.0  # 1-second iteration evaluation loop
        
        while True:
            process_status = process.poll()
            activity_detected = False
            
            # --- Tier 1 tracking: Standard Output Pipeline Stream Capture ---
            while True:
                try:
                    line_text = stdout_queue.get_nowait().rstrip()
                    if self.ticker_active:
                        sys.stdout.write("\n")
                        self.ticker_active = False
                    print(f"  [STREAM] > {line_text}")
                    activity_detected = True
                except Empty:
                    break
                    
            # --- Tier 2 tracking: Passive Filesystem Inode Log Growth Sentinel ---
            if self.log_file.exists():
                try:
                    current_size = self.log_file.stat().st_size
                    if current_size > self.last_known_size:
                        self.last_known_size = current_size
                        activity_detected = True
                except OSError:
                    pass
                    
            # --- Tier 3 tracking: Volatile Parameterized Back-Channel Heartbeat ---
            if HEARTBEAT_FILE.exists():
                try:
                    current_heartbeat_ts = HEARTBEAT_FILE.stat().st_mtime
                    if current_heartbeat_ts > self.last_heartbeat_ts:
                        self.last_heartbeat_ts = current_heartbeat_ts
                        activity_detected = True
                        
                        # Parse the contents to extract dynamic command values
                        with open(HEARTBEAT_FILE, "r", errors="replace") as hf:
                            pulse_data = hf.read().strip().split()
                        
                        if len(pulse_data) >= 2 and pulse_data[0].lower() == "woof" and pulse_data[1].isdigit():
                            self.silence_budget = int(pulse_data[1])
                            if self.ticker_active:
                                sys.stdout.write("\n")
                                self.ticker_active = False
                            print(f"\n[Watchdog Override] 🐾 Dynamic pulse captured! Safety gate expanded to {self.silence_budget}s.")
                        else:
                            if self.ticker_active:
                                sys.stdout.write("\n")
                                self.ticker_active = False
                            print(f"\n[Watchdog Reset] Ambient pulse captured. Budget restored to baseline threshold.")
                except OSError:
                    pass
            
            # Evaluate Watchdog State Machine Gates
            if activity_detected:
                if silence_counter >= REPORT_THRESHOLD:
                    if self.ticker_active:
                        sys.stdout.write("\n")
                        self.ticker_active = False
                    
                    print(f"\n[Watchdog Reset] Activity confirmed after {silence_counter:.1f}s of quiet. Budget restored to {self.silence_budget}s.")
                    
                    if self.log_file.exists():
                        try:
                            with open(self.log_file, "r", errors="replace") as lf:
                                lines = lf.readlines()
                                tail = [l.rstrip() for l in lines[-2:] if l.strip()]
                                print("  [Last Log Context]:")
                                for tl in tail:
                                    print(f"    > {tl}")
                        except Exception:
                            pass
                silence_counter = 0.0
            else:
                silence_counter += poll_interval
                
                # Sleek, horizontal sign-of-life countdown ticker execution
                if silence_counter > 0 and silence_counter % REPORT_THRESHOLD == 0:
                    remaining_budget = int(self.silence_budget - silence_counter)
                    if not self.ticker_active:
                        sys.stdout.write(f"  [Watchdog] T-{self.silence_budget}s -> {remaining_budget}")
                        self.ticker_active = True
                    else:
                        sys.stdout.write(f" {remaining_budget}")
                    sys.stdout.flush()
                
            if silence_counter >= self.silence_budget:
                if self.ticker_active:
                    sys.stdout.write("\n")
                print(f"\n[!] WATCHDOG STALL: No compiler telemetry detected for {silence_counter}s across all tracking layers.")
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    
                print("\n==================================================================")
                print("[+] PROFILE PASS RESOLVED: TIMEOUT_ABORT")
                print(f"[-] Root Manifest Updated: {MANIFEST_FILE}")
                print(f"[-] Final Log Location:    {self.log_file}")
                print("==================================================================")
                self.update_manifest("TIMEOUT_ABORT")
                return False
                
            if process_status is not None:
                break
                
            time.sleep(poll_interval)
            
        if self.ticker_active:
            sys.stdout.write("\n")
            
        # Complete post-mortem evaluation pass
        if process.returncode == 0:
            print("\n==================================================================")
            print("[+] PROFILE PASS RESOLVED: SUCCESS")
            print(f"[-] Root Manifest Updated: {MANIFEST_FILE}")
            print(f"[-] Final Log Location:    {self.log_file}")
            print("==================================================================")
            self.update_manifest("SUCCESS")
            return True
        else:
            print(f"\n[!] Build Execution Macro Failed with Exit Code: {process.returncode}")
            print("\n==================================================================")
            print("[+] PROFILE PASS RESOLVED: FAILED")
            print(f"[-] Root Manifest Updated: {MANIFEST_FILE}")
            print(f"[-] Final Log Location:    {self.log_file}")
            print("==================================================================")
            self.update_manifest("FAILED")
            return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="IrisLime Intelligent Local Build Orchestrator")
    parser.add_argument("--target", type=str, default="vulkan", help="Target acceleration framework")
    parser.add_argument("--profile", type=str, default="Debug", help="Compilation profile")
    parser.add_argument("--budget", type=int, default=DEFAULT_SILENCE_BUDGET, help="Silence budget window")
    
    args = parser.parse_args()
    
    orchestrator = BuildOrchestrator(target=args.target, profile=args.profile, silence_budget=args.budget)
    success = orchestrator.execute_build()
    sys.exit(0 if success else 1)
