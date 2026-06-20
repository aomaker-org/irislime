import os
import subprocess

def check_gpu_readiness():
    render_node = "/dev/dri/renderD128"
    if os.path.exists(render_node):
        print(f"[+] Found {render_node}. GPU bridge active.")
        return True
    
    print("[!] Render node missing. Suggestion: Run 'sudo modprobe vgem'.")
    return False
