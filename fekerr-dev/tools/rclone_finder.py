# ==============================================================================
# Path:        tools/rclone_finder.py
# Purpose:     Queries local rclone json trees instantly using fast text matches.
# Target:      Ubuntu 26.04 LTS / WSL2 / LXC
# Lineage:     fekerr-dev / Rclone Caching Engine
# UPDATED:     20260715_154000
# Integrity-Hash: PENDING
# ==============================================================================

import os
import sys
import json

CACHE_FILE = os.path.expanduser("~/src/fekerr-dev/rclone_cache/gdrive_file_tree.json")

def human_readable_size(num):
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if abs(num) < 1024.0:
            return f"{num:3.1f} {unit}"
        num /= 1024.0
    return f"{num:.1f} PB"

def find_items(query):
    if not os.path.exists(CACHE_FILE):
        sys.stderr.write("[!] Error: Local file cache not compiled. Run 'uv run python tools/rclone_cache_builder.py' first.\n")
        return

    with open(CACHE_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    sys.stdout.write(f"[*] Querying cached tree [Age: {data['metadata']['generated_at']}] for '{query}'...\n")
    matches = []
    
    for item in data["items"]:
        # Query matching against item paths or names
        if query.lower() in item.get("Path", "").lower() or query.lower() in item.get("Name", "").lower():
            matches.append(item)

    if not matches:
        sys.stdout.write("[-] No matching files or directories found in the local cache.\n")
        return

    sys.stdout.write(f"[+] Found {len(matches)} matching entries:\n")
    sys.stdout.write("-" * 80 + "\n")
    for match in matches:
        type_indicator = "[DIR]" if match.get("IsDir") else "[FIL]"
        size_str = human_readable_size(match.get("Size", 0)) if not match.get("IsDir") else "DIR"
        path = match.get("Path")
        sys.stdout.write(f"  {type_indicator}  {size_str:<10}  {path}\n")
    sys.stdout.write("-" * 80 + "\n")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.stdout.write("Usage: uv run python tools/rclone_finder.py <search_query>\n")
    else:
        find_items(sys.argv[1])
