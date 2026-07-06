# Architectural Design Specification: Advanced Watchdog & Thermal Management

## 1. Mitigating Buffer-Induced Watchdog Starvation

### 1.1 The Vulnerability
Standard output streams pipe text data through internal OS block allocations (typically 4KB pools under Windows/MSVC runtime layers) before flushing bytes to standard output. When executing deeply nested compilation passes, an execution tool can run for extended windows without completely filling a block, hiding terminal telemetry from the parent tracking queue and triggering false watchdog timeouts.

### 1.2 The Resolution Matrix
To prevent this output starvation, the toolchain enforces line-buffered flushing across all execution wrappers:
1. **Python Ingestion Core:** Force unbuffered streaming execution passes by injecting the `-u` parameter flag or setting `PYTHONUNBUFFERED=1` inside all active local environment tables.
2. **Subprocess Pipe Allocation:** `subprocess.Popen` invocations must specify `bufsize=1` (explicit line-level allocation mapping) to force immediate character transfers across subsystem boundaries.

---

## 2. Resource-Aware Intelligent Watchdogs

### 2.1 The Philosophy
A system working at maximum computational load must never be interrupted or killed by an automated monitoring script, regardless of log output constraints. Silence does not equal a hang if system counters confirm steady compute utilization.

### 2.2 The Implementation Blueprints
The monitoring thread will expand beyond checking console timestamps by tracking the live telemetry of the child process tree via Python's native `psutil` or direct system calls:

```python
# Conceptual Architecture: Resource-Aware Watchdog Guard
import psutil

def evaluate_process_vital_signs(child_pid):
    try:
        proc = psutil.Process(child_pid)
        cpu_percentage = proc.cpu_percentage(interval=0.5)
        memory_info = proc.memory_info()
        
        # If the process tree is actively consuming cycles, it is alive. 
        # Suppress timeout interrupts even if stdout is completely silent.
        if cpu_percentage > 10.0:
            return "ACTIVE_PROCESSING"
        return "IDLE_OR_STALLED"
    except psutil.NoSuchProcess:
        return "TERMINATED"
