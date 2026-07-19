# Interprocess & Intercomputer Communication Topology (`mtfdash` Architecture)

**Path:** `docs/INTERPROCESS_COMMUNICATION_TOPOLOGY.md`  
**Date:** July 18, 2026  
**Target:** Systems Architecture, `mtfdash` Mesh Engine, AGY Framework  

---

## 1. Executive Summary

`mtfdash` (v1.8.6) establishes a resilient node mesh across host environments (Windows 11 PowerShell 7) and guest subsystems (WSL2 Ubuntu 26.04 LTS). This document details the native **Local Disk Space Discovery & Communication Mesh** implemented in `mtfdash` and presents a comparative analysis of alternative Interprocess Communication (IPC) and Intercomputer Communication topologies.

---

## 2. Implemented Architecture: Local Disk-Based JSON Mesh

### 2.1 Mechanics
The primary `mtfdash` communication bus operates over the shared filesystem directory at [`logs/nodes/`](file:///home/fekerr/src/irislime/logs/nodes).

1. **Heartbeat Registration & Node Discovery:**
   * Every active node (Win11 PowerShell host or WSL Ubuntu CLI guest) maintains a registration state file: `logs/nodes/node_<node_id>.json`.
   * Node files record node identity, PID, OS capabilities (Intel oneAPI, OpenVINO, Python venv, rclone), ISO timestamps, and active narrative status.
   * Nodes scan `logs/nodes/*.json` every 5–15 seconds to discover active peers. Nodes silent for >15s are flagged as stale/dead.

2. **Atomic Write Protocol:**
   * To prevent file locks or partial-read corruption across Windows and WSL filesystem boundaries:
     * Payloads are written to a temporary file (`node_<id>.json.tmp`).
     * Files are atomically replaced using OS-level file replacement (`os.replace` / POSIX `rename`).

3. **Command Injection & Inbox Passing:**
   * Commands are dispatched by updating target node state files (`pendinginjectedcommand`).
   * Nodes poll their local inbox state, execute commands via background subprocessing, and log console output back to the shared narrative buffer.

### 2.2 Advantages & Trade-Offs
* **Pros:** Zero third-party dependencies, transparent human-auditable JSON logs, persistent across process restarts, seamless cross-OS interop (Windows <-> WSL2).
* **Trade-Offs:** Disk I/O latency (~1–5 ms), suitable for control-plane telemetry and task orchestration rather than high-frequency data streaming.

---

## 3. Alternative Interprocess Communication (IPC) Topologies

| Topology | Mechanics & Architecture | Pros | Cons | Best Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Local Disk File Mesh** *(Implemented)* | Shared JSON files in `logs/nodes/` using atomic file replacement. | Cross-platform, persistent, human-auditable, zero dependencies. | File I/O latency (~1–5ms), disk write endurance. | Node discovery, command injection, state sync. |
| **Named Pipes** | POSIX FIFOs (`/tmp/pipe`) / Win32 (`\\.\pipe\`). | Kernel-buffered, high throughput, low latency. | Windows & Linux pipe APIs are incompatible across WSL boundary. | Same-OS local process communication. |
| **Loopback Sockets (TCP/Unix Domain)** | Localhost TCP (`127.0.0.1:port`) or Unix Sockets (`/tmp/node.sock`). | Full-duplex streaming, sub-millisecond latency, standardized APIs. | Port allocation management, listener process lifetime binding. | High-frequency telemetry & streaming RPCs. |
| **Shared Memory (SHM)** | POSIX `shm_open` / Win32 `CreateFileMapping`. | Ultra-low latency (zero-copy memory speed, sub-microsecond). | Requires explicit mutexes/semaphores; non-trivial across WSL2 VM boundary. | High-volume tensor sharing between local GPUs/CPUs. |
| **VSOCK (Hyper-V Sockets)** | Linux-to-Hyper-V kernel socket bridge (`AF_VSOCK`). | Direct VM-to-Host communication without network stack overhead. | Platform-specific setup required in WSL kernel configs. | Low-level WSL-to-Host kernel IPC. |

---

## 4. Intercomputer & Remote Mesh Topologies

When expanding `mtfdash` beyond a single host machine to multi-node clusters across network boundaries:

### 4.1 HTTP REST & Server-Sent Events (SSE)
* **Description:** Lightweight HTTP server exposing status endpoints and SSE streams for real-time model loading updates (as utilized in `llama.cpp` `/models/sse`).
* **Fit:** Web UI integration, agent status dashboards, multi-node web API clients.

### 4.2 gRPC / Protocol Buffers
* **Description:** High-performance, strongly typed binary RPC protocol running over HTTP/2.
* **Fit:** Multi-node distributed inference clusters, subagent coordination across dedicated compute nodes.

### 4.3 Pub/Sub Message Brokers (MQTT / NATS)
* **Description:** Centralized or distributed broker where nodes publish heartbeats to topics (e.g. `cluster/nodes/heartbeat`) and subscribe to command queues.
* **Fit:** Large-scale multi-computer node clusters with dynamic join/leave topologies.

### 4.4 Cloud Storage Transport Bus (`rclone` + Google Drive/S3)
* **Description:** Using `rclone` to push state manifests to a cloud remote path (`gdrive:cluster_mesh/nodes/`).
* **Fit:** Asynchronous multi-machine orchestration across geographically distributed development environments.

---

## 5. Verification & Tools Summary

* **Discovery Matrix Command:** `python3 tools/mtfdash_node_manager.py discover` (or `mtfdash-nodes`)
* **Command Injection:** `python3 tools/mtfdash_node_manager.py send-cmd <target|all> "<command>"` (or `mtfdash-send`)
* **Inbox Execution:** `python3 tools/mtfdash_node_manager.py process-inbox` (or `mtfdash-inbox`)
