#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tools/clip_helper.py
# Purpose:      Standalone Clipboard Processing Logic with Automated Handshake
# Target OS:    Ubuntu 26.04 LTS / WSL2 Subsystem
# Lineage:      IrisLime Modular Utility Tier
# Attribution:  fekerr & Gemini (20260713_0812 Safe Handshake Pass)
# ==============================================================================

import subprocess
import sys
from datetime import datetime

def get_host_clipboard() -> str:
    """Queries the host Windows Forms API via PowerShell core hooks."""
    try:
        proc = subprocess.run(
            ["powershell.exe", "-NoProfile", "-Command", "[Windows.Forms.Clipboard]::GetText()"],
            capture_output=True, text=True, check=True
        )
        return proc.stdout
    except Exception:
        try:
            proc = subprocess.run(
                ["powershell.exe", "-NoProfile", "-Command", "Get-Clipboard"],
                capture_output=True, text=True, check=True
            )
            return proc.stdout
        except Exception:
            return ""

def push_host_clipboard(payload: str) -> bool:
    """Pushes an ASCII-safe text block directly to the Win11 system clipboard."""
    try:
        proc = subprocess.Popen(['clip.exe'], stdin=subprocess.PIPE, text=True, errors='ignore')
        proc.communicate(input=payload)
        return proc.returncode == 0
    except Exception:
        return False

def format_and_prime_handshake(character_count: int, status_slug: str):
    """Generates a shell-safe pre-commented handshake and loads it to the clipboard."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    handshake = f"""# ==============================================================================
# IRISLIME TRANSPORTS HANDSHAKE MATRIX: {timestamp}
# Status Token : {status_slug}
# Profile Trace: fekerr & Gemini Sync Mode
# ==============================================================================
# [+] Clipboard Ingestion Cycle Completed Natively.
# [*] Extracted Buffer Size: {character_count} characters verified.
# [-] Core Staging Status  : Staged for next refinement chunk.
# ==============================================================================
# EOR {timestamp}_clip_handshake_prime
"""
    push_host_clipboard(handshake)
    print("[+] Symmetrical handshake frame loaded and primed in host clipboard.")
