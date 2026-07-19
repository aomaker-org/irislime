#!/usr/bin/env python3
"""
Path:        tools/agy_mtfdash_bridge.py
Purpose:     AGY (Google Antigravity CLI) mtfdash Mesh Bridge.
             Binds AGY workspace activity, background task logs, and subagent state
             to the local disk mtfdash node registry (logs/nodes/).
             Intercepts pendinginjectedcommand tasks dispatched over mtfdash.
Lineage:     irislime / fekerr-dev Integration
Updated:     20260718 (fekerr & Antigravity)
"""

import os
import sys
import json
import time
import socket
import subprocess
import argparse
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
WORKSPACE_ROOT = SCRIPT_DIR.parent
NODES_DIR = WORKSPACE_ROOT / "logs" / "nodes"

def get_agy_node_id() -> str:
    hostname = socket.gethostname().lower().replace("-", "_")
    pid = os.getpid()
    return f"agy_core_{hostname}_{pid}"

def inspect_agy_telemetry() -> dict:
    """Inspects AGY workspace state, task logs, and conversation metadata."""
    tasks_dir = WORKSPACE_ROOT / ".system_generated" / "tasks"
    active_tasks = []
    if tasks_dir.is_dir():
        for tfile in tasks_dir.glob("*.log"):
            active_tasks.append(tfile.stem)

    # Inspect active conversation context if present
    conv_id = os.environ.get("AGY_CONVERSATION_ID", "2801f589-4ece-405e-9e12-0def6a935363")
    
    return {
        "agy_status": "ACTIVE" if active_tasks else "IDLE",
        "conversation_id": conv_id,
        "active_task_count": len(active_tasks),
        "active_tasks": active_tasks[:5],
    }

def update_agy_heartbeat(status: str = "active", narrative: str = "AGY core listening on mtfdash mesh"):
    NODES_DIR.mkdir(parents=True, exist_ok=True)
    node_id = get_agy_node_id()
    file_path = NODES_DIR / f"node_{node_id}.json"
    
    pending_cmd = None
    if file_path.is_file():
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                existing = json.load(f)
                pending_cmd = existing.get("pendinginjectedcommand")
        except Exception:
            pass

    telemetry = inspect_agy_telemetry()

    payload = {
        "node_id": node_id,
        "pid": os.getpid(),
        "node_type": "agy_core",
        "hostname": socket.gethostname(),
        "status": status,
        "last_seen": time.time(),
        "last_seen_iso": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "agy_telemetry": telemetry,
        "narrative": f"[v1.8.6] {narrative}",
        "pendinginjectedcommand": pending_cmd,
    }
    
    tmp_path = file_path.with_suffix(".tmp")
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
    tmp_path.replace(file_path)
    return payload

def poll_and_execute_injected_commands():
    """Polls mtfdash node registry for pendinginjectedcommand tasks."""
    node_id = get_agy_node_id()
    file_path = NODES_DIR / f"node_{node_id}.json"
    
    if not file_path.is_file():
        update_agy_heartbeat()
        return

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        cmd = data.get("pendinginjectedcommand")
        if cmd:
            print(f"[*] AGY Bridge Intercepted mtfdash Command: {cmd}")
            # Execute command or task payload
            run_cmd = f"agy run --task \"{cmd}\"" if not cmd.startswith("agy") else cmd
            print(f"[*] Executing AGY Task: {run_cmd}")
            
            # Clear pending command and update narrative
            data["pendinginjectedcommand"] = None
            data["narrative"] = f"[v1.8.6] AGY executed task: {cmd}"
            data["last_seen"] = time.time()
            
            tmp_path = file_path.with_suffix(".tmp")
            with open(tmp_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
            tmp_path.replace(file_path)

            # Spawn command execution
            subprocess.run(run_cmd, shell=True)
    except Exception as e:
        print(f"[!] Error in AGY mtfdash bridge: {e}", file=sys.stderr)

def main():
    parser = argparse.ArgumentParser(description="AGY mtfdash Mesh Bridge")
    parser.add_argument("--daemon", action="store_true", help="Run in continuous polling loop")
    parser.add_argument("--interval", type=int, default=5, help="Polling interval in seconds")
    args = parser.parse_args()

    print(f"[+] Starting AGY mtfdash bridge on node '{get_agy_node_id()}'...")
    update_agy_heartbeat(narrative="AGY core mesh node online")

    if args.daemon:
        try:
            while True:
                poll_and_execute_injected_commands()
                update_agy_heartbeat()
                time.sleep(args.interval)
        except KeyboardInterrupt:
            print("\n[*] Stopping AGY mtfdash bridge daemon.")
    else:
        poll_and_execute_injected_commands()
        print("[+] AGY mtfdash bridge check completed.")

if __name__ == "__main__":
    main()
