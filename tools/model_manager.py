import subprocess
import os

def download_model(repo_id, filename):
    model_dir = "models"
    os.makedirs(model_dir, exist_ok=True)
    
    print(f"[!] Downloading {filename} from {repo_id} via 'hf'...")
    # The new syntax: hf download <repo_id> <filename> --local-dir <dir>
    subprocess.run([
        "hf", "download", repo_id, filename, 
        "--local-dir", model_dir
    ], check=True)
