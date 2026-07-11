#!/usr/bin/env python3
# ==============================================================================
# Path:        tools/bbptests_runner.py
# Purpose:     Dynamic Matrix Executor, Watchdog & Capabilities Smoke Tester
# Target OS:   Ubuntu 26.04 LTS / WSL2 Subsystem (Core12 Workstation Platform)
# Lineage:     Unified Asset Specification / Verification Suite
# Author:      IrisLime Core Engine Integration
# Updated:     20260710_0620 (Integrated --smoke-help binary linkage validation)
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
# Global Configuration & Paths
# ==============================================================================
WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
LOG_DIR = WORKSPACE_ROOT / "logs" / "tests"
TEST_MANIFEST = WORKSPACE_ROOT / "build" / "test_status.json"
DEFAULT_TEST_TIMEOUT = 30  # 30-second safety budget per individual target

class TestEngine:
    def __init__(self, target_profile: str, timeout: int, smoke_help: bool):
        self.target_profile = target_profile.lower() if target_profile else None
        self.timeout = timeout
        self.smoke_help = smoke_help or ("SMOKE_HELP" in os.environ.get("IRISLIME_FLAG_VARS", ""))
        self.timestamp = time.strftime("%Y%m%d_%H%M%S")
        
        prefix = "smoke_help" if self.smoke_help else "test_run"
        self.run_log_file = LOG_DIR / f"{prefix}_{self.timestamp}.json"
        
        # Diagnostics summaries
        self.passed_count = 0
        self.failed_count = 0
        self.timeout_count = 0
        self.results_registry = {}

    def pre_flight_checks(self):
        """Ensure directories are staged cleanly."""
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        print("==================================================================")
        mode_str = "CAPABILITIES HELP-SMOKE TESTER" if self.smoke_help else "WATCHDOG-ARMED EXECUTOR"
        print(f"[+] BBPTESTS RUNNER: {mode_str}")
        print("==================================================================")
        print(f"[*] Workspace Root: {WORKSPACE_ROOT}")
        print(f"[*] Log Staging:    {self.run_log_file}")
        print(f"[*] Unit Timeout:   {self.timeout}s per target binary")
        print("==================================================================")

    def discover_targets(self) -> list:
        """Probe all build directories dynamically to harvest target files."""
        discovered_binaries = []
        build_dir = WORKSPACE_ROOT / "build"
        
        if not build_dir.exists():
            print(f"[!] Core build directory missing: {build_dir}. Aborting scan.")
            return discovered_binaries

        for profile_path in build_dir.iterdir():
            if profile_path.is_dir() and not profile_path.name.startswith("."):
                # Global sweep or isolated folder profile matching
                if self.target_profile and self.target_profile not in profile_path.name.lower():
                    continue
                    
                bin_path = profile_path / "bin"
                if bin_path.exists() and bin_path.is_dir():
                    for file in bin_path.iterdir():
                        if not file.is_file() or not os.access(file, os.X_OK):
                            continue
                            
                        if self.smoke_help:
                            # Smoke Mode: Grab EVERYTHING that is executable (cli, server, tests)
                            # Exclude symlink duplicates to preserve log clarity
                            if not file.is_symlink():
                                discovered_binaries.append((profile_path.name, file))
                        else:
                            # Standard Mode: Only grab direct test binaries
                            if file.name.startswith("test-"):
                                discovered_binaries.append((profile_path.name, file))
                            
        discovered_binaries.sort(key=lambda x: (x[0], x[1].name))
        return discovered_binaries

    def _stream_reader(self, pipe, queue: Queue):
        """Background thread worker to harvest text streams non-blockingly."""
        try:
            for line in iter(pipe.readline, ''):
                queue.put(line)
        except Exception:
            pass
        finally:
            pipe.close()

    def format_total_elapsed(self, seconds: float) -> str:
        """Convert float runtime delta into a compact layout stopwatch [MM:SS.S]."""
        minutes = int(seconds // 60)
        secs = seconds % 60
        return f"[{minutes:02d}:{secs:04.1f}]"

    def execute_suite(self):
        """Iterate through harvested targets inside an isolated execution environment."""
        self.pre_flight_checks()
        target_list = self.discover_targets()
        
        if not target_list:
            print(f"[-] Discovery loop returned empty for criteria.")
            return False

        total_targets = len(target_list)
        print(f"[+] Probing complete. Identified {total_targets} target executables.\n")
        print(f"{'RUN CLOCK':<10} | {'REM'} | {'PROFILE':<22} | {'TARGET BINARY NAME':<30} | {'STATUS':<10} | {'ELAPSED'}")
        print("-" * 98)

        suite_start_time = time.time()

        for index, (profile, binary_path) in enumerate(target_list):
            remaining_count = total_targets - index
            test_start_time = time.time()
            test_key = f"{profile}/{binary_path.name}"
            
            current_total_elapsed = time.time() - suite_start_time
            clock_str = self.format_total_elapsed(current_total_elapsed)
            sys.stdout.write(f"{clock_str:<10} | {remaining_count:03d} | {profile[:22]:<22} | {binary_path.name:<30} | ")
            sys.stdout.flush()

            # Establish arguments based on active operational mode
            exec_args = [str(binary_path)]
            if self.smoke_help:
                exec_args.append("-h")

            process = subprocess.Popen(
                exec_args,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                errors="replace",
                cwd=str(binary_path.parent)
            )

            stdout_queue = Queue()
            reader_thread = Thread(target=self._stream_reader, args=(process.stdout, stdout_queue), daemon=True)
            reader_thread.start()

            output_lines = []
            status = "UNKNOWN"
            ticker_printed = False
            last_ticker_time = test_start_time

            while True:
                process_status = process.poll()
                elapsed = time.time() - test_start_time

                while True:
                    try:
                        line = stdout_queue.get_nowait()
                        output_lines.append(line.rstrip())
                    except Empty:
                        break

                if process_status is not None:
                    if self.smoke_help:
                        # Smoke Mode Validation: Exit code 0 or 1 is acceptable for help flags.
                        # Core gate: Did it crash via a signal (negative code) or output loader text?
                        is_loader_error = any("error while loading shared libraries" in l.lower() for l in output_lines)
                        if process.returncode in [0, 1] and not is_loader_error:
                            status = "LOAD_OK"
                            self.passed_count += 1
                        else:
                            status = "LINK_ERR"
                            self.failed_count += 1
                    else:
                        if process.returncode == 0:
                            status = "PASSED"
                            self.passed_count += 1
                        else:
                            status = "FAILED"
                            self.failed_count += 1
                    break

                if elapsed >= self.timeout:
                    status = "TIMEOUT"
                    self.timeout_count += 1
                    process.terminate()
                    try:
                        process.wait(timeout=2)
                    except subprocess.TimeoutExpired:
                        process.kill()
                    break

                if elapsed > 2.0 and time.time() - last_ticker_time >= 1.0:
                    remaining_budget = int(self.timeout - elapsed)
                    if not ticker_printed:
                        sys.stdout.write(f"STALLED (T-{remaining_budget}s)")
                        ticker_printed = True
                    else:
                        sys.stdout.write(f"\b\b\b\b\b{remaining_budget:02d}s)")
                    sys.stdout.flush()
                    last_ticker_time = time.time()

                time.sleep(0.05)

            if ticker_printed:
                sys.stdout.write("\r")
                current_total_elapsed = time.time() - suite_start_time
                clock_str = self.format_total_elapsed(current_total_elapsed)
                sys.stdout.write(f"{clock_str:<10} | {remaining_count:03d} | {profile[:22]:<22} | {binary_path.name:<30} | ")

            print(f"{status:<10} | {elapsed:.2f}s")
            sys.stdout.flush()

            self.results_registry[test_key] = {
                "profile": profile,
                "name": binary_path.name,
                "status": status,
                "elapsed_seconds": round(elapsed, 3),
                "help_catalog": output_lines if self.smoke_help else [],
                "output": [] if self.smoke_help else output_lines
            }

        self.finalize_run(time.time() - suite_start_time)
        return self.failed_count == 0 and self.timeout_count == 0

    def finalize_run(self, total_suite_time: float):
        """Compile statistics, write telemetry records, and update master status files."""
        summary = {
            "timestamp": self.timestamp,
            "mode": "smoke_help" if self.smoke_help else "unit_tests",
            "metrics": {
                "total_executed": len(self.results_registry),
                "passed_or_ok": self.passed_count,
                "failed_or_link_err": self.failed_count,
                "timeout": self.timeout_count,
                "total_elapsed_seconds": round(total_suite_time, 3)
            },
            "targets": self.results_registry
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
        print(f"[+] MATRIX RUN COMPLETED ({summary['mode'].upper()})")
        print(f"    Passed/OK:  {self.passed_count}")
        print(f"    Failed/Err: {self.failed_count}")
        print(f"    Timeout:    {self.timeout_count}")
        print(f"    Total Runtime: {self.format_total_elapsed(total_suite_time)} ({total_suite_time:.2f}s)")
        print(f"[-] Log Dossier Generated: {self.run_log_file}")
        print("==================================================================")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="IrisLime Dynamic Discovery Verification Suite")
    parser.add_argument("--profile", type=str, default=None, help="Isolate execution by build folder pattern")
    parser.add_argument("--timeout", type=int, default=DEFAULT_TEST_TIMEOUT, help="Individual timeout gate")
    parser.add_argument("--smoke-help", action="store_true", help="Execute -h linkage checks across all binaries")
    
    args = parser.parse_args()
    engine = TestEngine(target_profile=args.profile, timeout=args.timeout, smoke_help=args.smoke_help)
    success = engine.execute_suite()
    sys.exit(0 if success else 1)

# end of file: tools/bbptests_runner.py
