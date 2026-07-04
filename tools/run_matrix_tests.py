#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/run_matrix_tests.py
# Purpose:     Centralized multi-pass data-driven test matrix execution engine.
#              Fully audited against formatting corruption and syntax leaks.
# Type:        Orchestration Script
# Attribution: fekerr & Gemini (20260703_0030 / flash 3.5 extended)
# Timestamp:   20260703_0030
# ==============================================================================

import os
import sys
import json
import subprocess
import argparse
import time
from datetime import datetime

class MatrixLogger:
    """Simultaneously pipes validation metrics to terminal stdout and a local log file."""
    def __init__(self, log_path):
        self.terminal = sys.stdout
        self.log_file = open(log_path, "w", encoding="utf-8", buffering=1)

    def write(self, message):
        self.terminal.write(message)
        self.log_file.write(message)

    def flush(self):
        self.terminal.flush()
        self.log_file.flush()

def load_json_config(file_path):
    if not os.path.exists(file_path):
        return None
    try:
        with open(file_path, "r") as f:
            return json.load(f)
    except Exception as e:
        print(f"[!] Error: Corrupt or unreadable json specification at {file_path}: {e}")
        return None

def discover_build_environments(repo_root):
    """Scans the build folder to locate all active compiled backend variations."""
    build_dir = os.path.join(repo_root, "build")
    envs = []
    if not os.path.exists(build_dir) or not os.path.isdir(build_dir):
        return envs
    
    for item in os.listdir(build_dir):
        item_path = os.path.join(build_dir, item)
        if os.path.isdir(item_path) and "_" in item:
            parts = item.split("_", 1)
            backend = parts[0]
            profile = parts[1]
            if os.path.exists(os.path.join(item_path, "bin")) or backend == "litert":
                envs.append({
                    "folder": item,
                    "backend": backend,
                    "profile": profile,
                    "bin_base": os.path.join(item_path, "bin")
                })
    return sorted(envs, key=lambda x: x["folder"])

def execute_test_permutation(name, cmd_args, env_updates, log_stream):
    """Executes a target binary process, capturing elapsed time and streaming logs."""
    env = os.environ.copy()
    env.update(env_updates)
    
    print(f"  [RUN] Target Script/Binary: {name}")
    print(f"        Command: {' '.join(cmd_args)}")
    
    start_mark = time.perf_counter()
    try:
        process = subprocess.Popen(
            cmd_args, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
        )
        
        if process.stdout:
            for line in process.stdout:
                log_stream.write(line)
                
        return_code = process.wait()
        elapsed_duration = time.perf_counter() - start_mark
        return return_code == 0, round(elapsed_duration, 2)
    except Exception as e:
        print(f"  [❌] Critical system fault during subprocess execution loop: {e}")
        return False, 0.0

def finalize_and_summary(total, passed, failed, records, repo_root, is_triage_mode):
    """Prints out the final validation results ledger and updates persistent records."""
    print("\n================================================================================================")
    print("                                    FINAL MATRIX SWEEP LEDGER")
    print("================================================================================================")
    print(f" {'BUILD ENVIRONMENT':25} | {'TEST TARGET':22} | {'MODEL KEY':25} | {'DURATION':10} | {'STATUS'}")
    print("------------------------------------------------------------------------------------------------")
    for r in records:
        print(f" {r['env']:25} | {r['test']:22} | {r['model']:25} | {r['duration_seconds']:8}s | {r['status']}")
    print("================================================================================================")
    print(f"  TOTAL EVALUATED PERMUTATIONS : {total}")
    print(f"  SUCCESSFUL PASSES            : {passed}")
    print(f"  EXECUTION CRASHES/FAILURES   : {failed}")
    print("====================================================================================\n")

    # Safely write global tracking results ONLY if performing a broad master pass
    if not is_triage_mode:
        status_payload = {
            "last_sweep_timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "metrics": {"total": total, "passed": passed, "failed": failed},
            "runs": records
        }
        status_path = os.path.join(repo_root, "build", "test_status.json")
        with open(status_path, "w") as sf:
            json.dump(status_payload, sf, indent=2)

def orchestrate_matrix_sweep():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    # Setup Argument Filters
    parser = argparse.ArgumentParser(description="IrisLime Matrix Multi-Pass Test Sweeper")
    parser.add_argument("--backend", type=str, help="Filter sweep to a specific backend")
    parser.add_argument("--profile", type=str, help="Filter sweep to a specific profile")
    parser.add_argument("--failed", action="store_true", help="Only rerun permutations that failed in the last sweep pass")
    parsed_args = parser.parse_args()

    # Establish Log Directories out-of-tree
    log_dir = os.path.join(repo_root, "logs", "tests")
    os.makedirs(log_dir, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file_path = os.path.join(log_dir, f"matrix_run_{timestamp}.log")
    
    # Intercept system stdout and map to our dual sink logger
    matrix_logger = MatrixLogger(log_file_path)
    sys.stdout = matrix_logger

    print(f"[Make Session] Launching Validation Matrix at {datetime.now().strftime('%a %b %d %H:%M:%S %Z %Y')}")
    
    status_path = os.path.join(repo_root, "build", "test_status.json")
    failed_permutations = set()
    
    # Extract targeted history sets if triage mode is invoked
    if parsed_args.failed:
        print("\n[+] Mode Activation: Targeted Triage Pass (--failed)")
        last_status = load_json_config(status_path)
        if last_status and "runs" in last_status:
            failed_permutations = {
                (r["env"], r["test"], r["model"]) 
                for r in last_status["runs"] if r.get("status") == "FAILED"
            }
        if not failed_permutations:
            print("[*] Notice: No recorded verification failures found in tracking logs. Exiting safely.")
            sys.exit(0)
        print(f"[Triage] Isolated {len(failed_permutations)} failing case intersections to re-run.")
    else:
        print("\n[+] Initializing Multi-Pass Sequential Data-Driven Test Matrix Sweep...")
        
    print(f"[+] Active Logging Session Direct File Sink: logs/tests/matrix_run_{timestamp}.log")
    print("==================================================================")
    
    models_manifest = load_json_config(os.path.join(repo_root, "model_selector.json"))
    test_manifest = load_json_config(os.path.join(repo_root, "test_controller.json"))
    matrix_control = load_json_config(os.path.join(repo_root, "matrix_control.json"))
    
    if not models_manifest or not test_manifest:
        print("[!] Abort: Matrix orchestration blocked due to missing configuration definitions.")
        sys.exit(1)
        
    models_root = models_manifest.get("models_root_override") or os.path.abspath(os.path.join(repo_root, "..", "models"))
    available_models = models_manifest.get("available_assets", {})
    execution_matrix = test_manifest.get("execution_matrix", {})
    global_settings = test_manifest.get("global_test_settings", {})
    
    all_build_envs = discover_build_environments(repo_root)
    
    if parsed_args.backend:
        all_build_envs = [e for e in all_build_envs if e["backend"] == parsed_args.backend]
    if parsed_args.profile:
        all_build_envs = [e for e in all_build_envs if e["profile"].lower() == parsed_args.profile.lower()]

    if not all_build_envs:
        print("[!] Abort: No compiled target environments detected inside the build matrix topology.")
        sys.exit(1)

    total_run = 0
    passed_run = 0
    failed_run = 0
    summary_records = []

    for b_env in all_build_envs:
        active_backend = b_env["backend"]
        active_profile = b_env["profile"]
        bin_base = b_env["bin_base"]
        
        env_updates = {
            "DEBUGINFOD_URLS": "",
            "IRISLIME_ACTIVE_BACKEND": active_backend,
            "IRISLIME_ACTIVE_PROFILE": active_profile
        }
        
        if matrix_control:
            custom_vars = matrix_control.get("backend_overrides", {}).get(active_backend, {}).get("env_vars", {})
            for var_key, var_val in custom_vars.items():
                env_updates[var_key] = str(var_val)

        for group_name, group_properties in execution_matrix.items():
            if not group_properties.get("enabled", False):
                continue
                
            targets = group_properties.get("targets", [])
            
            for target in targets:
                target_name = target.get("name")
                target_type = target.get("type")
                compatible_formats = target.get("compatible_formats", [])
                
                for model_alias, model_info in available_models.items():
                    if model_info.get("format") not in compatible_formats:
                        continue
                    
                    if parsed_args.failed and (b_env['folder'], target_name, model_alias) not in failed_permutations:
                        continue
                    
                    model_full_path = os.path.join(models_root, model_info.get("filename"))
                    cmd = []
                    
                    if target_type == "internal_script":
                        script_path = os.path.join(repo_root, target.get("path"))
                        cmd = [sys.executable, script_path]
                    elif target_type == "compiled_binary":
                        bin_path = os.path.join(bin_base, os.path.basename(target.get("relative_path")))
                        
                        if not os.path.exists(bin_path):
                            continue
                            
                        cmd = [bin_path] + target.get("args", [])
                        
                        if "llama-bench" in bin_path:
                            cmd.extend(["--model", model_full_path])
                            if active_backend not in ["litert", "cpu"]:
                                cmd.extend(["--device", active_backend])
                        elif "test-backend-ops" in bin_path:
                            if not target.get("args"):
                                cmd.append(active_backend)
                    # ...
                    total_run += 1
                    print(f"\n[{total_run}] Environment: {b_env['folder']} | Test: {target_name} | Model: {model_alias}")
                    
                    env_updates["IRISLIME_TEST_MODEL"] = model_full_path
                    success, elapsed_sec = execute_test_permutation(target_name, cmd, env_updates, matrix_logger)
                    
                    record = {
                        "env": b_env['folder'],
                        "test": target_name,
                        "model": model_alias,
                        "duration_seconds": elapsed_sec,
                        "status": "PASSED" if success else "FAILED"
                    }
                    summary_records.append(record)
                    
                    if success:
                        passed_run += 1
                    else:
                        failed_run += 1
                        if global_settings.get("stop_on_first_failure", False):
                            print("\n[!] Fail-Fast Triggered: Aborting matrix run early.")
                            finalize_and_summary(total_run, passed_run, failed_run, summary_records, repo_root, parsed_args.failed)
                            sys.exit(1)

    finalize_and_summary(total_run, passed_run, failed_run, summary_records, repo_root, parsed_args.failed)
    sys.exit(0 if failed_run == 0 else 1)

if __name__ == "__main__":
    orchestrate_matrix_sweep()
                    # ...

# End of file: tools/run_matrix_tests.py
