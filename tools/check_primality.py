#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tools/check_primality.py
# Purpose:      Lightweight Primality Checker for Terminal Telemetry & $PS1 Prompts
# Type:         Executable
# Attribution:  fekerr & Gemini (20260729 Task 110 Implementation)
# ==============================================================================

import sys

def is_prime(n: int) -> bool:
    if n <= 1:
        return False
    if n <= 3:
        return True
    if n % 2 == 0 or n % 3 == 0:
        return False
    i = 5
    while i * i <= n:
        if n % i == 0 or n % (i + 2) == 0:
            return False
        i += 6
    return True

def main():
    if len(sys.argv) > 1:
        try:
            num = int(sys.argv[1])
            if is_prime(num):
                print(f"[P:{num}]")
            else:
                print(f"[{num}]")
        except ValueError:
            print("[N/A]")
    else:
        print("[N/A]")

if __name__ == "__main__":
    main()
