#!/usr/bin/env python3
"""
Path:        tools/mtfdash_node_manager.py
Purpose:     WSL / Win11 mtfdash local disk-based node discovery, heartbeat registry,
             and interprocess command-passing mesh engine.
Lineage:     irislime / fekerr-dev Architecture
Updated:     20260718 (fekerr & Antigravity)
"""

import os
import sys
import json
import time
import glob
import platform
import socket
import subprocess
import argparse
from pathlib import Path

# Resolve root workspace path
SCRIPT_DIR = Path(__file__).resolve().parent
WORKSPACE_ROOT = SCRIPT_DIR.parent
NODES_DIR = WORKSPACE_ROOT / "logs" / "nodes"

# Heartbeat timeout threshold in seconds
HEARTBEAT_TIMEOUT_SEC = 15

def get_node_identity() -> str:
    """Returns a unique identifier for the running node session."""
    hostname = socket.gethostname().lower().replace("-", "_")
    is_wsl = "wsl" in platform.release().lower() or "microsoft" in platform.release().lower()
    prefix = "wsl_ubuntu" if is_wsl else "win11_host"
    pid = os.getpid()
    return f"{prefix}_{hostname}_{pid}"

def ensure_nodes_dir():
    """Ensures the logs/nodes directory exists."""
    NODES_DIR.mkdir(parents=True, exist_ok=True)

def get_system_capabilities() -> dict:
    """Gathers local subsystem capabilities and state metrics."""
    is_wsl = "wsl" in platform.release().lower() or "microsoft" in platform.release().lower()
    
    # Check Python virtualenv
    venv = os.environ.get("VIRTUAL_ENV", "")
    has_venv = bool(venv)
    
    # Check Intel oneAPI / OpenVINO
    has_oneapi = os.path.exists("/opt/intel/oneapi") or "ONEAPI_ROOT" in os.environ
    has_openvino = "OpenVINO_DIR" in os.environ or os.path.exists("/usr/lib/x86_64-linux-gnu/cmake/openvino")
    
    # Check rclone
    rclone_avail = shutil_which("rclone") or os.path.exists("/mnt/c/Users/feker/AppData/Local/Microsoft/WinGet/Links/rclone.exe")
    
    return {
        "os": "WSL2 Ubuntu 26.04" if is_wsl else f"Windows 11 ({platform.system()})",
        "python_version": platform.python_version(),
        "virtual_env": venv if has_venv else None,
        "oneapi_active": has_oneapi,
        "openvino_active": has_openvino,
        "rclone_available": bool(rclone_avail),
    }

def shutil_which(cmd: str):
    """Helper to check command presence without external imports."""
    for p in os.environ.get("PATH", "").split(os.pathsep):
        candidate = Path(p) / cmd
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
    return None

def atomic_write_json(file_path: Path, data: dict):
    """Writes JSON data atomically using a temporary file to avoid race conditions."""
    tmp_path = file_path.with_suffix(".tmp")
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    tmp_path.replace(file_path)

def register_heartbeat(node_id: str = None, status: str = "active", narrative: str = "Node online"):
    """Registers or updates the local node heartbeat file in logs/nodes/."""
    ensure_nodes_dir()
    if not node_id:
        node_id = get_node_identity()
    
    file_path = NODES_DIR / f"node_{node_id}.json"
    
    # Retain existing pending command if present
    pending_cmd = None
    if file_path.is_file():
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                existing = json.load(f)
                pending_cmd = existing.get("pendinginjectedcommand")
        except Exception:
            pass

    payload = {
        "node_id": node_id,
        "pid": os.getpid(),
        "hostname": socket.gethostname(),
        "status": status,
        "last_seen": time.time(),
        "last_seen_iso": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "capabilities": get_system_capabilities(),
        "narrative": f"[v1.8.6] {narrative}",
        "pendinginjectedcommand": pending_cmd,
    }
    
    atomic_write_json(file_path, payload)
    return payload

def discover_nodes() -> dict:
    """Scans logs/nodes/*.json and returns active vs stale nodes on the host."""
    ensure_nodes_dir()
    active_nodes = {}
    stale_nodes = {}
    now = time.time()
    
    for fpath in NODES_DIR.glob("node_*.json"):
        try:
            with open(fpath, "r", encoding="utf-8") as f:
                data = json.load(f)
            node_id = data.get("node_id", fpath.stem.replace("node_", ""))
            last_seen = data.get("last_seen", 0)
            
            if (now - last_seen) <= HEARTBEAT_TIMEOUT_SEC:
                active_nodes[node_id] = data
            else:
                stale_nodes[node_id] = data
        except Exception:
            continue
            
    return {"active": active_nodes, "stale": stale_nodes}

def send_command(target_node_id: str, command: str) -> bool:
    """Injects a command payload into a target node's inbox on disk."""
    ensure_nodes_dir()
    
    # If targeting all active nodes or specific target
    if target_node_id == "all":
        nodes = discover_nodes()["active"]
        if not nodes:
            print("[!] No active nodes discovered to send command.", file=sys.stderr)
            return False
        for nid, node_data in nodes.items():
            _inject_command(nid, command)
        print(f"[+] Command dispatched to {len(nodes)} active node(s).")
        return True
    else:
        file_path = NODES_DIR / f"node_{target_node_id}.json"
        if not file_path.is_file():
            print(f"[!] Target node '{target_node_id}' not found in registry.", file=sys.stderr)
            return False
        _inject_command(target_node_id, command)
        print(f"[+] Command dispatched to target node '{target_node_id}'.")
        return True

def _inject_command(node_id: str, command: str):
    file_path = NODES_DIR / f"node_{node_id}.json"
    if file_path.is_file():
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            data["pendinginjectedcommand"] = command.lower().strip()
            data["last_seen"] = time.time()
            atomic_write_json(file_path, data)
        except Exception as e:
            print(f"[!] Failed to inject command to {node_id}: {e}", file=sys.stderr)

def process_inbox(node_id: str = None) -> list:
    """Reads and clears pending injected commands for this node."""
    ensure_nodes_dir()
    if not node_id:
        node_id = get_node_identity()
    file_path = NODES_DIR / f"node_{node_id}.json"
    
    executed = []
    if file_path.is_file():
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            cmd = data.get("pendinginjectedcommand")
            if cmd:
                print(f"[*] Node '{node_id}' processing command: {cmd}")
                executed.append(cmd)
                # Clear command after reading
                data["pendinginjectedcommand"] = None
                data["narrative"] = f"[v1.8.6] Executed command: {cmd}"
                data["last_seen"] = time.time()
                atomic_write_json(file_path, data)
        except Exception as e:
            print(f"[!] Error processing inbox for {node_id}: {e}", file=sys.stderr)
            
    return executed

def print_mesh_matrix():
    """Prints a formatted human-readable dashboard matrix of discovered nodes."""
    discovery = discover_nodes()
    active = discovery["active"]
    stale = discovery["stale"]
    
    print("=" * 72)
    print("               MTFDASH LOCAL DISK NODE DISCOVERY MATRIX             ")
    print("=" * 72)
    print(f" Registry Directory: {NODES_DIR}")
    print(f" Active Nodes: {len(active)} | Stale Nodes: {len(stale)}")
    print("-" * 72)
    
    if not active:
        print(" [!] No active nodes detected in the last 15 seconds.")
    else:
        for nid, ndata in active.items():
            caps = ndata.get("capabilities", {})
            os_name = caps.get("os", "Unknown OS")
            seen = ndata.get("last_seen_iso", "N/A")
            narrative = ndata.get("narrative", "")
            cmd = ndata.get("pendinginjectedcommand") or "<none>"
            print(f" * Node ID:    {nid}")
            print(f"   OS/Target:  {os_name} (PID {ndata.get('pid')})")
            print(f"   Last Seen:  {seen}")
            print(f"   Pending Cmd:{cmd}")
            print(f"   Narrative:  {narrative}")
            print("-" * 72)

def main():
    parser = argparse.ArgumentParser(description="mtfdash Local Disk Node Discovery & IPC Engine")
    subparsers = parser.add_subparsers(dest="subcommand")
    
    # register
    reg_parser = subparsers.add_parser("register", help="Register/touch node heartbeat")
    reg_parser.add_argument("--node-id", default=None, help="Custom node identifier")
    reg_parser.add_argument("--status", default="active", help="Node operational status")
    reg_parser.add_argument("--narrative", default="Node online", help="Narrative log entry")
    
    # discover
    subparsers.add_parser("discover", help="Discover active nodes and print mesh matrix")
    
    # send-cmd
    send_parser = subparsers.add_parser("send-cmd", help="Send a command to a target node")
    send_parser.add_argument("target", help="Target node ID or 'all'")
    send_parser.add_argument("command", help="Command payload string")
    
    # process-inbox
    subparsers.add_parser("process-inbox", help="Check and execute pending commands for this node")
    
    args = parser.parse_args()
    
    if args.subcommand == "register":
        payload = register_heartbeat(args.node_id, args.status, args.narrative)
        print(f"[+] Heartbeat updated for node '{payload['node_id']}'.")
    elif args.subcommand == "discover" or not args.subcommand:
        # Default to registering self and printing matrix
        register_heartbeat(narrative="Discovery matrix view pass")
        print_mesh_matrix()
    elif args.subcommand == "send-cmd":
        send_command(args.target, args.command)
    elif args.subcommand == "process-inbox":
        process_inbox()

if __name__ == "__main__":
    main()
