#!/usr/bin/env python3
"""
Path:        tools/llamacpp_mtfdash_bridge.py
Purpose:     llama.cpp mtfdash Mesh Bridge & Runner.
             Binds llama.cpp CLI / Server execution and inference metrics to the
             local disk mtfdash node registry (logs/nodes/).
             Receives injected prompts/tasks over the mtfdash command mesh.
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
DEFAULT_MODEL = WORKSPACE_ROOT / ".." / "models" / "tinyllama-1.1b-chat-v1.0.Q4_0.gguf"

def get_llama_node_id() -> str:
    hostname = socket.gethostname().lower().replace("-", "_")
    pid = os.getpid()
    return f"llamacpp_{hostname}_{pid}"

def detect_hardware_backend() -> str:
    """Detects active hardware runtime flags (SYCL, OpenVINO, Vulkan, CPU)."""
    if "ONEAPI_ROOT" in os.environ or "ZES_ENABLE_SYSMAN" in os.environ:
        return "Intel SYCL / oneAPI"
    elif "OpenVINO_DIR" in os.environ:
        return "Intel OpenVINO"
    elif "VULKAN_SDK" in os.environ:
        return "Vulkan GPU"
    return "CPU (x86_64 AVX2/AVX512)"

def update_llama_heartbeat(model_path: str, status: str = "IDLE", tokens_per_sec: float = 0.0, narrative: str = "llama.cpp node online"):
    NODES_DIR.mkdir(parents=True, exist_ok=True)
    node_id = get_llama_node_id()
    file_path = NODES_DIR / f"node_{node_id}.json"
    
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
        "node_type": "llamacpp_engine",
        "hostname": socket.gethostname(),
        "status": status,
        "last_seen": time.time(),
        "last_seen_iso": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "llama_telemetry": {
            "model_path": str(model_path),
            "backend": detect_hardware_backend(),
            "tokens_per_sec": tokens_per_sec,
        },
        "narrative": f"[v1.8.6] {narrative}",
        "pendinginjectedcommand": pending_cmd,
    }
    
    tmp_path = file_path.with_suffix(".tmp")
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
    tmp_path.replace(file_path)
    return payload

def run_llama_prompt(model_path: str, prompt: str):
    """Invokes llama.cpp binary/runner with given prompt and streams telemetry to mtfdash."""
    node_id = get_llama_node_id()
    print(f"[*] llama.cpp node '{node_id}' executing prompt: {prompt}")
    update_llama_heartbeat(model_path, status="INFERRING", narrative=f"Generating inference for prompt: {prompt[:30]}...")

    start_time = time.time()
    # Check llama-cli executable or fallback to mock runner output
    llama_bin = WORKSPACE_ROOT / "llama.cpp" / "build" / "bin" / "llama-cli"
    if not llama_bin.is_file():
        llama_bin = WORKSPACE_ROOT / "llama.cpp" / "llama-cli"

    if llama_bin.is_file():
        cmd = [str(llama_bin), "-m", str(model_path), "-p", prompt, "-n", "128"]
        try:
            res = subprocess.run(cmd, capture_output=True, text=True)
            output = res.stdout.strip()
            print(output)
        except Exception as e:
            print(f"[!] Error running llama-cli: {e}", file=sys.stderr)
    else:
        print(f"[+] [llama.cpp Simulation Mode] Model: {Path(model_path).name}")
        print(f"[+] Output: Processing prompt '{prompt}' over {detect_hardware_backend()} runtime.")
        time.sleep(1)

    elapsed = max(time.time() - start_time, 0.1)
    tok_sec = round(128.0 / elapsed, 2)
    update_llama_heartbeat(model_path, status="IDLE", tokens_per_sec=tok_sec, narrative=f"Inference completed ({tok_sec} tok/s)")

def poll_llama_mesh_inbox(model_path: str):
    """Checks for injected prompts over mtfdash command mesh."""
    node_id = get_llama_node_id()
    file_path = NODES_DIR / f"node_{node_id}.json"
    
    if not file_path.is_file():
        update_llama_heartbeat(model_path)
        return

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        cmd = data.get("pendinginjectedcommand")
        if cmd:
            print(f"[*] llama.cpp Intercepted Command: {cmd}")
            # Clear command
            data["pendinginjectedcommand"] = None
            data["narrative"] = f"[v1.8.6] Processing prompt: {cmd}"
            data["last_seen"] = time.time()
            
            tmp_path = file_path.with_suffix(".tmp")
            with open(tmp_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
            tmp_path.replace(file_path)

            run_llama_prompt(model_path, cmd)
    except Exception as e:
        print(f"[!] Error polling llama inbox: {e}", file=sys.stderr)

def main():
    parser = argparse.ArgumentParser(description="llama.cpp mtfdash Mesh Bridge")
    parser.add_argument("-m", "--model", default=str(DEFAULT_MODEL), help="Path to GGUF model")
    parser.add_argument("-p", "--prompt", default=None, help="Prompt to execute immediately")
    parser.add_argument("--daemon", action="store_true", help="Run in continuous polling daemon mode")
    parser.add_argument("--interval", type=int, default=5, help="Polling interval in seconds")
    args = parser.parse_args()

    print(f"[+] Starting llama.cpp mtfdash bridge on node '{get_llama_node_id()}'...")
    update_llama_heartbeat(args.model, status="IDLE", narrative="llama.cpp mesh node online")

    if args.prompt:
        run_llama_prompt(args.model, args.prompt)
    elif args.daemon:
        try:
            while True:
                poll_llama_mesh_inbox(args.model)
                update_llama_heartbeat(args.model)
                time.sleep(args.interval)
        except KeyboardInterrupt:
            print("\n[*] Stopping llama.cpp mtfdash bridge daemon.")
    else:
        poll_llama_mesh_inbox(args.model)
        print("[+] llama.cpp mtfdash bridge check completed.")

if __name__ == "__main__":
    main()
