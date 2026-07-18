# ==============================================================================
# PATH:        tools/pipe2clip.py
# PURPOSE:     Executes a command, intercepts stdout/stderr with millisecond-accurate
#              delta-timing markers, and copies the formatted trace to the clipboard.
#              Parses local aliases and streams logs dynamically to the local disk.
# TARGET:      Ubuntu 26.04 LTS / WSL2 / LXC Subsystem
# LINEAGE:     fekerr-dev / Diagnostic Infrastructure
# UPDATED:     20260715_144500
# Integrity-Hash: e2e5e3a984b3b40426f3f2a2f3f8d077c6be7354d1f98c062431468663664d4a
# ==============================================================================

import sys
import os
import subprocess
import time
import threading
import queue
import shlex

def get_clipboard_command():
    if os.path.exists("/mnt/c/Windows/System32/clip.exe"):
        return ["/mnt/c/Windows/System32/clip.exe"]
    elif subprocess.call("type xclip", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0:
        return ["xclip", "-selection", "clipboard"]
    elif subprocess.call("type xsel", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0:
        return ["xsel", "--clipboard", "--input"]
    return None

def copy_to_clipboard(text):
    cmd = get_clipboard_command()
    if not cmd:
        sys.stderr.write("[!] Warning: No clipboard utility (clip.exe, xclip, xsel) detected.\n")
        return False
    try:
        proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        proc.communicate(input=text.encode("utf-8"))
        return proc.returncode == 0
    except Exception as e:
        sys.stderr.write(f"[!] Error writing to clipboard: {e}\n")
        return False

def load_alias_cache():
    cache_path = os.path.expanduser("~/.logs/shell/alias_cache")
    aliases = {}
    if os.path.exists(cache_path):
        try:
            with open(cache_path, "r") as f:
                for line in f:
                    if "=" in line:
                        key, val = line.strip().split("=", 1)
                        aliases[key.strip()] = val.strip()
        except Exception as e:
            sys.stderr.write(f"[-] Diagnostic: Failed to parse alias cache: {e}\n")
    return aliases

def stream_reader(stream, stream_name, queue, start_time):
    while True:
        line = stream.readline()
        if not line:
            break
        elapsed = time.monotonic() - start_time
        queue.put((elapsed, stream_name, line.rstrip("\n")))

def main():
    args = sys.argv[1:]
    if not args:
        sys.stdout.write("================================================================================\n")
        sys.stdout.write("PATH:        tools/pipe2clip.py\n")
        sys.stdout.write("USAGE:       uv run python tools/pipe2clip.py <command> [args...]\n")
        sys.stdout.write("================================================================================\n")
        return

    aliases = load_alias_cache()
    primary_executable = args[0]
    
    if primary_executable in aliases:
        expanded_target = aliases[primary_executable]
        sys.stdout.write(f"[*] Expanded alias '{primary_executable}' -> {expanded_target}\n")
        expanded_args = shlex.split(expanded_target)
        run_args = expanded_args + args[1:]
    else:
        run_args = args

    command_str = " ".join(run_args)
    sys.stdout.write(f"[*] Executing process: {command_str}\n")
    
    start_time = time.monotonic()
    timestamp_start_gmt = time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime())
    file_timestamp = time.strftime("%Y%m%d_%H%M%S")
    
    try:
        proc = subprocess.Popen(
            run_args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
    except Exception as e:
        sys.stderr.write(f"[!] Failed to initiate process: {e}\n")
        sys.exit(1)

    output_queue = queue.Queue()
    
    t_out = threading.Thread(target=stream_reader, args=(proc.stdout, "stdout", output_queue, start_time))
    t_err = threading.Thread(target=stream_reader, args=(proc.stderr, "stderr", output_queue, start_time))
    
    t_out.start()
    t_err.start()
    
    t_out.join()
    t_err.join()
    proc.wait()

    trace_lines = []
    trace_lines.append(f"================================================================================")
    trace_lines.append(f"DIAGNOSTIC RUN: {command_str}")
    trace_lines.append(f"STARTED AT:     {timestamp_start_gmt}")
    trace_lines.append(f"EXIT CODE:      {proc.returncode}")
    trace_lines.append(f"================================================================================")

    while not output_queue.empty():
        elapsed, stream, line = output_queue.get()
        formatted_line = f"[{elapsed:07.3f}] [{stream}]: {line}"
        trace_lines.append(formatted_line)
        # Mirror outputs to screen as they are parsed
        if stream == "stdout":
            sys.stdout.write(formatted_line + "\n")
        else:
            sys.stderr.write(formatted_line + "\n")

    trace_lines.append(f"================================================================================")
    final_payload = "\n".join(trace_lines) + "\n"

    # Write trace data to local logs directory
    log_dir = os.path.expanduser("~/src/fekerr-dev/logs")
    os.makedirs(log_dir, exist_ok=True)
    log_file_path = os.path.join(log_dir, f"diagnostic_run_{file_timestamp}.log")
    
    try:
        with open(log_file_path, "w", encoding="utf-8") as lf:
            lf.write(final_payload)
        sys.stdout.write(f"[+] Diagnostic log saved locally: {log_file_path}\n")
    except Exception as e:
        sys.stderr.write(f"[!] Warning: Failed to write trace log file: {e}\n")

    if copy_to_clipboard(final_payload):
        sys.stdout.write("[+] Diagnostic trace copied directly to clipboard!\n")
    else:
        sys.stderr.write("[!] Failed to copy final log data to clipboard.\n")

if __name__ == "__main__":
    main()
