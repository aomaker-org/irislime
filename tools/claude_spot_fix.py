#!/usr/bin/env python3
import sys, os, glob, subprocess, shutil

def analyze_and_fix(target_path):
    log_path = target_path
    
    # If a directory is passed, resolve the newest .log file inside it
    if os.path.isdir(target_path):
        matching_logs = glob.glob(os.path.join(target_path, "**", "*.log"), recursive=True)
        if matching_logs:
            log_path = max(matching_logs, key=os.path.getmtime)
        else:
            print(f"[Claude Spot-Fix] No .log files found inside directory: {target_path}")
            return

    print(f"[Claude Spot-Fix] Inspecting failure log: {log_path}")
    if not os.path.exists(log_path):
        print("[Claude Spot-Fix] Log file not found.")
        return
        
    with open(log_path, 'r') as f:
        log_lines = f.readlines()
        
    error_context = "".join(log_lines[-50:]) # Extract last 50 lines
    print("================ ERROR CONTEXT ================")
    print(error_context)
    print("===============================================")
    
    if shutil.which("claude"):
        prompt = f"The following build error occurred during IrisLime compilation:\n{error_context}\nProvide a minimal git patch to fix this error."
        subprocess.run(["claude", "-p", prompt])
    else:
        print("[Claude Spot-Fix] 'claude' CLI not in PATH. Error context captured for inspection.")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        analyze_and_fix(sys.argv[1])
