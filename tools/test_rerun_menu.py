#!/usr/bin/env python3
# ==============================================================================
# Filename:     tools/test_rerun_menu.py
# Purpose:      Interactive terminal interface to replay historical validation loops
# Type:         Executable Script
# Attribution:  fekerr & Gemini (20260705_0442 / Enter-Key Default Pass)
# ==============================================================================

import sys
import os
import subprocess
from pathlib import Path

def display_interactive_history_menu():
    log_dir = Path("logs/tests")
    if not log_dir.exists():
        print("[!] Execution Error: No historical test logs discovered on disk paths.")
        sys.exit(0)
        
    # Gather all reproduction shell files sorted chronologically (newest first)
    sh_scripts = sorted(list(log_dir.glob("*.sh")), key=lambda x: x.stat().st_mtime, reverse=True)
    
    if not sh_scripts:
        print("[!] Execution Error: Missing reproducible shell targets (*.sh) inside logging workspace.")
        sys.exit(0)
        
    print("\n==================================================================")
    print("      IrisLime Automated Test Replication & History Engine        ")
    print("==================================================================")
    print(" Select a target index to re-verify the exact effective command:")
    print("------------------------------------------------------------------")
    
    # Cap selection grid presentation limit slice to the last 10 runs
    display_limit = min(len(sh_scripts), 10)
    for idx in range(display_limit):
        target_script = sh_scripts[idx]
        friendly_time = target_script.name.replace("run_", "").replace(".sh", "")
        
        meta_label = "Unknown Binary Target"
        try:
            with open(target_script, "r", encoding="utf-8") as f:
                for line in f:
                    if "Generated for Backend:" in line:
                        meta_label = line.replace("#", "").strip()
                        break
        except Exception:
            pass
            
        prefix = "[ Last Run ]" if idx == 0 else f"[ Index {idx:02d} ]"
        print(f" {prefix} -> Record Target ID: {friendly_time}")
        print(f"                |-- context: {meta_label}")
        print(f"                \\-- file:    {target_script.as_posix()}\n")
        
    print(" [ q ]       -> Exit Selection Workspace Grid")
    print("------------------------------------------------------------------")
    
    # Implements safe carriage-return capture to prioritize immediate re-runs
    user_choice = input("Enter choice target [Default: Enter -> Last Run]: ").strip().lower()
    
    if user_choice == "":
        chosen_idx = 0
        print("[*] Empty target caught. Short-circuiting to Index 00 (Last Run)...")
    elif user_choice in ("q", "quit", "exit"):
        print("[-] Exiting replication engine pass.")
        sys.exit(0)
    else:
        try:
            chosen_idx = int(user_choice)
        except ValueError:
            print("[!] Input Error: Pass an explicit index integer, hit Enter, or choose 'q'.")
            sys.exit(1)
            
    if chosen_idx < 0 or chosen_idx >= display_limit:
        print("[!] Boundary Error: Selection falls outside active timeline arrays.")
        sys.exit(1)
        
    selected_sh_script = sh_scripts[chosen_idx]
    print(f"\n[*] Re-firing Target Matrix Loop: {selected_sh_script.name}")
    print("==================================================================")
    
    # Stream execution bytes natively directly back to the live shell session
    result = subprocess.run(["bash", selected_sh_script.as_posix()])
    sys.exit(result.returncode)

if __name__ == "__main__":
    display_interactive_history_menu()

# --- END OF FILE: tools/test_rerun_menu.py ---
