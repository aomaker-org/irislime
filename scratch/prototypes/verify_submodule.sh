#!/bin/sh
echo "[+] Checking physical directory contents of llama.cpp/:"
ls -la llama.cpp

echo "\n[+] Checking if .git pointer file exists inside the submodule path:"
if [ -f "llama.cpp/.git" ]; then
    echo "    -> Found .git pointer: $(cat llama.cpp/.git)"
else
    echo "    -> [!] WARNING: Submodule repository is physically empty or uninitialized."
fi
