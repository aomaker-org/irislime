#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# IDENTIFIER:  tools/tree_scan.py
# AUTHOR:      fekerr & Gemini
# VERSION:     1.0.0
# DESCRIPTION: Lightweight metadata scanner to audit workspace paths safely
# ==============================================================================

import os
from pathlib import Path

def main():
    root = Path(__file__).resolve().parent.parent
    print(f"=== WORKSPACE STRUCTURE SNAPSHOT ===")
    print(f"Root: {root}\n")
    
    # Simple recursive directory walk ignoring hidden/virtual env paths
    for path in sorted(root.rglob("*")):
        if any(part in path.parts for part in [".git", ".venv", "__pycache__", "blobs"]):
            continue
            
        rel_path = path.relative_to(root)
        if path.is_file():
            size_kb = path.stat().st_size / 1024
            print(f"FILE: {rel_path} ({size_kb:.2f} KB)")
        elif path.is_dir():
            print(f"DIR : {rel_path}/")
            
    print("====================================")

if __name__ == "__main__":
    main()
