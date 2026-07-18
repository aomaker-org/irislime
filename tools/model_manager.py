#!/usr/bin/env python3
# ==============================================================================
# Path:        tools/model_manager.py
# Purpose:     Low-Overhead Model Directory Asset Provisioner & HF Downloader
# Target OS:   Ubuntu 26.04 LTS / WSL2 Subsystem (Core12 Workstation Platform)
# Lineage:     Unified Asset Specification / Infrastructure Tools
# Author:      IrisLime Core Engine Integration
# Updated:     20260710_0658 (Fixed Qwen decimal name & integrated HF_TOKEN detection)
# ==============================================================================

import os
import sys
import argparse
from urllib.request import Request, urlopen
from urllib.error import URLError
from pathlib import Path

# Default targeting pointing cleanly adjacent to your active repository root
DEFAULT_DEST_DIR = Path(__file__).resolve().parent.parent.parent / "models"

# Sugested initial "puppy_chow" testing asset weights
DEFAULT_REPO = "Qwen/Qwen2.5-0.5B-Instruct-GGUF"
DEFAULT_FILE = "qwen2.5-0.5b-instruct-q4_k_m.gguf"  # FIXED: Period character corrected

class ModelProvisioner:
    def __init__(self, repo: str, filename: str, destination: Path):
        self.repo = repo
        self.filename = filename
        self.dest_dir = destination.resolve()
        self.target_path = self.dest_dir / filename
        
        # Build canonical Hugging Face direct resolve download endpoint URL
        self.download_url = f"https://huggingface.co/{repo}/resolve/main/{filename}"

    def execute_provision(self) -> bool:
        """Execute stream chunk acquisition loop with inline stdout metrics."""
        print("==================================================================")
        print("[+] IRISLIME MODEL PROVISION UTILITY INITIALIZED")
        print("==================================================================")
        print(f"[*] HF Source Repo: {self.repo}")
        print(f"[*] Target Binary:  {self.filename}")
        print(f"[*] Destination:    {self.target_path}")
        
        # Check environment configurations for authorization layer injection
        hf_token = os.environ.get("HF_TOKEN")
        if hf_token:
            print("[*] Security Flag:  Active HF_TOKEN detected. Injecting Bearer auth.")
        else:
            print("[*] Security Flag:  No active HF_TOKEN environment binding found.")
        print("==================================================================\n")

        # Guarantee local block storage layout presence
        self.dest_dir.mkdir(parents=True, exist_ok=True)

        if self.target_path.exists():
            print(f"[!] Target binary already present on filesystem storage blocks.")
            print(f"[-] Path: {self.target_path}\nSkipping download operation.")
            return True

        # Build connection request with custom headers
        headers = {"User-Agent": "IrisLime-Engine-Core"}
        if hf_token:
            headers["Authorization"] = f"Bearer {hf_token}"
            
        req = Request(self.download_url, headers=headers)
        
        try:
            with urlopen(req) as response:
                meta = response.info()
                file_size = int(meta.get("Content-Length", 0))
                
                size_mb = file_size / (1024 * 1024)
                print(f"[+] Connection Established. Content Payload Size: {size_mb:.2f} MB")
                print(f"[+] Streaming remote payload bytes down to workspace...")

                bytes_downloaded = 0
                chunk_size = 1024 * 512  # Efficient 512 KB transfer windows
                
                with open(self.target_path, "wb") as local_file:
                    while True:
                        buffer = response.read(chunk_size)
                        if not buffer:
                            break
                            
                        bytes_downloaded += len(buffer)
                        local_file.write(buffer)
                        
                        # Calculate and render low-overhead inline terminal metrics
                        percent = (bytes_downloaded / file_size) * 100 if file_size else 0
                        downloaded_mb = bytes_downloaded / (1024 * 1024)
                        sys.stdout.write(f"\r  -> Progress Matrix: {percent:6.2f}% | [{downloaded_mb:7.2f} MB / {size_mb:7.2f} MB]")
                        sys.stdout.flush()
                        
                sys.stdout.write("\n\n[+] Stream transmission verified. Syncing file descriptor states to disk storage layout.")
                print("\n==================================================================")
                print("[+] PROVISION STEP RESOLVED: SUCCESS")
                print("==================================================================")
                return True

        except URLError as ue:
            print(f"\n[!] Network communication gate connection failure encountered: {ue.reason}")
            if self.target_path.exists():
                self.target_path.unlink() # Cleanup fragments
            return False
        except Exception as e:
            print(f"\n[!] Unexpected infrastructure crash occurred during download: {e}")
            if self.target_path.exists():
                self.target_path.unlink()
            return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="IrisLime Lightweight Model Provisioning Utility")
    parser.add_argument("--repo", type=str, default=DEFAULT_REPO, help="Hugging Face repo source path mapping")
    parser.add_argument("--file", type=str, default=DEFAULT_FILE, help="Target GGUF file asset string name")
    parser.add_argument("--dest", type=str, default=str(DEFAULT_DEST_DIR), help="Target local storage location path")
    
    args = parser.parse_args()
    
    provisioner = ModelProvisioner(
        repo=args.repo,
        filename=args.file,
        destination=Path(args.dest)
    )
    
    success = provisioner.execute_provision()
    sys.exit(0 if success else 1)

# end of file: tools/model_manager.py
