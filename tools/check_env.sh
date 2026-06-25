#!/bin/bash
# Simple dependency check for the lab
deps=("cmake" "icpx" "make" "python3")

for d in "${deps[@]}"; do
    if ! command -v "$d" &> /dev/null; then
        echo "[!] Error: $d is required but not found."
        exit 1
    fi
done
echo "[+] All system dependencies satisfied."
