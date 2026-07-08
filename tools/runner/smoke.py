# Prototype Submodule Snippet: tools/runner/smoke.py
import subprocess
import os

def verify_binary_signature(binary_path):
    """Phase 1 Smoke Test: Confirms file existence and command-router validity."""
    if not os.path.exists(binary_path):
        return False, "Target executable binary structurally absent from drive."
        
    try:
        # Query basic version output to ensure shared library linkages (libllama.so) resolve
        result = subprocess.run([binary_path, "version"], capture_output=True, text=True, check=True)
        return True, result.stdout.strip()
    except subprocess.CalledProcessError as e:
        return False, f"Linkage fault detected. Router dropped execution: {e.stderr}"
