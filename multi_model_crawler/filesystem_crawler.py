import os
import mimetypes
import json
from pathlib import Path

# Directories we absolutely want to exclude to prevent infinite loops / garbage tracking
BANNED_DIRS = {'.git', 'node_modules', '__pycache__', 'AppData', 'Local Settings'}

def extract_file_features(root_path: str, max_sample_bytes: int = 1024):
    """Walks the filesystem and extracts lightweight data packets for the models."""
    scan_results = []
    
    for root, dirs, files in os.walk(root_path):
        # In-place filtering to prevent os.walk from entering banned subdirectories
        dirs[:] = [d for d in dirs if d not in BANNED_DIRS]
        
        for file in files:
            file_path = Path(root) / file
            try:
                stat = file_path.stat()
                mime_type, _ = mimetypes.guess_type(str(file_path))
                
                # Sample the head of the file if it's small or text-based
                sample_text = ""
                if stat.st_size > 0 and (mime_type and 'text' in mime_type or file_path.suffix in ['.log', '.txt', '.py', '.c', '.json', '.cpp', '.md']):
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        sample_text = f.read(max_sample_bytes)
                
                file_packet = {
                    "path": str(file_path),
                    "filename": file,
                    "extension": file_path.suffix,
                    "size_bytes": stat.st_size,
                    "mime_type": mime_type or "application/octet-stream",
                    "content_sample": sample_text.strip()
                }
                scan_results.append(file_packet)
                
            except Exception as e:
                # Silently catch access errors, locked files, or dead symlinks
                continue
                
    return scan_results
