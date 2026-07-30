#!/usr/bin/env python3
"""
PATH: pr-36/monitor_perf_counters.py
PURPOSE: Unified performance counter engine interrogating all Windows host 
         metric domains simultaneously in a single CIM pass with monospaced 
         table outputs, JSONL streaming, and PID-safe log rotation.
"""

import argparse
import datetime
import json
import logging
import os
import signal
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List, Any, Tuple


def generate_log_filenames(prefix: str, output_dir: str) -> Tuple[Path, Path]:
    """Generates unique, non-overwriting timestamped paths with microsecond & PID guards."""
    now = datetime.datetime.now(datetime.timezone.utc)
    now_str = f"{now.strftime('%Y%m%d_%H%M%S_%f')}_p{os.getpid()}"
    out_path = Path(output_dir)
    out_path.mkdir(parents=True, exist_ok=True)
    
    return out_path / f"{prefix}_{now_str}.log", out_path / f"{prefix}_{now_str}.jsonl"


def setup_logging(log_file: Path, verbose: bool) -> logging.Logger:
    """Configures dual console and file logging."""
    logger = logging.getLogger("PerfMonitor")
    logger.setLevel(logging.DEBUG if verbose else logging.INFO)

    log_format = logging.Formatter(
        "[%(asctime)s] [%(levelname)-5s] %(message)s", datefmt="%Y-%m-%d %H:%M:%S"
    )

    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(logging.DEBUG if verbose else logging.INFO)
    ch.setFormatter(log_format)
    logger.addHandler(ch)

    fh = logging.FileHandler(log_file, mode="a", encoding="utf-8")
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(log_format)
    logger.addHandler(fh)

    return logger


def query_all_perf_counters(logger: logging.Logger) -> Dict[str, Any]:
    """Queries all performance counter domains in a single, atomic PowerShell invocation."""
    ps_script = """
    $res = @{
        Thermal   = (Get-CimInstance Win32_PerfFormattedData_Counters_ThermalZoneInformation | Select-Object Name, Temperature)
        Processor = (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor | Where-Object { $_.Name -eq '_Total' } | Select-Object PercentProcessorTime, PercentInterruptTime)
        Memory    = (Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory | Select-Object AvailableMBytes, PageFaultsPerSec, PagesPerSec, CacheBytes)
        DiskIO    = (Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk | Where-Object { $_.Name -eq '_Total' } | Select-Object DiskReadsPerSec, DiskWritesPerSec, PercentDiskTime)
        System    = (Get-CimInstance Win32_PerfFormattedData_PerfOS_System | Select-Object Processes, Threads, ProcessorQueueLength, SystemUpTime)
    }
    $res | ConvertTo-Json -Compress
    """

    cmd = ["powershell.exe", "-NoProfile", "-Command", ps_script]

    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=12)
        if res.returncode != 0:
            logger.error(f"PowerShell query failed: {res.stderr.strip()}")
            return {}

        raw_output = res.stdout.strip()
        if not raw_output:
            return {}

        return json.loads(raw_output)

    except subprocess.TimeoutExpired:
        logger.warning("Timeout querying consolidated CIM counters.")
        return {}
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse JSON response: {e}")
        return {}
    except Exception as e:
        logger.exception(f"Unexpected error querying CIM counters: {e}")
        return {}


def process_telemetry_snapshot(raw_data: Dict[str, Any]) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
    """Transforms raw CIM payloads into flat telemetry rows and structured JSON metrics."""
    # 1. Thermal
    thermal_raw = raw_data.get("Thermal") or {}
    if isinstance(thermal_raw, list):
        thermal_raw = thermal_raw[0] if thermal_raw else {}
    temp_k = float(thermal_raw.get("Temperature", 273.15))
    temp_c = round(temp_k - 273.15, 1)
    temp_f = round((temp_c * 9/5) + 32, 1)

    # 2. Processor
    proc_raw = raw_data.get("Processor") or {}
    cpu_util = proc_raw.get("PercentProcessorTime", 0)
    cpu_intr = proc_raw.get("PercentInterruptTime", 0)

    # 3. Memory
    mem_raw = raw_data.get("Memory") or {}
    avail_mb = mem_raw.get("AvailableMBytes", 0)
    page_faults = mem_raw.get("PageFaultsPerSec", 0)
    pages_sec = mem_raw.get("PagesPerSec", 0)
    cache_mb = round(int(mem_raw.get("CacheBytes", 0)) / (1024 * 1024), 1)

    # 4. Disk IO
    disk_raw = raw_data.get("DiskIO") or {}
    disk_reads = disk_raw.get("DiskReadsPerSec", 0)
    disk_writes = disk_raw.get("DiskWritesPerSec", 0)
    disk_util = disk_raw.get("PercentDiskTime", 0)

    # 5. System
    sys_raw = raw_data.get("System") or {}
    procs = sys_raw.get("Processes", 0)
    threads = sys_raw.get("Threads", 0)
    cpu_queue = sys_raw.get("ProcessorQueueLength", 0)

    # Table representation
    table_rows = [
        {"Domain": "Thermal",   "Metric_1": f"Temp: {temp_c} C",       "Metric_2": f"Temp: {temp_f} F",      "Metric_3": "Status: COOL" if temp_c < 70 else "Status: WARM"},
        {"Domain": "Processor", "Metric_1": f"CPU: {cpu_util} %",      "Metric_2": f"Intr: {cpu_intr} %",    "Metric_3": f"Queue: {cpu_queue}"},
        {"Domain": "Memory",    "Metric_1": f"Avail: {avail_mb} MB",   "Metric_2": f"Faults/s: {page_faults}","Metric_3": f"Cache: {cache_mb} MB"},
        {"Domain": "DiskIO",    "Metric_1": f"Reads/s: {disk_reads}",  "Metric_2": f"Writes/s: {disk_writes}","Metric_3": f"DiskUtil: {disk_util} %"},
        {"Domain": "System",    "Metric_1": f"Procs: {procs}",         "Metric_2": f"Threads: {threads}",   "Metric_3": f"Pages/s: {pages_sec}"}
    ]

    # Clean JSON structured representation
    json_record = {
        "thermal": {"temp_c": temp_c, "temp_f": temp_f},
        "processor": {"cpu_util_pct": cpu_util, "interrupt_pct": cpu_intr, "queue_length": cpu_queue},
        "memory": {"avail_ram_mb": avail_mb, "page_faults_sec": page_faults, "pages_sec": pages_sec, "cache_mb": cache_mb},
        "disk_io": {"reads_sec": disk_reads, "writes_sec": disk_writes, "disk_util_pct": disk_util},
        "system": {"processes": procs, "threads": threads}
    }

    return table_rows, json_record


def format_monospaced_table(rows: List[Dict[str, Any]]) -> str:
    """Formats telemetry rows into a clean monospaced text table."""
    if not rows:
        return "No data."

    headers = ["Domain", "Metric_1", "Metric_2", "Metric_3"]
    widths = {h: len(h) for h in headers}

    for row in rows:
        for h in headers:
            widths[h] = max(widths[h], len(str(row.get(h, ""))))

    header_line = "  ".join(f"{h:<{widths[h]}}" for h in headers)
    divider_line = "  ".join("-" * widths[h] for h in headers)

    data_lines = []
    for row in rows:
        line = "  ".join(f"{str(row.get(h, '')):<{widths[h]}}" for h in headers)
        data_lines.append(line)

    return "\n".join([header_line, divider_line] + data_lines)


def write_jsonl_record(jsonl_file: Path, record: Dict[str, Any], logger: logging.Logger):
    """Appends a single structured JSON record line to the .jsonl stream."""
    try:
        with jsonl_file.open("a", encoding="utf-8") as f:
            f.write(json.dumps(record, separators=(",", ":")) + "\n")
    except Exception as e:
        logger.error(f"Failed to write record to JSONL log {jsonl_file}: {e}")


def main():
    parser = argparse.ArgumentParser(
        description="Unified Windows Host Performance Engine (WSL2 -> CIM).",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("-i", "--interval", type=int, default=10,
                        help="Sampling interval in seconds")
    parser.add_argument("-p", "--prefix", type=str, default="perf_metrics",
                        help="Prefix for generated log files")
    parser.add_argument("-o", "--output-dir", type=str, default="logs",
                        help="Directory to store timestamped logs")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Enable verbose debug logging")

    args = parser.parse_args()

    txt_log, jsonl_log = generate_log_filenames(args.prefix, args.output_dir)
    logger = setup_logging(txt_log, args.verbose)

    logger.info("=================================================================")
    logger.info("Starting Unified Performance Counter Interrogation Engine")
    logger.info(f"Sample Interval  : {args.interval}s")
    logger.info(f"Text Console Log : {txt_log}")
    logger.info(f"JSONL Stream Log : {jsonl_log}")
    logger.info("=================================================================")

    def signal_handler(sig, frame):
        logger.info(f"Received signal {sig}. Exiting cleanly.")
        sys.exit(0)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    sample_count = 0

    try:
        while True:
            sample_count += 1
            utc_now = datetime.datetime.now(datetime.timezone.utc).isoformat()
            logger.info(f"--- [Sample #{sample_count}] Consolidated Host Telemetry Pass ---")

            raw_data = query_all_perf_counters(logger)

            if raw_data:
                table_rows, json_record = process_telemetry_snapshot(raw_data)

                # Output Monospaced Table
                table_str = format_monospaced_table(table_rows)
                for line in table_str.split("\n"):
                    logger.info(line)

                # Append JSONL Record
                telemetry_payload = {
                    "timestamp": utc_now,
                    "sample": sample_count,
                    "metrics": json_record
                }
                write_jsonl_record(jsonl_log, telemetry_payload, logger)

            else:
                logger.warning("Failed to retrieve CIM telemetry snapshot.")

            time.sleep(args.interval)

    except Exception as e:
        logger.exception(f"Fatal error in telemetry loop: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
