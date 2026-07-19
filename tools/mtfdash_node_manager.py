#!/usr/bin/env python3
"""
Path:        tools/mtfdash_node_manager.py
Purpose:     WSL / Win11 mtfdash local disk-based node discovery, heartbeat registry,
             mesh issue logging & broadcasting, and interprocess command mesh.
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
MESH_ISSUES_FILE = NODES_DIR / "mesh_issues.jsonl"

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

def get_tree_context() -> dict:
    """Inspects host computer name, WSL distro tree, and git working directory branch/sha."""
    is_wsl = "wsl" in platform.release().lower() or "microsoft" in platform.release().lower()
    distro = os.environ.get("WSL_DISTRO_NAME", "Host Win11" if not is_wsl else "Ubuntu-WSL")
    host_computer = socket.gethostname()
    
    branch = "unknown"
    sha = "unknown"
    try:
        res_b = subprocess.run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=WORKSPACE_ROOT, capture_output=True, text=True)
        if res_b.returncode == 0:
            branch = res_b.stdout.strip()
        res_s = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=WORKSPACE_ROOT, capture_output=True, text=True)
        if res_s.returncode == 0:
            sha = res_s.stdout.strip()
    except Exception:
        pass

    unc_path = str(WORKSPACE_ROOT)
    if is_wsl:
        try:
            res_u = subprocess.run(["wslpath", "-w", str(WORKSPACE_ROOT)], capture_output=True, text=True)
            if res_u.returncode == 0:
                unc_path = res_u.stdout.strip()
        except Exception:
            pass

    return {
        "host_computer": host_computer,
        "subsystem_type": "WSL2 Guest" if is_wsl else "Win11 Host",
        "distro_name": distro,
        "workspace_path": str(WORKSPACE_ROOT),
        "windows_unc_path": unc_path,
        "git_branch": branch,
        "git_sha": sha,
    }

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

def log_and_broadcast_issue(node_id: str = None, message: str = "", severity: str = "ERROR", broadcast_mesh: bool = True) -> dict:
    """
    Logs an mtfdash issue to logs/nodes/mesh_issues.jsonl AND broadcasts it
    across active node registry files in the mesh.
    """
    ensure_nodes_dir()
    if not node_id:
        node_id = get_node_identity()

    now_ts = time.time()
    iso_ts = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    
    issue_record = {
        "timestamp": now_ts,
        "timestamp_iso": iso_ts,
        "node_id": node_id,
        "severity": severity.upper(),
        "message": message,
    }

    # 1. Append to persistent mesh_issues.jsonl
    try:
        with open(MESH_ISSUES_FILE, "a", encoding="utf-8") as f:
            f.write(json.dumps(issue_record) + "\n")
    except Exception as e:
        print(f"[!] Failed to write to mesh_issues.jsonl: {e}", file=sys.stderr)

    # 2. Update local node file state
    file_path = NODES_DIR / f"node_{node_id}.json"
    if file_path.is_file():
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            
            data["status"] = "ISSUE"
            data["narrative"] = f"[BROADCAST {severity.upper()}] {message}"
            data["last_seen"] = now_ts
            data["last_seen_iso"] = iso_ts
            
            recent = data.get("recent_issues", [])
            recent.insert(0, issue_record)
            data["recent_issues"] = recent[:10]
            
            atomic_write_json(file_path, data)
        except Exception as e:
            print(f"[!] Failed to update node state for issue: {e}", file=sys.stderr)

    # 3. Broadcast alert command payload to active nodes if requested
    if broadcast_mesh:
        try:
            active_mesh = discover_nodes()["active"]
            alert_cmd = f"mesh_alert:{severity.lower()}:{message}"
            for target_nid in active_mesh:
                if target_nid != node_id:
                    _inject_command(target_nid, alert_cmd)
        except Exception:
            pass

    print(f"[!] [BROADCAST {severity.upper()}] Node '{node_id}': {message}", file=sys.stderr)
    return issue_record

def register_heartbeat(node_id: str = None, status: str = "active", narrative: str = "Node online"):
    """Registers or updates the local node heartbeat file in logs/nodes/."""
    ensure_nodes_dir()
    if not node_id:
        node_id = get_node_identity()
    
    file_path = NODES_DIR / f"node_{node_id}.json"
    
    # Retain existing pending command and recent issues if present
    pending_cmd = None
    recent_issues = []
    if file_path.is_file():
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                existing = json.load(f)
                pending_cmd = existing.get("pendinginjectedcommand")
                recent_issues = existing.get("recent_issues", [])
        except Exception:
            pass

    payload = {
        "node_id": node_id,
        "pid": os.getpid(),
        "hostname": socket.gethostname(),
        "status": status,
        "last_seen": time.time(),
        "last_seen_iso": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "tree_context": get_tree_context(),
        "capabilities": get_system_capabilities(),
        "narrative": f"[v1.8.6] {narrative}",
        "recent_issues": recent_issues[:10],
        "pendinginjectedcommand": pending_cmd,
    }
    
    atomic_write_json(file_path, payload)
    return payload

def discover_nodes() -> dict:
    """
    Scans logs/nodes/*.json and returns active, stale, and corrupt nodes.
    Prevents discovery errors ('v' view members crash prevention).
    """
    ensure_nodes_dir()
    active_nodes = {}
    stale_nodes = {}
    corrupt_nodes = {}
    now = time.time()
    
    for fpath in NODES_DIR.glob("node_*.json"):
        try:
            with open(fpath, "r", encoding="utf-8") as f:
                data = json.load(f)
            
            if not isinstance(data, dict):
                corrupt_nodes[fpath.name] = "Content is not a JSON object"
                continue

            node_id = data.get("node_id", fpath.stem.replace("node_", ""))
            last_seen = data.get("last_seen", 0)
            
            # Ensure safe fallback data structures
            if "tree_context" not in data or not isinstance(data["tree_context"], dict):
                data["tree_context"] = {}
            if "capabilities" not in data or not isinstance(data["capabilities"], dict):
                data["capabilities"] = {}

            if (now - last_seen) <= HEARTBEAT_TIMEOUT_SEC:
                active_nodes[node_id] = data
            else:
                stale_nodes[node_id] = data
        except Exception as e:
            corrupt_nodes[fpath.name] = str(e)
            continue
            
    return {"active": active_nodes, "stale": stale_nodes, "corrupt": corrupt_nodes}

def get_recent_broadcast_issues(limit: int = 5) -> list:
    """Reads the last N broadcasted mesh issues from logs/nodes/mesh_issues.jsonl."""
    if not MESH_ISSUES_FILE.is_file():
        return []
    records = []
    try:
        with open(MESH_ISSUES_FILE, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        records.append(json.loads(line))
                    except Exception:
                        continue
    except Exception:
        pass
    return records[-limit:]

def send_command(target_node_id: str, command: str) -> bool:
    """Injects a command payload into a target node's inbox on disk."""
    ensure_nodes_dir()
    
    if target_node_id == "all":
        nodes = discover_nodes()["active"]
        if not nodes:
            log_and_broadcast_issue("system", "send-cmd failed: No active nodes discovered.", severity="WARNING")
            return False
        for nid in nodes:
            _inject_command(nid, command)
        print(f"[+] Command dispatched to {len(nodes)} active node(s).")
        return True
    else:
        file_path = NODES_DIR / f"node_{target_node_id}.json"
        if not file_path.is_file():
            log_and_broadcast_issue("system", f"send-cmd failed: Target node '{target_node_id}' not found.", severity="WARNING")
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
            log_and_broadcast_issue(node_id, f"Failed to inject command '{command}': {e}", severity="ERROR")

def delegate_rclone_operation(rclone_args: str) -> bool:
    """Submits an rclone operation request from a WSL node to the Win11 host node."""
    ensure_nodes_dir()
    nodes = discover_nodes()["active"]
    host_node_id = None
    for nid, ndata in nodes.items():
        if "win11" in nid.lower() or "win11" in ndata.get("capabilities", {}).get("os", "").lower():
            host_node_id = nid
            break
            
    if not host_node_id:
        log_and_broadcast_issue("wsl_node", "No active Win11 host node found to service rclone delegation. Falling back to local.", severity="WARNING")
        bridge_script = WORKSPACE_ROOT / "tools" / "wsl_rclone_bridge.py"
        if bridge_script.is_file():
            res = subprocess.run([sys.executable, str(bridge_script)] + rclone_args.split())
            return res.returncode == 0
        return False
        
    cmd_payload = f"rclone:{rclone_args}"
    _inject_command(host_node_id, cmd_payload)
    print(f"[+] Rclone operation '{rclone_args}' delegated to Win11 host node '{host_node_id}'.")
    return True

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
                
                if cmd.startswith("mesh_alert:"):
                    parts = cmd.split(":", 2)
                    sev = parts[1] if len(parts) > 1 else "info"
                    msg = parts[2] if len(parts) > 2 else cmd
                    print(f"[!] [MESH ALERT RECEIVED] [{sev.upper()}] {msg}", file=sys.stderr)
                    data["narrative"] = f"[v1.8.6] Received Mesh Alert: {msg}"
                elif cmd.startswith("rclone:"):
                    r_op = cmd.split("rclone:", 1)[1].strip()
                    print(f"[*] servicing delegated rclone request on host: {r_op}")
                    bridge_script = WORKSPACE_ROOT / "tools" / "wsl_rclone_bridge.py"
                    if bridge_script.is_file():
                        subprocess.run([sys.executable, str(bridge_script)] + r_op.split())
                    data["narrative"] = f"[v1.8.6] Serviced rclone request: {r_op}"
                else:
                    data["narrative"] = f"[v1.8.6] Executed command: {cmd}"

                data["pendinginjectedcommand"] = None
                data["last_seen"] = time.time()
                atomic_write_json(file_path, data)
        except Exception as e:
            log_and_broadcast_issue(node_id, f"Error processing inbox: {e}", severity="ERROR")
            
    return executed

def print_mesh_matrix():
    """
    Prints an expanded, multi-line dashboard matrix of discovered nodes and logged issues.
    Fulfills 'v' view members error recovery and 'more lines need to be on the dashboard'.
    """
    discovery = discover_nodes()
    active = discovery["active"]
    stale = discovery["stale"]
    corrupt = discovery.get("corrupt", {})
    recent_issues = get_recent_broadcast_issues(limit=5)
    
    print("=" * 80)
    print("           MTFDASH SYSTEM MEMBERS & LOCAL DISK NODE DISCOVERY MATRIX        ")
    print("=" * 80)
    print(f" Registry Directory : {NODES_DIR}")
    print(f" Active Nodes       : {len(active)} | Stale Nodes: {len(stale)} | Corrupt Files: {len(corrupt)}")
    print(f" Mesh Issues Logged : {len(recent_issues)} recent broadcast record(s)")
    print("=" * 80)
    
    # 1. Active Nodes Section (Expanded Lines)
    print("\n--- ACTIVE MESH MEMBERS (ONLINE) ---")
    if not active:
        print(" [!] No active nodes detected in the last 15 seconds.")
    else:
        for nid, ndata in active.items():
            status = ndata.get("status", "ACTIVE").upper()
            status_flag = f"[{status}]"
            pid = ndata.get("pid", "N/A")
            node_type = ndata.get("node_type", "subsystem_node")
            
            tree = ndata.get("tree_context", {})
            host_comp = tree.get("host_computer", ndata.get("hostname", "Unknown Host"))
            distro = tree.get("distro_name", "Win11")
            subsys_id = tree.get("subsystem_id", "")
            subsys_str = f"{distro} (ID {subsys_id})" if subsys_id else distro
            branch = tree.get("git_branch", "main")
            sha = tree.get("git_sha", "")
            workspace = tree.get("workspace_path", "")
            unc_path = tree.get("windows_unc_path", "")
            
            caps = ndata.get("capabilities", {})
            os_name = caps.get("os", "Unknown OS")
            py_ver = caps.get("python_version", "N/A")
            venv = caps.get("virtual_env") or "None"
            oneapi = "Active" if caps.get("oneapi_active") else "Inactive"
            openvino = "Active" if caps.get("openvino_active") else "Inactive"
            rclone = "Available" if caps.get("rclone_available") else "Missing"
            
            seen = ndata.get("last_seen_iso", "N/A")
            narrative = ndata.get("narrative", "")
            cmd = ndata.get("pendinginjectedcommand") or "<none>"
            issues = ndata.get("recent_issues", [])

            print(f" * Node ID      : {nid} {status_flag} (Type: {node_type} | PID: {pid})")
            print(f"   Host/Tree    : [{host_comp}] <---> [{subsys_str}] (Branch: {branch}@{sha})")
            print(f"   UNC Path     : {unc_path}")
            print(f"   Local Path   : {workspace}")
            print(f"   Capabilities : OS={os_name} | Python={py_ver} | Venv={venv}")
            print(f"   Accelerators : oneAPI={oneapi} | OpenVINO={openvino} | Rclone={rclone}")
            print(f"   Heartbeat    : Last Seen={seen} | Pending Cmd={cmd}")
            print(f"   Narrative    : {narrative}")
            if issues:
                latest_issue = issues[0]
                print(f"   Active Issue : [{latest_issue.get('severity')}] {latest_issue.get('message')}")
            print("-" * 80)

    # 2. Stale Nodes Section
    print("\n--- STALE / OFFLINE MESH MEMBERS ---")
    if not stale:
        print(" [i] No stale nodes registered.")
    else:
        for nid, ndata in stale.items():
            tree = ndata.get("tree_context", {})
            host_comp = tree.get("host_computer", ndata.get("hostname", "Unknown Host"))
            distro = tree.get("distro_name", "Unknown")
            seen = ndata.get("last_seen_iso", "N/A")
            narrative = ndata.get("narrative", "")
            print(f" - Stale Node   : {nid}")
            print(f"   Host/Distro  : [{host_comp}] <---> [{distro}]")
            print(f"   Last Seen    : {seen}")
            print(f"   Last Status  : {narrative}")
            print("   " + "." * 76)

    # 3. Corrupt Registry Files (Error Recovery)
    if corrupt:
        print("\n--- CORRUPT REGISTRY FILES (AUTO-RECOVERED) ---")
        for fname, err in corrupt.items():
            print(f" [!] File: {fname} | Error: {err}")

    # 4. Broadcasted Mesh Issues Log Section
    print("\n--- BROADCASTED MESH ISSUES & LOGS ---")
    if not recent_issues:
        print(" [✓] No mesh issues logged.")
    else:
        for r in recent_issues:
            print(f" [!] [{r.get('timestamp_iso')}] [{r.get('severity')}] Node '{r.get('node_id')}': {r.get('message')}")
    print("=" * 80)

def main():
    parser = argparse.ArgumentParser(description="mtfdash Local Disk Node Discovery & IPC Engine")
    subparsers = parser.add_subparsers(dest="subcommand")
    
    # register
    reg_parser = subparsers.add_parser("register", help="Register/touch node heartbeat")
    reg_parser.add_argument("--node-id", default=None, help="Custom node identifier")
    reg_parser.add_argument("--status", default="active", help="Node operational status")
    reg_parser.add_argument("--narrative", default="Node online", help="Narrative log entry")
    
    # discover
    subparsers.add_parser("discover", help="Discover active nodes and print expanded mesh matrix")
    
    # log-issue
    issue_parser = subparsers.add_parser("log-issue", help="Log and broadcast an issue across mtfdash mesh")
    issue_parser.add_argument("message", help="Issue description message")
    issue_parser.add_argument("--node-id", default=None, help="Node ID reporting the issue")
    issue_parser.add_argument("--severity", default="ERROR", help="Severity level (ERROR, WARNING, CRITICAL)")

    # send-cmd
    send_parser = subparsers.add_parser("send-cmd", help="Send a command to a target node")
    send_parser.add_argument("target", help="Target node ID or 'all'")
    send_parser.add_argument("command", help="Command payload string")
    
    # process-inbox
    subparsers.add_parser("process-inbox", help="Check and execute pending commands for this node")
    
    # rclone-delegate
    rcl_parser = subparsers.add_parser("rclone-delegate", help="Delegate rclone operation to active Win11 host node")
    rcl_parser.add_argument("rclone_args", help="Rclone command arguments string (e.g. 'copyto file.zip gdrive:path')")
    
    args = parser.parse_args()
    
    if args.subcommand == "register":
        payload = register_heartbeat(args.node_id, args.status, args.narrative)
        print(f"[+] Heartbeat updated for node '{payload['node_id']}'.")
    elif args.subcommand == "discover" or not args.subcommand:
        register_heartbeat(narrative="Discovery matrix view pass")
        print_mesh_matrix()
    elif args.subcommand == "log-issue":
        log_and_broadcast_issue(args.node_id, args.message, args.severity)
    elif args.subcommand == "send-cmd":
        send_command(args.target, args.command)
    elif args.subcommand == "process-inbox":
        process_inbox()
    elif args.subcommand == "rclone-delegate":
        delegate_rclone_operation(args.rclone_args)

if __name__ == "__main__":
    main()
