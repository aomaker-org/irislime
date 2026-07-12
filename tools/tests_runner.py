#!/usr/bin/env python3
# ==============================================================================
# Path:        tools/tests_runner
# Purpose:     Dynamic Discovery Test Suite Execution Engine
# Target OS:   Ubuntu 26.04 LTS / WSL2 Subsystem (Core12 Workstation Platform)
# Lineage:     Unified Asset Specification / Verification Suite
# Author:      IrisLime Core Engine Integration
# Updated:     20260710_0558 (Format specifier correction & vulkan filtering pass)
# ==============================================================================

import os
import sys
import json
import time
import subprocess
import argparse
from pathlib import Path

# ==============================================================================
# Global Configuration & Paths
# ==============================================================================
WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
LOG_DIR = WORKSPACE_ROOT / "logs" / "tests"
TEST_MANIFEST = WORKSPACE_ROOT / "build" / "test_status.json"
DEFAULT_TEST_TIMEOUT = 30  # 30-second safety gate per individual unit test

class TestEngine:
    def __init__(self, target_profile: str, timeout: int):
        self.target_profile = target_profile.lower() if target_profile else None
        self.timeout = timeout
        self.timestamp = time.strftime("%Y%m%d_%H%M%S")
        self.run_log_file = LOG_DIR / f"test_run_{self.timestamp}.json"
        
        # Diagnostics summaries
        self.passed_count = 0
        self.failed_count = 0
        self.timeout_count = 0
        self.results_registry = {}

    def pre_flight_checks(self):
        """Ensure directories are staged cleanly."""
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        print("==================================================================")
        print("[+] IRISLIME AUTOMATED DYNAMIC TESTING MATRIX INITIALIZED")
        print("==================================================================")
        print(f"[*] Workspace Root: {WORKSPACE_ROOT}")
        print(f"[*] Log Staging:    {self.run_log_file}")
        print(f"[*] Safety Timeout: {self.timeout}s per unit test")
        print("==================================================================")

    def discover_tests(self) -> list:
        """Probe build directories dynamically to harvest executable test binaries."""
        discovered_binaries = []
        build_dir = WORKSPACE_ROOT / "build"
        
        if not build_dir.exists():
            print(f"[!] Core build directory missing: {build_dir}. Aborting scan.")
            return discovered_binaries

        # Search for binary folders inside our pattern layout (e.g., build/vulkan_debug/bin)
        for profile_path in build_dir.iterdir():
            if profile_path.is_dir() and not profile_path.name.startswith("."):
                # Filter specifically by selected target profile if provided
                if self.target_profile and self.target_profile not in profile_path.name.lower():
                    continue
                    
                bin_path = profile_path / "bin"
                if bin_path.exists() and bin_path.is_dir():
                    for file in bin_path.iterdir():
                        # Authoritative match criterion: starts with 'test-' and has execute bits
                        if file.is_file() and file.name.startswith("test-") and os.access(file, os.X_OK):
                            discovered_binaries.append((profile_path.name, file))
                            
        # Sort items chronologically by profile name and binary name for scannability
        discovered_binaries.sort(key=lambda x: (x[0], x[1].name))
        return discovered_binaries

    def execute_suite(self):
        """Iterate through harvested targets inside an isolated execution environment."""
        self.pre_flight_checks()
        test_list = self.discover_tests()
        
        if not test_list:
            print(f"[-] Discovery loop returned empty for profile filter: '{self.target_profile}'.")
            return False

        print(f"[+] Probing complete. Identified {len(test_list)} independent test targets.\n")
        print(f"{'PROFILE':<24} | {'TEST TARGET NAME':<30} | {'STATUS':<10} | {'ELAPSED':<8}")
        print("-" * 80)

        for profile, binary_path in test_list:
            start_time = time.time()
            test_key = f"{profile}/{binary_path.name}"
            
            try:
                # Execute the unit test target within its native binary directory context
                res = subprocess.run(
                    [str(binary_path)],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    timeout=self.timeout,
                    cwd=str(binary_path.parent)
                )
                
                elapsed = time.time() - start_time
                if res.returncode == 0:
                    status = "PASSED"
                    self.passed_count += 1
                else:
                    status = "FAILED"
                    self.failed_count += 1
                    
                output_dump = res.stdout
                
            except subprocess.TimeoutExpired as te:
                elapsed = time.time() - start_time
                status = "TIMEOUT"
                self.timeout_count += 1
                output_dump = te.stdout if te.stdout else "Process hung and was terminated by timeout gate."
                
            # Log full details into memory matrix
            self.results_registry[test_key] = {
                "profile": profile,
                "name": binary_path.name,
                "status": status,
                "elapsed_seconds": round(elapsed, 3),
                "output": output_dump.splitlines() if output_dump else []
            }
            
            # FIXED: Moved string literal 's' safely outside the curly format block
            print(f"{profile:<24} | {binary_path.name:<30} | {status:<10} | {elapsed:.2f}s")

        self.finalize_run()
        return self.failed_count == 0 and self.timeout_count == 0

    def finalize_run(self):
        """Compile statistics, write telemetry records, and update master status files."""
        summary = {
            "timestamp": self.timestamp,
            "metrics": {
                "total_executed": len(self.results_registry),
                "passed": self.passed_count,
                "failed": self.failed_count,
                "timeout": self.timeout_count
            },
            "tests": self.results_registry
        }
        
        with open(self.run_log_file, "w") as f:
            json.dump(summary, f, indent=2)
            
        with open(TEST_MANIFEST, "w") as f:
            json.dump({
                "last_run_timestamp": self.timestamp,
                "summary": summary["metrics"],
                "status": "SUCCESS" if (self.failed_count == 0 and self.timeout_count == 0) else "FAILURES_DETECTED"
            }, f, indent=2)

        print("\n==================================================================")
        print("[+] MATRIX RUN COMPLETED")
        print(f"    Passed:  {self.passed_count}")
        print(f"    Failed:  {self.failed_count}")
        print(f"    Timeout: {self.timeout_count}")
        print(f"[-] Authoritative Manifest Synchronized: {TEST_MANIFEST}")
        print("==================================================================")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="IrisLime Dynamic Discovery Test Engine")
    parser.add_argument(
        "--profile", 
        type=str, 
        default=None, 
        help="Isolate execution to a specific build directory pattern (e.g., vulkan_debug)"
    )
    parser.add_argument(
        "--timeout", 
        type=int, 
        default=DEFAULT_TEST_TIMEOUT, 
        help="Individual test duration constraint threshold"
    )
    
    args = parser.parse_args()
    engine = TestEngine(target_profile=args.profile, timeout=args.timeout)
    success = engine.execute_suite()
    sys.exit(0 if success else 1)

# end of file: tools/tests_runner
