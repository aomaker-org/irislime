#!/usr/bin/env python3
"""
20260624 copilot | Multi-method llama.cpp runner with forensic log capture.
Supports bare CLI usage and VS Code task integration.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple


@dataclass
class MethodSpec:
    name: str
    binary: Path
    args: List[str]
    env: Dict[str, str]


def now_ts() -> str:
    return time.strftime("%Y%m%d_%H%M%S")


def project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def relpath(path: Path, root: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def detect_sycl_device(sycl_bin: Path, timeout_sec: int = 10) -> Optional[str]:
    if not sycl_bin.exists():
        return None

    try:
        proc = subprocess.run(
            [str(sycl_bin), "--list-devices"],
            text=True,
            capture_output=True,
            timeout=timeout_sec,
            check=False,
        )
    except Exception:
        return None

    output = f"{proc.stdout}\n{proc.stderr}"
    for line in output.splitlines():
        m = re.match(r"\s*(SYCL\d+):", line)
        if m:
            return m.group(1)
    return None


def run_case(
    root: Path,
    logs_dir: Path,
    ts: str,
    model: Path,
    prompt: str,
    n_predict: int,
    timeout_sec: int,
    method: MethodSpec,
) -> Tuple[str, str, str, Path]:
    case_log = logs_dir / f"{method.name}_{ts}.log"

    if not method.binary.exists():
        case_log.write_text(
            "=== CASE: {} ===\nmissing binary: {}\n".format(method.name, method.binary),
            encoding="utf-8",
        )
        return method.name, "EMPTY", "N/A", case_log

    cmd: List[str] = [
        str(method.binary),
        "--model",
        str(model),
        "--conversation",
        "--simple-io",
        "--n-predict",
        str(n_predict),
    ] + method.args

    env = os.environ.copy()
    env.update(method.env)

    header = [
        f"=== CASE: {method.name} ===",
        f"timestamp: {time.strftime('%Y-%m-%dT%H:%M:%S%z')}",
        f"binary: {method.binary}",
        f"model: {model}",
        f"args: {' '.join(method.args) if method.args else '(none)'}",
        f"env_overrides: {method.env if method.env else '(none)'}",
        "",
    ]

    payload = f"{prompt}\n/exit\n"

    status = "PASS"
    exit_text = "0"
    out = ""
    err = ""

    try:
        proc = subprocess.run(
            cmd,
            input=payload,
            text=True,
            capture_output=True,
            timeout=timeout_sec,
            check=False,
            env=env,
        )
        out = proc.stdout
        err = proc.stderr
        code = proc.returncode
        exit_text = str(code)
        if code != 0:
            status = "FAIL"
    except subprocess.TimeoutExpired as ex:
        status = "TIMEOUT"
        exit_text = "TIMEOUT"
        out = ex.stdout or ""
        err = ex.stderr or ""
    except Exception as ex:  # defensive capture for forensics
        status = "ERROR"
        exit_text = "ERROR"
        err = f"runner exception: {ex}\n"

    combined = f"{out}\n{err}"
    error_markers = [
        r"ov::Exception",
        r"Compute error",
        r"failed to decode",
        r"graph_compute: .*failed",
        r"Segmentation fault",
        r"error while handling argument",
    ]
    if status == "PASS":
        for marker in error_markers:
            if re.search(marker, combined, flags=re.IGNORECASE):
                status = "FAIL"
                if exit_text == "0":
                    exit_text = "LOG_ERROR"
                break

    with case_log.open("w", encoding="utf-8") as f:
        f.write("\n".join(header))
        if out:
            f.write("[STDOUT]\n")
            f.write(out)
            if not out.endswith("\n"):
                f.write("\n")
        if err:
            f.write("[STDERR]\n")
            f.write(err)
            if not err.endswith("\n"):
                f.write("\n")
        f.write(f"[RESULT] status={status} exit={exit_text}\n")

    return method.name, status, exit_text, case_log


def build_methods(root: Path, openvino_device: str) -> List[MethodSpec]:
    cpu_release = root / "build" / "cpu_release" / "bin" / "llama-cli"
    cpu_debug = root / "build" / "cpu_debug" / "bin" / "llama-cli"
    sycl_release = root / "build" / "sycl_release" / "bin" / "llama-cli"
    openvino_release = root / "build" / "openvino_release" / "bin" / "llama-cli"
    vulkan_release = root / "build" / "vulkan_release" / "bin" / "llama-cli"

    sycl_dev = detect_sycl_device(sycl_release)
    sycl_args = ["--n-gpu-layers", "99"]
    sycl_name = "sycl_release_auto"
    if sycl_dev:
        sycl_name = f"sycl_release_{sycl_dev}"
        sycl_args += ["--device", sycl_dev]

    return [
        MethodSpec("cpu_release_ngl0", cpu_release, ["--n-gpu-layers", "0"], {}),
        MethodSpec("cpu_debug_ngl0", cpu_debug, ["--n-gpu-layers", "0"], {}),
        MethodSpec(sycl_name, sycl_release, sycl_args, {}),
        MethodSpec(
            "openvino_release",
            openvino_release,
            ["--n-gpu-layers", "99", "--single-turn", "--n-predict", "1"],
            {"GGML_OPENVINO_DEVICE": openvino_device, "GGML_OPENVINO_DISABLE_CACHE": "1"},
        ),
        MethodSpec("vulkan_release", vulkan_release, ["--n-gpu-layers", "99"], {}),
    ]


def parse_args() -> argparse.Namespace:
    root = project_root()
    parser = argparse.ArgumentParser(description="Run llama.cpp multiple ways with forensic logs")
    parser.add_argument(
        "--model",
        default=str(root / "models" / "tinyllama-1.1b-chat-v1.0.Q2_K.gguf"),
        help="GGUF model path",
    )
    parser.add_argument(
        "--prompt",
        default="The quick brown fox jumps over the lazy dog.",
        help="Prompt for first input line",
    )
    parser.add_argument("--n-predict", type=int, default=16, help="Max generated tokens")
    parser.add_argument("--timeout-sec", type=int, default=45, help="Timeout per method")
    parser.add_argument(
        "--openvino-device",
        default=os.environ.get("GGML_OPENVINO_DEVICE", "GPU"),
        help="OpenVINO device (GPU/CPU/NPU/AUTO)",
    )
    parser.add_argument(
        "--logs-dir",
        default=str(root / "logs" / "test"),
        help="Directory for result logs",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = project_root()
    model = Path(args.model).resolve()
    logs_dir = Path(args.logs_dir).resolve()
    logs_dir.mkdir(parents=True, exist_ok=True)

    if not model.exists():
        print(f"[!] Model not found: {model}")
        return 2

    ts = now_ts()
    summary_log = logs_dir / f"llama_multi_capture_{ts}.log"

    methods = build_methods(root, args.openvino_device)

    lines: List[str] = []
    lines.append("============================================================")
    lines.append("LLAMA MULTI CAPTURE RUN (PY)")
    lines.append(f"timestamp: {time.strftime('%Y-%m-%dT%H:%M:%S%z')}")
    lines.append(f"model: {model}")
    lines.append(f"prompt: {args.prompt}")
    lines.append(f"n_predict: {args.n_predict}")
    lines.append(f"timeout_sec: {args.timeout_sec}")
    lines.append(f"openvino_device: {args.openvino_device}")
    lines.append("============================================================")
    lines.append("")
    lines.append("| Method | Status | Exit | Log |")
    lines.append("| :--- | :--- | :--- | :--- |")

    print("\n".join(lines[:-2]))
    print(lines[-2])
    print(lines[-1])

    failures = 0
    for method in methods:
        name, status, exit_text, case_log = run_case(
            root=root,
            logs_dir=logs_dir,
            ts=ts,
            model=model,
            prompt=args.prompt,
            n_predict=args.n_predict,
            timeout_sec=args.timeout_sec,
            method=method,
        )
        if status not in {"PASS", "EMPTY"}:
            failures += 1
        row = f"| {name} | {status} | {exit_text} | {relpath(case_log, root)} |"
        print(row)
        lines.append(row)

    lines.append("")
    lines.append(f"summary_log: {relpath(summary_log, root)}")

    summary_log.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"summary_log: {relpath(summary_log, root)}")

    return 0 if failures == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
