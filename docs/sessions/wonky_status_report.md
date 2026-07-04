# Exhaustive Forensic Workspace Status Audit Ledger
Timestamp: 2026-06-27T17:24:37-07:00
Host:      LAPTOP-AJPE53SG
========================================================

## 💻 PART A: PARENT REPOSITORY [irislime]
### 1. Working Tree & Index Status
```text
On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	scratch/audit_all_status.sh
	scratch/wonky_status_report.md

nothing added to commit but untracked files present (use "git add" to track)
```

### 2. Branch Track Comparison (-vv)
```text
  feature/onboarding-and-testing-harness                    6f340a7 Build: Finalize snapshot utilities and update test discovery ledgers
* main                                                      114a638 [origin/main] capture work in progress
  remotes/origin/20260620                                   4bec749 fix(sycl): implement and document runtime stability patch
  remotes/origin/HEAD                                       -> origin/main
  remotes/origin/aomaker-org-llama-cpp-15714263644114602509 833695e feat: Update llama.cpp to aomaker-org fork, implement target cross-compile scripts, get-model functionality and documentation
  remotes/origin/checkpoint/irislime1-20260625_080811       44838ba Design-Checkpoint: Interim Sandbox Snapshot (20260625_080811)
  remotes/origin/feature/onboarding-and-testing-harness     6f340a7 Build: Finalize snapshot utilities and update test discovery ledgers
  remotes/origin/main                                       114a638 capture work in progress
  remotes/origin/refactor/migration                         957d2f9 Add multi-capture runners, OpenVINO healthcheck, and dual-mode test docs
```

### 3. Recent Commit Graph Head
```text
* 114a638 (HEAD -> main, origin/main, origin/HEAD) capture work in progress
* 4c5f219 capture work in progress as gemini session is getting wonky
* e80a58e Infrastructure: Consolidate Remote Auditing Tools and Hardened Compute Ledgers (#11)
* 32d0874 Workflow: Transition scratchpad architecture to transparent public tracking
* fc8448c Configuration: Sync parent submodule metadata with organization fork remote SSH string
* 9660377 Integration: Encapsulate llama.cpp dependency tree via secure submodule
*   61effb0 Merge pull request #4 from aomaker-org/refactor/migration
|\  
| * 957d2f9 (origin/refactor/migration) Add multi-capture runners, OpenVINO healthcheck, and dual-mode test docs
```

### 4. Remote Server Head Line Refs
```text
4bec749cd8f0ced7b47a520db537e6e63d525377	refs/heads/20260620
833695ea70e78e5fa53a1dd91d93b45400fe856a	refs/heads/aomaker-org-llama-cpp-15714263644114602509
44838bafa672b72d6ae8a69042de64cdcf9544fb	refs/heads/checkpoint/irislime1-20260625_080811
6f340a73aff3fe3d543dc06caaec06d5cf659333	refs/heads/feature/onboarding-and-testing-harness
114a638555dad50b31c87d175171d86c32ea1a88	refs/heads/main
957d2f9305312df082778949894f664036e66311	refs/heads/refactor/migration
```

### 5. GitHub Pull Request Matrix
```text
11	Infrastructure: Consolidate Remote Auditing Tools and Hardened Compute Ledgers	feature/onboarding-and-testing-harness	MERGED	2026-06-27T17:10:46Z
5	feat: Update llama.cpp to aomaker-org fork, implement target cross-compile scripts, get-model functionality and documentation	aomaker-org-llama-cpp-15714263644114602509	OPEN	2026-06-23T04:09:21Z
4	Refactor: Move to OOT build and flat structure	refactor/migration	MERGED	2026-06-20T21:11:05Z
1	fix(sycl): implement and document Level Zero runtime stability patch	20260620	OPEN	2026-06-20T17:29:23Z
```

### 6. GitHub Tracking Issue Matrix
```text
10	CLOSED	Tracking: Post-merge backend hardening wave (CPU/SYCL/OpenVINO/Vulkan)	documentation, tracking	2026-06-24T09:45:44Z
9	CLOSED	Vulkan backend bring-up plan and readiness criteria	documentation, enhancement, phase:vulkan	2026-06-24T09:45:42Z
8	CLOSED	OpenVINO runtime hardening and shape/cache edge cases	bug, documentation, enhancement, phase:openvino	2026-06-24T09:43:05Z
7	CLOSED	SYCL device selection and regression checks	documentation, enhancement, phase:sycl	2026-06-24T09:40:36Z
6	CLOSED	CPU execution stability and performance baseline	documentation, enhancement, phase:cpu	2026-06-24T09:37:35Z
3	CLOSED	getting started doesn't have all the magic to get started		2026-06-27T17:14:26Z
2	CLOSED	tools seems to be a submodule; llama.cpp should derive from a fork/clone in another repo		2026-06-27T17:14:24Z
```

## 🦙 PART B: SIBLING ENGINE FORK [llama.cpp]
### 1. Working Tree & Index Status
```text
On branch patch/intel-iris-gpu-optimizations
nothing to commit, working tree clean
```

### 2. Branch Track Comparison (-vv)
```text
  master                                            84de01a1f [origin/master] llama : use LLM_KV for quantization_version & file_type (#24802)
* patch/intel-iris-gpu-optimizations                e03c62427 Hardware: Port Intel Iris Xe optimization patches to validation stack
  remotes/origin/HEAD                               -> origin/master
  remotes/origin/master                             84de01a1f llama : use LLM_KV for quantization_version & file_type (#24802)
  remotes/origin/patch/intel-iris-gpu-optimizations e03c62427 Hardware: Port Intel Iris Xe optimization patches to validation stack
```

### 3. Recent Commit Graph Head
```text
* e03c62427 (HEAD -> patch/intel-iris-gpu-optimizations, origin/patch/intel-iris-gpu-optimizations) Hardware: Port Intel Iris Xe optimization patches to validation stack
* 84de01a1f (origin/master, origin/HEAD, master) llama : use LLM_KV for quantization_version & file_type (#24802)
* 75f460ac2 arg: try fixing test-args-parser randomly fails (#24826)
* 845282461 release: add missing link for win opencl adreno arm64 (#24809)
* e27f30859 server: avoid forwarding auth headers in CORS proxy (#24373)
```

### 4. Remote Server Head Line Refs
```text
928528c1b2831482040b9d37c5afa82b7ec5ea71	refs/heads/feature/sycl-openvino-intel-patches
84de01a1f1c847292b8d90a9c0bff6619f2919be	refs/heads/master
e03c62427686aa04ed34e21e08d4dbdbc86e38ee	refs/heads/patch/intel-iris-gpu-optimizations
```

