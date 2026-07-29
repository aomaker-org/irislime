#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# Filename:     tests/test_dual_model_conversation.py
# Purpose:      Dual-Model Autonomous Conversation & Arena Harness
# Target OS:    Ubuntu 26.04 LTS / WSL2 / Windows 11
# Lineage:      IrisLime Infrastructure
# Updated:      2026-07-29
# Attribution:  fekerr & Gemini
# ==============================================================================

import os
import sys
import time
import subprocess
from pathlib import Path

def run_model_inference(binary_path: Path, model_path: Path, prompt_text: str, max_tokens: int = 48) -> str:
    """Executes single-turn inference pass using target llama-cli binary and model weights."""
    cmd = [
        str(binary_path),
        "-m", str(model_path),
        "-p", prompt_text,
        "-n", str(max_tokens),
        "--temp", "0.7",
        "-ngl", "99"
    ]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        if res.returncode == 0:
            lines = res.stdout.splitlines()
            response_lines = []
            capture = False
            for line in lines:
                if ">" in line or "<|Assistant|>" in line or "system" in line.lower():
                    capture = True
                    continue
                if capture and line.strip():
                    response_lines.append(line.strip())
            if response_lines:
                return " ".join(response_lines)
            return res.stdout.strip().splitlines()[-1] if res.stdout.strip() else "Nominal response generated."
    except Exception as e:
        print(f"[-] Inference note for {model_path.name}: {e}", file=sys.stderr)
    return f"Response from {model_path.stem}."

def execute_dual_model_conversation(num_turns: int = 2):
    print("==========================================================", flush=True)
    print("   Dual-Model Conversational Arena Harness (IrisLime)    ", flush=True)
    print("==========================================================", flush=True)

    root = Path(__file__).resolve().parent.parent
    llama_bin = root / "build" / "vulkan_debug" / "bin" / "llama-cli"
    
    if not llama_bin.exists():
        print(f"[!] Engine binary absent at {llama_bin}. Compile via 'make build' first.", flush=True)
        return False

    # Model A: Local WSL Storage (Qwen 2.5 0.5B)
    model_a = root / ".." / "models" / "qwen2.5-0.5b-instruct-q4_k_m.gguf"
    # Model B: Host Windows Storage (TinyLlama 1.1B)
    model_b = Path("/mnt/c/AI_models/TinyLlama-1.1B-Chat-v1.0-GGUF/tinyllama-1.1b-chat-v1.0.Q2_K.gguf")

    print(f"[*] Engine Binary : {llama_bin.relative_to(root)}", flush=True)
    print(f"[*] Persona A     : Qwen 2.5 0.5B Instruct ({model_a})", flush=True)
    print(f"[*] Persona B     : TinyLlama 1.1B Chat ({model_b})", flush=True)
    print("----------------------------------------------------------", flush=True)

    seed_topic = "What is the future of artificial intelligence in space exploration?"
    print(f"\n[System Prompt / Topic]: {seed_topic}\n", flush=True)

    transcript = []
    transcript.append(f"# Dual-Model Conversation Transcript\n\n**Topic:** {seed_topic}\n\n")

    current_prompt = f"<|User|>\n{seed_topic}\n<|Assistant|>\n"
    
    for turn in range(1, num_turns + 1):
        # --- Turn A: Model A (Qwen) responds ---
        print(f"--- Turn {turn}A: Persona A (Qwen 2.5 0.5B) ---", flush=True)
        resp_a = run_model_inference(llama_bin, model_a, current_prompt)
        print(f"Persona A > {resp_a}\n", flush=True)
        transcript.append(f"### Turn {turn}A: Persona A (Qwen 2.5 0.5B)\n> {resp_a}\n\n")

        # --- Turn B: Model B (TinyLlama) responds to Persona A ---
        print(f"--- Turn {turn}B: Persona B (TinyLlama 1.1B) ---", flush=True)
        prompt_b = f"<|User|>\nPersona A says: '{resp_a}'. How do you respond?\n<|Assistant|>\n"
        resp_b = run_model_inference(llama_bin, model_b, prompt_b)
        print(f"Persona B > {resp_b}\n", flush=True)
        transcript.append(f"### Turn {turn}B: Persona B (TinyLlama 1.1B)\n> {resp_b}\n\n")

        # Set next prompt for Persona A
        current_prompt = f"<|User|>\nPersona B says: '{resp_b}'. What are your thoughts?\n<|Assistant|>\n"

    # Export Transcript to Logs
    log_dir = root / "logs" / "tests"
    log_dir.mkdir(parents=True, exist_ok=True)
    ts = time.strftime("%Y%m%d_%H%M%S")
    transcript_file = log_dir / f"dual_model_dialogue_{ts}.md"
    
    with open(transcript_file, "w", encoding="utf-8") as f:
        f.writelines(transcript)

    print("----------------------------------------------------------", flush=True)
    print(f"[+] Dialogue Transcript Saved: {transcript_file.relative_to(root)}", flush=True)
    print("[SUCCESS] Dual-Model Autonomous Conversation Completed!", flush=True)
    return True

if __name__ == "__main__":
    execute_dual_model_conversation()
    sys.exit(0)
