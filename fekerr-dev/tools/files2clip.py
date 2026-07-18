#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tools/files2clip.py
# Purpose:      Pack multi-target workspace assets with TOML-driven controls.
# Type:         Executable / TOML Config-Aware Context Packer
# Attribution:  fekerr & Gemini (20260715 TOML Integration Pass)
# ==============================================================================
import os
import sys
import glob
import subprocess
import hashlib
import argparse

# Try importing the built-in TOML parser (available in Python 3.11+)
try:
    import tomllib
except ImportError:
    tomllib = None

# Fallback/Default configurations in case TOML is absent
DEFAULT_CONFIG = {
    "max_truncate_size": 1024 * 1024,
    "require_git_tracking": False,
    "default_targets": ["."],
    "wsl_clip_path": "/mnt/c/Windows/System32/clip.exe"
}

def load_toml_config():
    """Locates and parses the nearest files2clip.toml file."""
    script_dir = os.path.dirname(os.path.realpath(__file__))
    candidates = [
        os.path.join(os.getcwd(), "files2clip.toml"),
        os.path.join(script_dir, "files2clip.toml"),
        os.path.expanduser("~/.config/files2clip/files2clip.toml")
    ]
    
    for path in candidates:
        if os.path.exists(path):
            if tomllib is None:
                print(f"[!] Warning: TOML parsing library unavailable. Using defaults.", file=sys.stderr)
                return DEFAULT_CONFIG
            try:
                with open(path, "rb") as f:
                    data = tomllib.load(f)
                
                # Flatten the TOML block structure into a clean dict
                config = DEFAULT_CONFIG.copy()
                if "limits" in data:
                    config["max_truncate_size"] = data["limits"].get("max_truncate_size", config["max_truncate_size"])
                if "rules" in data:
                    config["require_git_tracking"] = data["rules"].get("require_git_tracking", config["require_git_tracking"])
                    config["default_targets"] = data["rules"].get("default_targets", config["default_targets"])
                if "paths" in data:
                    config["wsl_clip_path"] = data["paths"].get("wsl_clip_path", config["wsl_clip_path"])
                return config
            except Exception as e:
                print(f"[-] Error parsing TOML config at {path}: {e}", file=sys.stderr)
                
    return DEFAULT_CONFIG

def get_tracked_files():
    """Parses the git index to enforce out-of-tree and workspace asset tracking."""
    try:
        cmd = ["git", "ls-files", "--cached", "--others", "--exclude-standard"]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return set(result.stdout.splitlines())
    except subprocess.CalledProcessError:
        return None

def generate_file_stream(file_path, max_size):
    """Wraps target text asset contents into symmetrical, tail-scrolling blocks."""
    try:
        size = os.path.getsize(file_path)
        with open(file_path, 'r', errors='ignore') as f:
            content = f.read(max_size)
        
        clean_content = content.replace('\r\n', '\n')
        sha256 = hashlib.sha256(clean_content.encode('utf-8')).hexdigest()
        
        header = f"--- BEGIN FILE: {file_path} | Size: {size} bytes | SHA256: {sha256} ---\n"
        footer = f"\n--- END FILE: {file_path} ---\n"
        return f"{header}{clean_content}{footer}"
    except Exception as e:
        return f"\n[!] Error generating stream node for {file_path}: {e}\n"

def resolve_targets(targets, require_git_tracking):
    """Resolves arbitrary targets, directories, and wildcards."""
    allowed_files = get_tracked_files() if require_git_tracking else None
    resolved_files = []

    for target in targets:
        globbed = glob.glob(target, recursive=True)
        if not globbed:
            if not os.path.exists(target):
                print(f"[!] Warning: Target '{target}' matched no files or paths.", file=sys.stderr)
            continue

        for path in globbed:
            norm_path = os.path.normpath(path).replace('\\', '/')
            
            if os.path.isdir(path):
                for root, _, files in os.walk(path):
                    for file in files:
                        full_path = os.path.join(root, file)
                        rel_path = os.path.relpath(full_path, start=os.getcwd())
                        rel_norm = os.path.normpath(rel_path).replace('\\', '/')
                        if not require_git_tracking or (allowed_files and rel_norm in allowed_files):
                            resolved_files.append(full_path)
            else:
                rel_path = os.path.relpath(path, start=os.getcwd())
                rel_norm = os.path.normpath(rel_path).replace('\\', '/')
                if not require_git_tracking or (allowed_files and (rel_norm in allowed_files or norm_path in allowed_files)):
                    resolved_files.append(path)

    return list(dict.fromkeys(resolved_files))

def main():
    config = load_toml_config()
    
    parser = argparse.ArgumentParser(
        description="Pack specific workspace targets into the clipboard container."
    )
    parser.add_argument(
        "targets", nargs="*", default=config["default_targets"],
        help="Target files, directories, or wildcard patterns"
    )
    parser.add_argument(
        "--force-git", action="store_true",
        help="Force strict Git index filtering regardless of TOML settings."
    )
    
    args = parser.parse_args()
    
    # Check if we should enforce git index filtering
    require_git = config["require_git_tracking"] or args.force_git
    
    files_to_pack = resolve_targets(args.targets, require_git_tracking=require_git)
    
    if not files_to_pack:
        print("[X] Abort: No valid files identified under target matching guidelines.", file=sys.stderr)
        sys.exit(1)
        
    output_nodes = [generate_file_stream(f, config["max_truncate_size"]) for f in files_to_pack]
    content = "".join(output_nodes)
    
    timestamp = subprocess.run(["date", "+%Y%m%d_%H%M%S"], capture_output=True, text=True).stdout.strip()
    wrapped_stream = (
        f"# Stream Frame: {timestamp}_Workspace_Context_Payload\n"
        f"* **Target Scope Count:** {len(files_to_pack)} resolved files\n"
        f"-------------\n\n"
        f"{content}\n"
        f"-------------\n"
        f"# Tracking Footer: {timestamp}_Workspace_Context_Payload_Complete\n"
    )
    
    copied = False
    
    # Try the configured absolute WSL-to-Windows clipboard pipe first
    wsl_clip = config["wsl_clip_path"]
    if os.path.exists(wsl_clip):
        try:
            proc = subprocess.Popen([wsl_clip], stdin=subprocess.PIPE, text=True, errors='ignore')
            proc.communicate(input=wrapped_stream)
            if proc.returncode == 0:
                copied = True
        except Exception as e:
            print(f"[-] Diagnostic: WSL absolute clip.exe path failed: {e}", file=sys.stderr)

    # Fall back to raw command check (for Windows environments where clip.exe is native in PATH)
    if not copied:
        try:
            proc = subprocess.Popen(['clip.exe'], stdin=subprocess.PIPE, text=True, errors='ignore')
            proc.communicate(input=wrapped_stream)
            if proc.returncode == 0:
                copied = True
        except Exception:
            pass

    # Fall back to Linux system clipboards ONLY if not running on WSL/Windows paths
    if not copied:
        for cmd in [['xclip', '-selection', 'clipboard'], ['wl-copy']]:
            try:
                proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, text=True)
                proc.communicate(input=wrapped_stream)
                if proc.returncode == 0:
                    copied = True
                    break
            except Exception:
                continue

    if copied:
        print(f"[+] Bundle generated successfully ({len(files_to_pack)} assets). Pushed to clipboard.")
    else:
        print("[X] System Routing Fault: Clipboard sub-system could not be accessed natively.", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
