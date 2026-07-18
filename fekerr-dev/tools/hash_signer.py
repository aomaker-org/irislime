# ==============================================================================
# PATH:        tools/hash_signer.py
# PURPOSE:     Self-referential SHA-256 signature utility for file integrity checking.
#              Bypasses circular dependency by ignoring lines containing "Integrity-Hash:".
#              Autodetects comment wrappers and injects placeholder tags if missing.
# TARGET:      Python 3.x / Ubuntu 26.04 dev environment
# LINEAGE:     fekerr-dev / Systems Integrity
# UPDATED:     20260715_141000
# ==============================================================================

import sys
import os
import hashlib
import re

HASH_TAG = "Integrity-Hash:"

def detect_comment_syntax(filepath):
    """Determines the correct comment prefix/suffix based on file extension or content."""
    _, ext = os.path.splitext(filepath)
    ext = ext.lower()
    
    # Check shebang first if it's extensionless or .sh
    has_shebang = False
    if os.path.exists(filepath):
        try:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                first_line = f.readline()
                if first_line.startswith("#!"):
                    has_shebang = True
        except Exception:
            pass

    # Map extensions to comment styles
    if ext in ['.py', '.sh', '.yaml', '.yml', '.ini', '.toml', '.cfg', '.txt'] or has_shebang:
        return "# ", "", has_shebang
    elif ext in ['.js', '.ts', '.rs', '.go', '.cpp', '.hpp', '.c', '.h', '.cs', '.java']:
        return "// ", "", has_shebang
    elif ext in ['.html', '.xml', '.md']:
        return "", has_shebang
    
    # Safe default fallback
    return "# ", "", has_shebang

def compute_normalized_hash(filepath):
    """Calculates the SHA-256 hash of a file while ignoring lines containing HASH_TAG."""
    sha256 = hashlib.sha256()
    has_signature_line = False
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            if HASH_TAG in line:
                has_signature_line = True
                continue
            sha256.update(line.encode('utf-8'))
            
    return sha256.hexdigest(), has_signature_line

def inject_placeholders(filepath):
    """Autodetects comment markers and inserts Integrity-Hash placeholders at top/bottom."""
    prefix, suffix, has_shebang = detect_comment_syntax(filepath)
    temp_path = filepath + ".tmp"
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as src:
        lines = src.readlines()

    with open(temp_path, 'w', encoding='utf-8') as dst:
        inserted_header = False
        
        # Write lines, checking where to drop the header placeholder
        for idx, line in enumerate(lines):
            dst.write(line)
            # Inject right after the shebang if present, or at the very top
            if has_shebang and idx == 0 and not inserted_header:
                dst.write(f"{prefix}{HASH_TAG} PENDING{suffix}\n")
                inserted_header = True
        
        if not inserted_header:
            # No shebang: we will prepend the tag later
            pass
            
        # Ensure there's a matching footer tag at the very end
        if len(lines) == 0 or not lines[-1].endswith('\n'):
            dst.write('\n')
        dst.write(f"{prefix}{HASH_TAG} PENDING{suffix}\n")

    # If we didn't have a shebang, prepend the header tag directly to the top
    if not has_shebang:
        with open(temp_path, 'r', encoding='utf-8') as tmp:
            tmp_content = tmp.read()
        with open(temp_path, 'w', encoding='utf-8') as dst:
            dst.write(f"{prefix}{HASH_TAG} PENDING{suffix}\n")
            dst.write(tmp_content)

    os.replace(temp_path, filepath)
    print(f"[+] Autodetected comments and injected placeholders into {os.path.basename(filepath)}.")

def sign_file(filepath):
    """Signs the file by updating all lines containing HASH_TAG with the fresh computed hash."""
    if not os.path.exists(filepath):
        print(f"[!] Error: File not found: {filepath}")
        return False
        
    computed_hash, has_sig = compute_normalized_hash(filepath)
    
    # If no tags are found, trigger the auto-injection process!
    if not has_sig:
        inject_placeholders(filepath)
        computed_hash, _ = compute_normalized_hash(filepath)

    temp_path = filepath + ".tmp"
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as src, \
         open(temp_path, 'w', encoding='utf-8') as dst:
        for line in src:
            if HASH_TAG in line:
                prefix = line.split(HASH_TAG)[0]
                suffix = ""
                if "-->" in line:
                    suffix = " -->"
                dst.write(f"{prefix}{HASH_TAG} {computed_hash}{suffix}\n")
            else:
                dst.write(line)
                
    os.replace(temp_path, filepath)
    print(f"[+] File successfully signed!")
    print(f"    Target: {os.path.basename(filepath)}")
    print(f"    Hash:   {computed_hash}")
    return True

def verify_file(filepath):
    """Compares the active computed hash of the file against the signature written inside it."""
    if not os.path.exists(filepath):
        print(f"[!] Error: File not found: {filepath}")
        return False
        
    computed_hash, _ = compute_normalized_hash(filepath)
    embedded_hashes = []
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        for line_num, line in enumerate(f, 1):
            if HASH_TAG in line:
                match = re.search(r'Integrity-Hash:\s*([a-fA-F0-9]{64})', line)
                if match:
                    embedded_hashes.append((line_num, match.group(1)))
                    
    if not embedded_hashes:
        print(f"[!] Verification failed: No valid '{HASH_TAG} [sha256]' signature found in file.")
        return False
        
    mismatches = 0
    for line_num, embedded in embedded_hashes:
        if embedded == computed_hash:
            print(f"[+] Verification PASSED (Line {line_num}): Embedded signature matches computed hash.")
        else:
            print(f"[!] Verification FAILED (Line {line_num}):")
            print(f"    Embedded: {embedded}")
            print(f"    Computed: {computed_hash}")
            mismatches += 1
            
    return mismatches == 0

def main():
    if len(sys.argv) < 3:
        print("================================================================================")
        print("PATH:        tools/hash_signer.py")
        print("USAGE:       uv run python tools/hash_signer.py [sign | verify] <filename>")
        print("================================================================================")
        return

    action = sys.argv[1].lower()
    target = sys.argv[2]
    
    if action == "sign":
        sign_file(target)
    elif action == "verify":
        verify_file(target)
    else:
        print(f"[!] Unknown action: {action}")

if __name__ == "__main__":
    main()
