#!/usr/bin/env bash
# Dispatches to the appropriate backend
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # We are in Git Bash on Windows
    pwsh -File "$(dirname "$0")/../ps7/main.ps1" "$@"
else
    # We are in WSL/Linux
    bash "$(dirname "$0")/shell/main.sh" "$@"
fi
