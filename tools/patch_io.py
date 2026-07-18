import sys
import os
import subprocess

def patch_in(file_path):
    # Logic for patching input stream
    print(f"[+] Patching Input: {file_path}")
    
    script_dir = os.path.dirname(os.path.realpath(__file__))
    tool_path = os.path.join(script_dir, "clip2files")
    if not os.path.exists(tool_path):
        tool_path += ".py"
        
    if os.path.exists(tool_path):
        # clip2files reads from clipboard and extracts files
        cmd = [sys.executable, tool_path]
        subprocess.run(cmd)
    else:
        print(f"[-] Error: clip2files not found at {tool_path}")

def patch_out(file_path):
    # Logic for patching output stream
    print(f"[+] Patching Output: {file_path}")
    
    script_dir = os.path.dirname(os.path.realpath(__file__))
    tool_path = os.path.join(script_dir, "files2clip")
    if not os.path.exists(tool_path):
        tool_path += ".py"
        
    if os.path.exists(tool_path):
        # files2clip takes the file_path and packs it to clipboard
        cmd = [sys.executable, tool_path, file_path]
        subprocess.run(cmd)
    else:
        print(f"[-] Error: files2clip not found at {tool_path}")

def main():
    if len(sys.argv) < 2:
        print("Usage: patch_io.py [in|out] [path]")
        sys.exit(1)

    mode = sys.argv[1]
    file_path = sys.argv[2] if len(sys.argv) > 2 else "default_stream"

    if mode == "in":
        patch_in(file_path)
    elif mode == "out":
        patch_out(file_path)
    else:
        print(f"[-] Unknown mode: {mode}")
        sys.exit(1)

if __name__ == "__main__":
    main()
