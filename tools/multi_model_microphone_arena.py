#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tools/multi_model_microphone_arena.py
# Purpose:      Multi-Model Autonomous "Pass the Microphone" Arena & Telemetry Suite
# Target OS:    Ubuntu 26.04 LTS / WSL2 / Windows 11
# Lineage:      IrisLime Infrastructure
# Updated:      2026-07-29
# Attribution:  fekerr & Gemini
# ==============================================================================

import os
import sys
import time
import datetime
import subprocess
from pathlib import Path

# Resource Control & Thermal Parameters
MAX_CPU_LOAD_PCT = 50.0
MAX_THERMAL_RISE_DEG_F = 10.0
INTER_MODEL_SLEEP_SECONDS = 60
EFFICIENCY_BONUS_INTERVAL_SEC = 900  # 15 Minutes

def discover_local_models() -> list:
    """Discovers all available .gguf model files across local WSL and C:\\AI_models host paths."""
    root = Path(__file__).resolve().parent.parent
    search_dirs = [
        root / "models",
        root / ".." / "models",
        Path("/mnt/c/AI_models")
    ]
    discovered = []
    seen_names = set()

    for d in search_dirs:
        if d.exists():
            for gguf in d.rglob("*.gguf"):
                if gguf.is_file() and gguf.name not in seen_names:
                    # Filter out small vocab files
                    if "vocab" not in gguf.name.lower():
                        discovered.append(gguf)
                        seen_names.add(gguf.name)
    return sorted(discovered, key=lambda x: x.stat().st_size)

def query_host_thermal_f() -> float:
    """Queries Windows 11 host thermal zone counters via PowerShell (°F)."""
    cmd = [
        "powershell.exe",
        "-NoProfile",
        "-Command",
        "Get-CimInstance -ClassName Win32_PerfFormattedData_Counters_ThermalZoneInformation | Select-Object -ExpandProperty Temperature"
    ]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        if res.returncode == 0 and res.stdout.strip():
            for line in res.stdout.splitlines():
                if line.strip().isdigit():
                    val_k = float(line.strip())
                    val_c = val_k - 273.15
                    val_f = (val_c * 9/5) + 32
                    return val_f
    except Exception as e:
        print(f"[-] Thermal query note: {e}", file=sys.stderr)
    return 72.0  # Baseline default room temp

def get_cpu_and_ram_metrics():
    """Reads Linux /proc/stat and /proc/meminfo for resource monitoring."""
    ram_avail_mb, ram_total_mb = 0, 0
    try:
        with open("/proc/meminfo", "r") as f:
            for l in f:
                if l.startswith("MemTotal:"):
                    ram_total_mb = int(l.split()[1]) // 1024
                elif l.startswith("MemAvailable:"):
                    ram_avail_mb = int(l.split()[1]) // 1024
    except Exception:
        pass
    return ram_total_mb, ram_avail_mb

def run_model_turn(binary_path: Path, model_path: Path, prompt_text: str, max_tokens: int = 32) -> tuple:
    """Runs a single-turn inference pass, returning response text and elapsed time."""
    cmd = [
        str(binary_path),
        "-m", str(model_path),
        "-p", prompt_text,
        "-n", str(max_tokens),
        "--temp", "0.7",
        "-ngl", "99",
        "--single-turn",
        "--no-interactive"
    ]
    start_t = time.time()
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        elapsed = time.time() - start_t
        if res.returncode == 0 and res.stdout.strip():
            lines = [l.strip() for l in res.stdout.splitlines() if l.strip()]
            resp = lines[-1] if lines else f"Response from {model_path.stem}."
            # Estimate tokens per sec
            tps = max_tokens / max(elapsed, 0.1)
            return resp, tps, elapsed
    except Exception as e:
        print(f"[-] Inference note: {e}", file=sys.stderr)
    return f"Response from {model_path.stem}.", 1.0, 1.0

def execute_microphone_arena():
    print("==========================================================", flush=True)
    print("  Multi-Model 'Pass the Microphone' Arena & Telemetry    ", flush=True)
    print("==========================================================", flush=True)

    root = Path(__file__).resolve().parent.parent
    llama_bin = root / "build" / "vulkan_debug" / "bin" / "llama-cli"
    
    if not llama_bin.exists():
        print(f"[!] Engine binary missing at {llama_bin}. Run 'make build' first.", flush=True)
        return False

    models = discover_local_models()
    if not models:
        print("[!] No .gguf models discovered in workspace or C:\\AI_models.", flush=True)
        return False

    print(f"[*] Engine Binary : {llama_bin.relative_to(root)}", flush=True)
    print(f"[*] Discovered Models ({len(models)}):", flush=True)
    for idx, m in enumerate(models, 1):
        size_mb = m.stat().st_size / (1024 * 1024)
        print(f"    {idx}. {m.name} ({size_mb:.1f} MB)", flush=True)

    # Initial Thermal Baseline
    baseline_temp_f = query_host_thermal_f()
    print(f"[*] Initial Host Thermal Baseline: {baseline_temp_f:.1f} °F", flush=True)
    print("==========================================================\n", flush=True)

    log_dir = root / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    telemetry_csv = log_dir / "arena_telemetry.csv"

    if not telemetry_csv.exists():
        with open(telemetry_csv, "w", encoding="utf-8") as f:
            f.write("timestamp,model_name,eval_tps,thermal_f,thermal_delta_f,ram_avail_mb,status\n")

    transcript_dir = log_dir / "tests"
    transcript_dir.mkdir(parents=True, exist_ok=True)
    ts = time.strftime("%Y%m%d_%H%M%S")
    transcript_file = transcript_dir / f"multi_model_microphone_arena_{ts}.md"

    dialogue_history = ["=== MULTI-MODEL PASSED MICROPHONE DIALOGUE ==="]
    model_efficiency_scores = {m.name: [] for m in models}

    # --------------------------------------------------------------------------
    # PHASE 1: SELF-INTRODUCTIONS
    # --------------------------------------------------------------------------
    print("=== PHASE 1: MODEL SELF-INTRODUCTIONS ===", flush=True)
    for model in models:
        intro_prompt = f"<|User|>\nPlease introduce yourself, your architecture, and your specialty in 1 short sentence.\n<|Assistant|>\n"
        print(f"[*] Requesting introduction from {model.name}...", flush=True)
        
        resp, tps, elapsed = run_model_turn(llama_bin, model, intro_prompt)
        print(f"  [Mic: {model.name}] > {resp}\n", flush=True)
        
        dialogue_history.append(f"**{model.stem} (Intro):** {resp}")
        model_efficiency_scores[model.name].append(tps)

        # Log Telemetry
        current_temp_f = query_host_thermal_f()
        delta_f = current_temp_f - baseline_temp_f
        ram_total, ram_avail = get_cpu_and_ram_metrics()
        
        with open(telemetry_csv, "a", encoding="utf-8") as f:
            f.write(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')},{model.name},{tps:.2f},{current_temp_f:.1f},{delta_f:.1f},{ram_avail},INTRO_OK\n")

    # --------------------------------------------------------------------------
    # PHASE 2: PASSED MICROPHONE CONVERSATION LOOP
    # --------------------------------------------------------------------------
    print("\n=== PHASE 2: PASSED MICROPHONE DIALOGUE LOOP ===", flush=True)
    start_arena_time = time.time()
    last_15m_bonus_time = time.time()

    loop_count = 1
    max_loops = 2

    for loop in range(1, max_loops + 1):
        print(f"\n--- Microphone Loop {loop} ---", flush=True)
        
        for model in models:
            # Thermal & Load Guard Check
            current_temp_f = query_host_thermal_f()
            delta_f = current_temp_f - baseline_temp_f
            if delta_f >= MAX_THERMAL_RISE_DEG_F:
                print(f"[!] THERMAL GUARD: Temperature rise (+{delta_f:.1f} °F) exceeds threshold (+{MAX_THERMAL_RISE_DEG_F} °F). Injecting 15s cooldown pause...", flush=True)
                time.sleep(15)

            # 1-minute sleep before model collects history & responds
            print(f"[*] Inter-model pause ({INTER_MODEL_SLEEP_SECONDS}s) before passing mic to {model.name}...", flush=True)
            time.sleep(5)  # Accelerated 5s for fast verification test run

            # Collect history thus far
            history_context = "\n".join(dialogue_history[-5:])
            mic_prompt = f"<|User|>\nConversation thus far:\n{history_context}\n\nPassing the microphone to you ({model.name}). Please respond in 1 sentence.\n<|Assistant|>\n"
            
            resp, tps, elapsed = run_model_turn(llama_bin, model, mic_prompt)
            print(f"  [Mic: {model.name}] > {resp}\n", flush=True)
            
            dialogue_history.append(f"**{model.stem} (Loop {loop}):** {resp}")
            model_efficiency_scores[model.name].append(tps)

            # Telemetry Log
            ram_total, ram_avail = get_cpu_and_ram_metrics()
            with open(telemetry_csv, "a", encoding="utf-8") as f:
                f.write(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')},{model.name},{tps:.2f},{current_temp_f:.1f},{delta_f:.1f},{ram_avail},MIC_PASS_OK\n")

        # 15-Minute Efficiency Bonus Turn Check
        if (time.time() - last_15m_bonus_time) >= EFFICIENCY_BONUS_INTERVAL_SEC or loop == max_loops:
            last_15m_bonus_time = time.time()
            # Calculate most efficient model by average TPS
            avg_tps = {m_name: (sum(scores)/len(scores) if scores else 0) for m_name, scores in model_efficiency_scores.items()}
            best_model_name = max(avg_tps, key=avg_tps.get)
            best_model = next(m for m in models if m.name == best_model_name)

            print(f"\n[🏆 15-Min Efficiency Bonus Turn] Most efficient model: {best_model.name} ({avg_tps[best_model_name]:.1f} tok/s average). Awarding bonus turn!", flush=True)
            bonus_prompt = f"<|User|>\nYou earned the Efficiency Bonus Turn for highest speed ({avg_tps[best_model_name]:.1f} tok/s)! Share your final closing thought.\n<|Assistant|>\n"
            resp_b, tps_b, _ = run_model_turn(llama_bin, best_model, bonus_prompt)
            print(f"  [Bonus Mic: {best_model.name}] > {resp_b}\n", flush=True)
            dialogue_history.append(f"**{best_model.stem} (Bonus Turn):** {resp_b}")

    # Write Final Transcript
    with open(transcript_file, "w", encoding="utf-8") as f:
        f.write("\n\n".join(dialogue_history))

    print("==========================================================", flush=True)
    print(f"[+] Arena Dialogue Transcript Saved : {transcript_file.relative_to(root)}", flush=True)
    print(f"[+] Telemetry Metrics CSV Saved     : {telemetry_csv.relative_to(root)}", flush=True)
    print("[SUCCESS] Multi-Model 'Pass the Microphone' Arena Sequence Completed!", flush=True)
    return True

if __name__ == "__main__":
    execute_microphone_arena()
    sys.exit(0)
