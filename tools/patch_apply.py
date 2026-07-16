import sys
import subprocess
import pyperclip
import os
from datetime import datetime

def run_cmd(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True)

def patch_out():
    # Generate diff from HEAD
    result = run_cmd("git diff --unified=3 HEAD")
    if result.returncode != 0 or not result.stdout.strip():
        print("[!] Nothing to patch out (no changes detected).")
        return
    
    # Copy to clipboard
    pyperclip.copy(result.stdout)
    
    # Log to disk for safety
    log_dir = "logs/patches"
    os.makedirs(log_dir, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_path = f"{log_dir}/patch_out_{ts}.patch"
    with open(log_path, 'w') as f:
        f.write(result.stdout)
        
    print(f"[+] Patch generated ({len(result.stdout)} bytes). Logged to {log_path}. Copied to clipboard.")

def patch_in():
    patch_data = pyperclip.paste()
    if not patch_data.strip():
        print("[!] Clipboard is empty.")
        return

    # Pre-flight: Check if apply will succeed
    with open(".temp.patch", "w") as f:
        f.write(patch_data)
        
    check = run_cmd("git apply --check --ignore-whitespace .temp.patch")
    if check.returncode != 0:
        print(f"[!] Pre-flight check failed:\n{check.stderr}")
        os.remove(".temp.patch")
        return

    # Execute
    apply = run_cmd("git apply --ignore-whitespace .temp.patch")
    if apply.returncode == 0:
        print("[+] Patch applied successfully.")
    else:
        print(f"[!] Patch application failed:\n{apply.stderr}")
    
    os.remove(".temp.patch")

if __name__ == "__main__":
    if len(sys.argv) < 2: sys.exit(1)
    if sys.argv[1] == "out": patch_out()
    elif sys.argv[1] == "in": patch_in()

