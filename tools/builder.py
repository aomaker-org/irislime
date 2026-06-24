import os
import subprocess

def build_llama_sycl():
    repo_path = "llama.cpp"
    
    # 1. Automatic clone if missing
    if not os.path.exists(repo_path):
        print(f"[!] '{repo_path}' not found. Cloning repository...")
        try:
            subprocess.run(
                ["git", "clone", "https://github.com/ggerganov/llama.cpp"], 
                check=True
            )
        except subprocess.CalledProcessError:
            print("[X] Failed to clone llama.cpp. Check your internet connection.")
            return False

    build_dir = os.path.join(repo_path, "build")
    os.makedirs(build_dir, exist_ok=True)

    # 2. Build Command
    # We no longer 'source' here; we rely on the environment 
    # already being prepared in your shell session.
    cmd = (
        f"cd {build_dir} && "
        "cmake .. -DGGML_SYCL=ON "
        "-DCMAKE_C_COMPILER=$(which icx) "
        "-DCMAKE_CXX_COMPILER=$(which icpx) "
        "-DCMAKE_VERBOSE_MAKEFILE=ON && "
        "make -j$(nproc)"
    )
    
    print("[!] Starting C++ build process...")
    try:
        # We run this in the shell so the $(which) commands resolve correctly
        subprocess.run(
            cmd, 
            shell=True, 
            executable='/bin/bash', 
            check=True
        )
        print("[+] Build successful!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"\n[X] Build failed with return code {e.returncode}")
        print("[X] Check the output above for specific compiler or linker errors.")
        return False
