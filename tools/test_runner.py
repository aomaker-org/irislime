#!/usr/bin/env python3
# ==============================================================================
# Filename:     tools/test_runner.py
# Purpose:      Automated testing engine with combinatorial parameter matrix sweeps
# Type:         Executable Script
# Attribution:  fekerr & Gemini (20260705_0515 / Combinatorics Engine Pass)
# ==============================================================================

import sys
import os
import re
import json
import csv
import subprocess
import argparse
import datetime
import time
from pathlib import Path

def get_next_run_index(log_dir, timestamp, loop_id=None):
    """Calculates a unique tracking ID, embedding a loop counter if provided."""
    idx = 1
    suffix = f"_{loop_id}" if loop_id else ""
    while True:
        sh_check = log_dir / f"run_{timestamp}{suffix}_{idx:03d}.sh"
        log_check = log_dir / f"run_{timestamp}{suffix}_{idx:03d}.log"
        if not sh_check.exists() and not log_check.exists():
            return f"{idx:03d}"
        idx += 1

def format_exit_code(code):
    """Translates standard integer return values into dual decimal/hex system blocks."""
    if code < 0:
        unsigned_code = (1 << 32) + code
        return f"{code} (0x{unsigned_code:08X})"
    elif code > 255:
        return f"{code} (0x{code:08X})"
    return f"{code}"

def emit_log_file_tail(log_path, lines_count=20):
    """Surgically extracts and outputs the trailing log metrics on node failure."""
    print(f"\n[Forensic Log Tail] Final {lines_count} Lines of: {log_path.as_posix()}")
    print("------------------------------------------------------------------")
    try:
        if log_path.exists():
            with open(log_path, "r", encoding="utf-8", errors="replace") as f:
                lines = f.readlines()
                for idx, line in enumerate(lines[-lines_count:], start=1):
                    sys.stdout.write(f"  [TAIL L+{idx:02d}] > {line}")
        else:
            print(f"[!] System Warning: Log target file vanished from expected track.")
    except Exception as e:
        print(f"[!] Failed to parse post-mortem file tail: {e}")
    print("------------------------------------------------------------------")

def generate_reproduction_assets(log_dir, timestamp, run_idx, backend, profile, cmd_args, env, code, stdout, stderr, duration, loop_id=None):
    """Commits forensic master logs and fully expanded shell replication scripts to disk."""
    log_dir.mkdir(parents=True, exist_ok=True)
    suffix = f"_{loop_id}" if loop_id else ""
    
    sh_file = log_dir / f"run_{timestamp}{suffix}_{run_idx}.sh"
    log_file = log_dir / f"run_{timestamp}{suffix}_{run_idx}.log"
    
    formatted_status = format_exit_code(code)
    
    with open(sh_file, "w", encoding="utf-8", newline="\n") as sf:
        sf.write("#!/usr/bin/bash\n")
        sf.write(f"# ==============================================================================\n")
        sf.write(f"# Automated Replication Script Generated for Backend: {backend} ({profile})\n")
        sf.write(f"# Generation Timestamp: {timestamp}{suffix}_{run_idx} | Status: {formatted_status}\n")
        sf.write(f"# Measured Execution Duration: {duration:.4f} seconds\n")
        sf.write(f"# ==============================================================================\n\n")
        
        for key in sorted(env.keys()):
            if any(x in key for x in ["IRISLIME", "OpenVINO", "OPENVINO", "ONEAPI", "ZES", "TCM", "OPENSSL", "PATH"]):
                escaped_val = str(env[key]).replace(" ", "\\ ")
                sf.write(f"export {key}={escaped_val}\n")
        
        sf.write("\n# Fully Expanded Target Command Line Statement\n")
        expanded_cmd = " ".join([f'"{x}"' if " " in x else x for x in cmd_args])
        sf.write(f"{expanded_cmd}\n")
    
    try:
        sh_file.chmod(0o755)
    except Exception:
        pass

    with open(log_file, "w", encoding="utf-8") as lf:
        lf.write(f"=== TEST RUN TELEMETRY METRIC MANIFEST ===\n")
        lf.write(f"Timestamp ID:       {timestamp}{suffix}_{run_idx}\n")
        lf.write(f"Command line:       {' '.join(cmd_args)}\n")
        lf.write(f"Execution Duration: {duration:.4f} seconds\n")
        lf.write(f"Exit Status:        {formatted_status}\n")
        lf.write(f"==========================================\n\n")
        lf.write(f"--- [RAW STDOUT STREAMS] ---\n{stdout}\n\n")
        lf.write(f"--- [RAW STDERR STREAMS] ---\n{stderr}\n")

    return sh_file, log_file

def append_csv_telemetry(backend, profile, stdout_data, log_filename, fallback_duration=0.0):
    """Parses llama-bench tables and appends them alongside tracking filenames to the CSV."""
    telemetry_csv = Path("logs/tests/telemetry_matrix.csv")
    telemetry_csv.parent.mkdir(parents=True, exist_ok=True)
    
    csv_exists = telemetry_csv.exists()
    row_pattern = re.compile(
        r"\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|"
    )
    
    captured_records = []
    lines = stdout_data.split("\n")
    
    for line in lines:
        if "model" in line or "----" in line or not line.strip():
            continue
        match = row_pattern.search(line)
        if match:
            cells = [c.strip() for c in match.groups()]
            ts_value = cells[6]
            std_dev = "0.0"
            if "±" in ts_value:
                parts = ts_value.split("±")
                ts_value = parts[0].strip()
                std_dev = parts[1].strip()
            elif "Â±" in ts_value:
                parts = ts_value.split("Â±")
                ts_value = parts[0].strip()
                std_dev = parts[1].strip()
                
            record = {
                "Timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "Backend": backend.upper(),
                "Profile": profile.upper(),
                "Model_Identifier": cells[0],
                "Model_Size": cells[1],
                "Model_Params": cells[2],
                "Execution_Backend": cells[3],
                "NGL_Layers": cells[4],
                "Test_Type": cells[5],
                "Tokens_Per_Sec": ts_value,
                "Std_Deviation": std_dev,
                "Execution_Duration_Sec": f"{fallback_duration:.4f}",
                "Log_File": log_filename
            }
            captured_records.append(record)
            
    if not captured_records and fallback_duration > 0.0:
        captured_records.append({
            "Timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "Backend": backend.upper(),
            "Profile": profile.upper(),
            "Model_Identifier": "FUNCTIONAL_UNIT",
            "Model_Size": "N/A",
            "Model_Params": "N/A",
            "Execution_Backend": backend.upper(),
            "NGL_Layers": "N/A",
            "Test_Type": "UNIT_TEST",
            "Tokens_Per_Sec": "N/A",
            "Std_Deviation": "N/A",
            "Execution_Duration_Sec": f"{fallback_duration:.4f}",
            "Log_File": log_filename
        })
            
    if captured_records:
        headers = list(captured_records[0].keys())
        with open(telemetry_csv, "a", encoding="utf-8", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=headers)
            if not csv_exists:
                writer.writeheader()
            writer.writerows(captured_records)

def execute_subprocess_target(args, env):
    """Safely executes a headless binary and tracks execution health with precise timing."""
    start_time = time.perf_counter()
    try:
        process = subprocess.run(
            args, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, errors="replace"
        )
        duration = time.perf_counter() - start_time
        return process.returncode, process.stdout, process.stderr, duration
    except Exception as e:
        duration = time.perf_counter() - start_time
        return -1, "", str(e), duration

def execute_single_test_node(full_path, env, log_dir, timestamp, run_idx, backend, profile, tail_lines, master_start):
    """Orchestrates single test nodes, logs execution vectors, and appends elapsed script runtime marks."""
    item = os.path.basename(full_path)
    elapsed_prefix = f"[{time.perf_counter() - master_start:06.2f}s]"
    print(f"  • {elapsed_prefix} Found Test Unit: {item} -> Executing...")
    
    cmd = [sys.executable, full_path] if item.endswith(".py") else ["bash", full_path]
    code, out, err, duration = execute_subprocess_target(cmd, env)
    
    sh_file, log_file = generate_reproduction_assets(log_dir, timestamp, run_idx, backend, profile, cmd, env, code, out, err, duration)
    append_csv_telemetry(backend, profile, out, log_file.name, fallback_duration=duration)
    
    if code == 0:
        print(f"    [✓] {item}: PASSED ({duration:.2f}s)")
        return True
    else:
        formatted_status = format_exit_code(code)
        print(f"    [✗] {item}: FAILED (Status: {formatted_status} | {duration:.2f}s)")
        emit_log_file_tail(log_file, tail_lines)
        return False

def traverse_and_execute_tests(backend, test_root_str, env, log_dir, timestamp, run_idx, profile, fail_fast, tail_lines, master_start):
    """Dynamically routes test steps whether given a specific file or target folder tree."""
    target_path = Path(test_root_str)
    
    if target_path.is_file():
        print(f"[Target Target] Direct single-file validation pass activated.")
        return execute_single_test_node(str(target_path), env, log_dir, timestamp, run_idx, backend, profile, tail_lines, master_start)
        
    backend_test_dir = target_path / backend if target_path.name != backend else target_path
    
    if not backend_test_dir.exists() or not backend_test_dir.is_dir():
        print(f"[-] Traversal: No specialized test directory found at {backend_test_dir.as_posix()}. Skipping pass.")
        return True

    print(f"[Traversal] Scanning for test infrastructure inside {backend_test_dir.as_posix()}...")
    all_passed = True
    
    for item in sorted(os.listdir(backend_test_dir)):
        if item.startswith("test_") and (item.endswith(".sh") or item.endswith(".py")):
            full_path = backend_test_dir / item
            success = execute_single_test_node(str(full_path), env, log_dir, timestamp, run_idx, backend, profile, tail_lines, master_start)
            if not success:
                all_passed = False
                if fail_fast:
                    print(f"[!] Fail-Fast Triggered: Aborting execution tree upon node crash.")
                    return False
                    
    return all_passed

def deduce_target_build_directory():
    """Queries project status records to find the most recent build directory target."""
    status_ledger_path = Path("build/build_status.json")
    if status_ledger_path.exists():
        try:
            with open(status_ledger_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                return data.get("target_directory")
        except Exception:
            pass
    return None

def run_evaluation_pass():
    master_start_time = time.perf_counter()
    print("\n[+] Launching Automated Validation Matrix...")
    print("------------------------------------------------------------------")
    
    parser = argparse.ArgumentParser(description="Irislime Custom Test Runner Automation")
    parser.add_argument("--dir", type=str, required=False, help="Target build directory to analyze")
    parser.add_argument("--tests-dir", type=str, default="tests", help="Root directory containing test scripts")
    parser.add_argument("--fail-fast", action="store_true", default=None, help="Force immediate abort on any failure")
    parser.add_argument("--no-fail-fast", action="store_false", dest="fail_fast", help="Disable fail-fast to execute full test array")
    parser.add_argument("--run-all", action="store_true", default=False, help="Execute all pipeline phases regardless of prior phase failures")
    parser.add_argument("--tail-lines", type=int, default=20, help="Number of tracking rows to extract from log file tails on failure")
    parsed_args = parser.parse_known_args()[0]
    
    target_dir_str = parsed_args.dir or deduce_target_build_directory()
    if not target_dir_str or not os.path.exists(target_dir_str):
        print("[!] Critical Error: Could not deduce valid target build workspace parameters.")
        return False
        
    target_dir = target_dir_str.rstrip('/')
    bin_base = f"{target_dir}/bin"
    control_path = "matrix_control.json"
    exe_suffix = ".exe" if os.name == "nt" else ""
    
    folder_signature = os.path.basename(target_dir)
    signature_parts = folder_signature.split('_')
    backend = signature_parts[0]
    profile = signature_parts[1].upper() if len(signature_parts) > 1 else "RELEASE"
    
    print(f"[Matrix Configuration] Deduced Backend: {backend.upper()} | Profile: {profile}")
    
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    log_dir = Path("logs/tests")
    run_idx = get_next_run_index(log_dir, timestamp)
    
    env = os.environ.copy()
    env["IRISLIME_ACTIVE_BACKEND"] = backend
    env["IRISLIME_ACTIVE_PROFILE"] = profile
    model_target = os.environ.get("IRISLIME_TEST_MODEL", "../models/tinyllama-1.1b-chat-v1.0.Q4_0.gguf")
    
    fail_fast_setting = False
    matrix_params = {}
    
    if os.path.exists(control_path):
        try:
            with open(control_path, "r") as cf:
                control_data = json.load(cf)
            global_settings = control_data.get("global_settings", {})
            if "test_model" in global_settings:
                model_target = global_settings["test_model"]
            backend_config = control_data.get("backend_overrides", {}).get(backend, {})
            if "fail_fast" in backend_config:
                fail_fast_setting = backend_config["fail_fast"]
            matrix_params = backend_config.get("test_matrix_parameters", {})
            custom_env_vars = backend_config.get("env_vars", {})
            for var_key, var_val in custom_env_vars.items():
                env[var_key] = str(var_val)
        except Exception:
            pass

    if parsed_args.fail_fast is not None:
        fail_fast_setting = parsed_args.fail_fast

    print(f"[Operational Config] Fail-Fast Mode Rule: {fail_fast_setting}")
    print(f"[Operational Config] Run-All Phases Rule: {parsed_args.run_all}")

    pipeline_failed = False

    # PHASE 1: Low-Level Engine Syntax Linkage Test
    unit_test_binary = f"{bin_base}/test-backend-ops{exe_suffix}"
    if os.path.exists(unit_test_binary):
        elapsed_mark = f"[{time.perf_counter() - master_start_time:06.2f}s]"
        print(f"\n{elapsed_mark} [Exec] Phase 1: Verifying Low-Level Engine Syntax Linkage: {unit_test_binary}")
        code, out, err, duration = execute_subprocess_target([unit_test_binary, "--list-ops"], env)
        _, log_file = generate_reproduction_assets(log_dir, timestamp, run_idx, backend, profile, [unit_test_binary, "--list-ops"], env, code, out, err, duration)
        if code != 0:
            formatted_status = format_exit_code(code)
            print(f"[!] Phase 1 Core Verification Failure [Status {formatted_status} | {duration:.2f}s]. Linkage corrupt.")
            emit_log_file_tail(log_file, parsed_args.tail_lines)
            if not parsed_args.run_all:
                return False
            pipeline_failed = True
        else:
            print(f"[+] Phase 1 Baseline Linkage Verification: PASSED ({duration:.2f}s)")

    # PHASE 2: Dynamic Test Directory Traversal
    elapsed_mark = f"[{time.perf_counter() - master_start_time:06.2f}s]"
    print(f"\n{elapsed_mark} [Exec] Phase 2: Launching Traversal Routine over Test Directories...")
    p2_success = traverse_and_execute_tests(backend, parsed_args.tests_dir, env, log_dir, timestamp, run_idx, profile, fail_fast_setting, parsed_args.tail_lines, master_start_time)
    if not p2_success:
        pipeline_failed = True
        if not parsed_args.run_all:
            return False
    else:
        print("[+] Phase 2 Directory Traversal Sweep: PASSED")

    # PHASE 3: Combinatorial Performance Benchmarking Pass
    bench_binary = f"{bin_base}/llama-bench{exe_suffix}"
    if os.path.exists(bench_binary) and os.path.exists(model_target):
        # Extract parameter sweep dimensions with bulletproof defaults
        contexts = matrix_params.get("context_sizes", [128])
        batches = matrix_params.get("batch_sizes", [16])
        offloads = matrix_params.get("gpu_layers_offload", [-1])
        
        total_permutations = len(contexts) * len(batches) * len(offloads)
        elapsed_mark = f"[{time.perf_counter() - master_start_time:06.2f}s]"
        print(f"\n{elapsed_mark} [Exec] Phase 3: Initializing Hyperparameter Sweep Grid ({total_permutations} Permutations)")
        print(f"  > Context Size Array: {contexts}")
        print(f"  > Batch Size Array:   {batches}")
        print(f"  > GPU Layer Offloads: {offloads}")
        print("------------------------------------------------------------------")
        
        loop_counter = 1
        for ctx in contexts:
            for b in batches:
                for ngl in offloads:
                    loop_id = f"sweep_{loop_counter:03d}"
                    iter_start = f"[{time.perf_counter() - master_start_time:06.2f}s]"
                    print(f"  • {iter_start} Permutation {loop_counter}/{total_permutations} -> [-c {ctx} -b {b} -ngl {ngl}]")
                    
                    bench_args = [
                        bench_binary, 
                        "--model", model_target, 
                        "-p", str(ctx), 
                        "-n", "16",
                        "-b", str(b),
                        "-ngl", str(ngl)
                    ]
                    if backend.lower() not in ("litert", "openvino", "base"):
                        bench_args.extend(["--device", backend])
                    
                    code, out, err, duration = execute_subprocess_target(bench_args, env)
                    
                    # Compute unique iteration index tracking markers to prevent overrides
                    iter_run_idx = get_next_run_index(log_dir, timestamp, loop_id=loop_id)
                    sh_file, log_file = generate_reproduction_assets(
                        log_dir, timestamp, iter_run_idx, backend, profile, 
                        bench_args, env, code, out, err, duration, loop_id=loop_id
                    )
                    
                    if code != 0:
                        formatted_status = format_exit_code(code)
                        print(f"    [✗] Grid Node Failed (Status: {formatted_status} | {duration:.2f}s)")
                        emit_log_file_tail(log_file, parsed_args.tail_lines)
                        pipeline_failed = True
                        if fail_fast_setting:
                            print("[!] Fail-Fast Triggered inside Phase 3 Sweep. Evacuating Grid.")
                            return False
                    else:
                        print(f"    [✓] Grid Node Complete ({duration:.2f}s)")
                        # Extract row rows to parse directly into telemetry matrix csv
                        append_csv_telemetry(backend, profile, out, log_file.name, fallback_duration=duration)
                    
                    loop_counter += 1
        
        print(f"\n[+] Phase 3 Combinatorial Sweep Completed.")
    else:
        print(f"[-] Phase 3 Skip: Target benchmarking suite or baseline model unavailable.")

    return not pipeline_failed

if __name__ == "__main__":
    success = run_evaluation_pass()
    sys.exit(0 if success else 1)

# --- END OF FILE: tools/test_runner.py ---
