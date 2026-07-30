#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tools/token_throttle_guard.py
# Purpose:      AGY Credit & Token Preservation Guard (Task 200)
# Target OS:    Ubuntu 26.04 LTS / WSL2 / Windows 11
# Lineage:      IrisLime Infrastructure (Task 200)
# Updated:      2026-07-29
# Attribution:  fekerr & Gemini
# ==============================================================================

import os
import sys
import time
import datetime
from pathlib import Path

FIVE_HOUR_TOKEN_BUDGET = 500000
PAUSE_INTERVAL_SECONDS = 600
THROTTLE_THRESHOLD_PCT = 0.50  # 50% quota gate threshold

def evaluate_token_preservation(estimated_tokens_used: int = 150000):
    root = Path(__file__).resolve().parent.parent
    log_dir = root / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    csv_file = log_dir / "token_quota_telemetry.csv"

    if not csv_file.exists():
        with open(csv_file, "w", encoding="utf-8") as f:
            f.write("timestamp,estimated_tokens_used,budget_5h,usage_ratio,throttled_status\n")

    usage_ratio = estimated_tokens_used / FIVE_HOUR_TOKEN_BUDGET
    is_throttled = usage_ratio >= THROTTLE_THRESHOLD_PCT
    status_str = "THROTTLED_PAUSE" if is_throttled else "NOMINAL"

    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"{ts},{estimated_tokens_used},{FIVE_HOUR_TOKEN_BUDGET},{usage_ratio:.4f},{status_str}\n"

    with open(csv_file, "a", encoding="utf-8") as f:
        f.write(log_entry)

    print("==========================================================")
    print("  AGY Credit & Token Preservation Guard (Task 200)        ")
    print("==========================================================")
    print(f"Timestamp           : {ts}")
    print(f"Tokens Used (5h)    : {estimated_tokens_used:,} / {FIVE_HOUR_TOKEN_BUDGET:,}")
    print(f"Usage Ratio         : {usage_ratio * 100:.1f}% (Gate Threshold: {THROTTLE_THRESHOLD_PCT * 100:.0f}%)")
    print(f"Preservation Mode   : {status_str}")

    if is_throttled:
        print(f"[!] WARNING: 50%/5h token quota gate threshold reached ({usage_ratio * 100:.1f}%).")
        print("    --> Preservation Guard active. Recommending 10-minute pause interval.")
    else:
        print("[+] Token quota consumption nominal. Unrestricted execution permitted.")

    print(f"[+] Telemetry logged to: {csv_file}")
    print("==========================================================")
    return True

if __name__ == "__main__":
    evaluate_token_preservation()
    sys.exit(0)
