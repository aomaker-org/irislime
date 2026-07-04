#!/usr/bin/env python3
# ==============================================================================
# Filename:    tools/bootstrap_test_matrix.py
# Purpose:     Automated configuration discovery and structural tests folder scaffolding
# Type:        Infrastructure Tool
# Attribution: fekerr & Gemini (20260702_1941 / flash 3.5 extended)
# ==============================================================================

import os
import sys
import json
import subprocess

def get_repository_root():
    try:
        return subprocess.check_output(["git", "rev-parse", "--show-toplevel"]).decode("utf-8").strip()
    except subprocess.CalledProcessError:
        return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def initialize_scaffolding():
    repo_root = get_repository_root()
    print(f"[+] Bootstrapping IrisLime Test Matrix Environment...")
    print(f"[+] Root Dir: {repo_root}")
    print("------------------------------------------------------------------")

    # 1. Resolve and Validate the Models Target Directory
    models_env_var = "IRISLIME_MODELS_PATH"
    models_path = os.environ.get(models_env_var, os.path.abspath(os.path.join(repo_root, "..", "models")))
    print(f"[Discovery] Scanning for local model assets inside: {models_path}")

    discovered_assets = {}
    if os.path.exists(models_path) and os.path.isdir(models_path):
        for file_item in os.listdir(models_path):
            file_path = os.path.join(models_path, file_item)
            if os.path.isfile(file_path):
                name_base, ext = os.path.splitext(file_item)
                ext_lower = ext.lower()
                
                if ext_lower in [".gguf", ".bin", ".litert"]:
                    model_format = "gguf" if ext_lower == ".gguf" else "litert"
                    deduced_arch = "gemma" if "gemma" in name_base.lower() else "llama"
                    
                    discovered_assets[name_base] = {
                        "filename": file_item,
                        "format": model_format,
                        "architecture": deduced_arch,
                        "recommended_backends": ["gpu", "cpu"] if model_format == "litert" else ["openvino", "sycl", "vulkan", "cpu"]
                    }
                    print(f"  • Found Model: {file_item} [{model_format.upper()}]")
    else:
        print(f"[-] Warning: Targeted models path does not exist on disk: {models_path}")

    # 2. Synchronize and Write the model_selector.json Manifest
    selector_path = os.path.join(repo_root, "model_selector.json")
    selector_payload = {
        "models_root_override": models_path if os.environ.get(models_env_var) else "",
        "available_assets": discovered_assets
    }
    with open(selector_path, "w") as sf:
        json.dump(selector_payload, sf, indent=2)
    print(f"[✅] Synchronized asset configurations to: {selector_path}")

    # 3. Create Testing Subdirectory Branches Structural Layout
    target_test_trees = ["tests/litert", "tests/llama", "tests/shared"]
    for tree_path in target_test_trees:
        full_tree_path = os.path.join(repo_root, tree_path)
        if not os.path.exists(full_tree_path):
            os.makedirs(full_tree_path, exist_ok=True)
            print(f"[Directory] Scaffolding test branch layout created at: {tree_path}")

    # 4. Inject Baseline Verification Test Template Boilerplates
    litert_placeholder_test = os.path.join(repo_root, "tests", "litert", "test_identity_load.py")
    if not os.path.exists(litert_placeholder_test):
        with open(litert_placeholder_test, "w") as tf:
            tf.write('''#!/usr/bin/env python3
# Automated structural baseline placeholder for LiteRT-LM components testing
import sys
import os

def test_placeholder():
    print("    [Sub-Test] Executing LiteRT-LM backend layer structural smoke pass...")
    # Add explicit validation verification checks here
    return True

if __name__ == "__main__":
    success = test_placeholder()
    sys.exit(0 if success else 1)
''')
        os.chmod(litert_placeholder_test, 0o755)
        print(f"  • Scaffolded verification script template into: tests/litert/test_identity_load.py")

    print("------------------------------------------------------------------")
    print("[✅] Matrix initialization completed successfully. Core scaffolds in position.")

if __name__ == "__main__":
    initialize_scaffolding()
