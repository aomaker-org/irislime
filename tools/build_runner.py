#!/usr/bin/env python3
# ==============================================================================
# Filename:     tools/build_runner.py
# Purpose:      Cross-platform build manager with environment mapping & logs tail
# Type:         Executable Script
# Attribution:  fekerr & Gemini (20260705_1015 / Integrated Production Pass)
# ==============================================================================

import sys
import os
import shutil
import subprocess
import datetime
import json
import threading
import queue
import argparse
from pathlib import Path

def load_matrix_control():
    """Ingests the root user-configured control specification file."""
    control_path = Path("matrix_control.json")
    if not control_path.exists():
        print(f"[!] Critical Error: Missing control file at {control_path}")
        sys.exit(3)
    with open(control_path, "r") as f:
        return json.load(f)

def load_cached_hardware_args(db_path_str):
    """Ingests pre-computed hardware features to bypass repetitive CMake checks."""
    if not db_path_str:
        return ""
    db_path = Path(db_path_str)
    if db_path.exists():
        try:
            with open(db_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                args = data.get("injected_cmake_args", "")
                print(f"[Hardware Sync] Ingested cached feature bypass flags: {args}")
                return args
        except Exception as e:
            print(f"[!] Warning: Failed parsing hardware cache database: {e}")
    else:
        print("[-] Hardware Cache Profile absent. Execute 'probe_hardware' to enable sub-2s configurations.")
    return ""

def verify_workspace_storage(min_free_gb):
    """Monitors workspace capacity ceilings before dropping into compiler passes."""
    _, _, free = shutil.disk_usage(".")
    free_gb = free / (1024 ** 3)
    print(f"[Storage Check] Active free capacity: {free_gb:.2f} GB (Required: {min_free_gb} GB)")
    return free_gb >= min_free_gb

def stream_reader_worker(pipe, output_queue):
    """Asynchronously drains a subprocess pipe line-by-line without blocking."""
    try:
        for line in iter(pipe.readline, ''):
            output_queue.put(line)
    except Exception:
        pass
    finally:
        pipe.close()

def emit_log_tail(log_path, lines_count=20):
    """Extracts and formats the final trailing metrics slice of a log file upon failure."""
    print(f"\n[!] METRIC POST-MORTEM: Last {lines_count} Lines of {log_path.name}:")
    print("------------------------------------------------------------------")
    try:
        if log_path.exists():
            with open(log_path, "r", encoding="utf-8", errors="replace") as f:
                lines = f.readlines()
                for idx, line in enumerate(lines[-lines_count:], start=1):
                    sys.stderr.write(f"  [TAIL L+{idx:02d}] > {line}")
        else:
            print(f"[-] System Warning: Log target file vanished from expected track.")
    except Exception as e:
        print(f"[-] Failed to extract post-mortem log stream: {e}")
    print("------------------------------------------------------------------")

def invoke_compilation_pass(backend, profile_spec, settings, hardware_bypass_args, debug_watchdog):
    """Configures and runs compilation blocks for a single backend/profile permutation."""
    profile_name = profile_spec.get("name", "Release")
    suffix = profile_spec.get("suffix", "release")
    
    jobs = settings.get("parallel_jobs", 1)
    cxx_flags = settings.get("cmake_cxx_flags", "")
    
    base_cmake_flags = settings.get("cmake_flags", "")
    if hardware_bypass_args:
        base_cmake_flags = f"{hardware_bypass_args} {base_cmake_flags}".strip()
        
    inactivity_timeout_secs = settings.get("inactivity_timeout_seconds", 120)
    
    target_dir = Path(f"build/{backend}_{suffix}")
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    
    log_dir = Path(f"logs/builds/{backend}_{suffix}")
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / f"build_{timestamp}.log"
    
    print(f"\n[+] Executing Isolated Target: {backend.upper()} | Profile: {profile_name}")
    print(f"==================================================================")
    print(f"[+] Isolated Target Folder: {target_dir.as_posix()}")
    print(f"[+] Persistent Log Target:  {log_file.as_posix()}")
    print(f"==================================================================")
    
    env_override = os.environ.copy()
    env_override["CMAKE_BUILD_TYPE"] = profile_name
    env_override["LOG_FILE_PATH"] = log_file.resolve().as_posix()
    
    make_binary = "make"
    if os.name == "nt" and not shutil.which("make"):
        if shutil.which("mingw32-make"):
            make_binary = "mingw32-make"
            
    openvino_env_path = env_override.get("OpenVINO_DIR") or env_override.get("OPENVINO_DIR", "")
    openvino_posix_path = Path(openvino_env_path).as_posix() if openvino_env_path else ""

    if backend == "litert":
        make_target = "litert-all"
        make_cmd = [
            make_binary,
            make_target,
            f"LITERT_DIR={target_dir.as_posix()}",
            f"NUM_BUILD_JOBS={jobs}"
        ]
    else:
        make_target = f"build-{backend}"
        make_cmd = [
            make_binary, 
            make_target, 
            f"BUILD_DIR={target_dir.as_posix()}",
            f"NUM_BUILD_JOBS={jobs}",
            f"OpenVINO_DIR={openvino_posix_path}"
        ]
    
    if cxx_flags:
        env_override["CMAKE_CXX_FLAGS"] = cxx_flags
    if base_cmake_flags:
        env_override["CMAKE_FLAGS"] = base_cmake_flags
        
    # CRITICAL: Extract and inject the custom env_vars block into subshell memory
    custom_env_vars = settings.get("env_vars", {})
    for var_key, var_val in custom_env_vars.items():
        env_override[var_key] = str(var_val)

    is_quiet = env_override.get("QUIET", "0") in ("1", "true", "TRUE")

    process = subprocess.Popen(
        make_cmd,
        env=env_override,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        errors="replace",
        bufsize=1
    )
    
    communication_queue = queue.Queue()
    reader_thread = threading.Thread(
        target=stream_reader_worker, 
        args=(process.stdout, communication_queue)
    )
    reader_thread.daemon = True
    reader_thread.start()
    
    last_activity_time = datetime.datetime.now()
    last_heartbeat_time = last_activity_time
    build_was_aborted = False
    
    if debug_watchdog:
        print(f"[Watchdog Init] Activity monitoring initialized. Silence Budget: {inactivity_timeout_secs}s")
    
    with open(log_file, "w", encoding="utf-8") as lf:
        while True:
            if process.poll() is not None and communication_queue.empty():
                break
                
            try:
                line = communication_queue.get(timeout=1.0)
                now = datetime.datetime.now()
                silence_duration = (now - last_activity_time).total_seconds()
                
                if debug_watchdog and silence_duration >= 5.0:
                    sys.stdout.write(f"\n[Watchdog Reset] Telemetry resumed after {silence_duration:.2f}s of quiet. Budget reset to {inactivity_timeout_secs}s.\n")
                    sys.stdout.flush()
                
                last_activity_time = now
                last_heartbeat_time = now
                
                lf.write(line)
                if not is_quiet:
                    sys.stdout.write(line)
                    sys.stdout.flush()
                    
            except queue.Empty:
                now = datetime.datetime.now()
                silence_delta = (now - last_activity_time).total_seconds()
                heartbeat_delta = (now - last_heartbeat_time).total_seconds()
                
                if debug_watchdog and silence_delta >= 10.0 and heartbeat_delta >= 30.0:
                    remaining_budget = max(0.0, inactivity_timeout_secs - silence_delta)
                    sys.stdout.write(f"\n[Watchdog Heartbeat] Sustained silence detected: {silence_delta:.1f}s. Remaining Budget: {remaining_budget:.1f}s / {inactivity_timeout_secs}s.\n")
                    sys.stdout.flush()
                    last_heartbeat_time = now
                
                if silence_delta > inactivity_timeout_secs:
                    print(f"\n[!] WATCHDOG STALL: No compiler telemetry for {silence_delta:.1f}s.")
                    process.terminate()
                    process.wait()
                    build_was_aborted = True
                    break

    process.wait()
    build_success = (process.returncode == 0) and not build_was_aborted
    
    status_payload = {
        "last_built_target": backend,
        "profile": profile_name,
        "timestamp": timestamp,
        "target_directory": target_dir.as_posix(),
        "log_file_location": log_file.as_posix(),
        "status": "SUCCESS" if build_success else ("TIMEOUT_ABORT" if build_was_aborted else "FAILED")
    }
    
    Path("build").mkdir(exist_ok=True)
    status_file_path = Path("build/build_status.json")
    with open(status_file_path, "w", encoding="utf-8") as sf:
        json.dump(status_payload, sf, indent=2)
        
    print(f"\n==================================================================")
    print(f"[+] PROFILE PASS RESOLVED: {status_payload['status']}")
    print(f"[-] Root Manifest Updated: {status_file_path.as_posix()}")
    print(f"[-] Final Log Location:    {log_file.as_posix()}")
    print(f"==================================================================")
    
    if not build_success:
        emit_log_tail(log_file, lines_count=20)
        
    return build_success

if __name__ == "__main__":
    control_config = load_matrix_control()
    
    parser = argparse.ArgumentParser(description="Irislime Custom Build Runner")
    parser.add_argument("--debug-watchdog", action="store_true", default=False, help="Enable throttled diagnostic updates for the inactivity watchdog")
    parsed_args = parser.parse_known_args()[0]
    
    # Resolves via explicit command-line switch OR inherited environment variable token
    debug_watchdog = parsed_args.debug_watchdog or (os.environ.get("IRISLIME_DEBUG_WATCHDOG") in ("1", "true", "TRUE"))
    
    global_limits = control_config.get("global_settings", {})
    min_space = global_limits.get("min_required_disk_space_gb", 5.0)
    hardware_db = global_limits.get("hardware_db_path", "")
    
    if not verify_workspace_storage(min_space):
        print("[!] ABORT: Insufficient host disk tracks to proceed safely.")
        sys.exit(2)
        
    bypass_flags = load_cached_hardware_args(hardware_db)
    backend_grid = control_config.get("backend_overrides", {})
    
    print("[Infra Dev] Processing control file execution matrices...")
    for backend, settings in backend_grid.items():
        if not settings.get("enabled", False):
            print(f"[Matrix] Skipping disabled backend layout target: {backend}")
            continue
            
        profiles_to_build = settings.get("ordered_profiles", [{"name": "Release", "suffix": "release"}])
        for profile_spec in profiles_to_build:
            if not invoke_compilation_pass(backend, profile_spec, settings, bypass_flags, debug_watchdog):
                print(f"[!] COMPILER FAULT: Pipeline broken at target {backend} ({profile_spec.get('name')})")
                sys.exit(1)
                
    print("\n[+] BUILD ENGINE METRICS: Control file compilation sweep complete.")

# end of tools/build_runner.py
