#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

mkdir -p pr-36/docs

cat << 'DOC1' > pr-36/docs/SUBMODULE_HYDRATION_ARCHITECTURE.txt
===============================================================================
SUBMODULE HYDRATION ARCHITECTURE AND BUILD INTERLOCK
===============================================================================

1. OVERVIEW
-------------------------------------------------------------------------------
This document specifies the on-demand engine submodule hydration pattern
implemented across IrisLime build blueprints (Requirement 10.30.30).

2. PROBLEM STATEMENT
-------------------------------------------------------------------------------
In fresh, unhydrated repository clones (or bare CI/CD environments where
'git clone --recurse-submodules' was omitted), core engine folders such as
llama.cpp/ exist as empty target directories. Executing 'make build' or direct
CMake configurations prior to hydration resulted in immediate build target
failures due to missing root CMakeLists.txt assets.

3. ARCHITECTURE AND IMPLEMENTATION
-------------------------------------------------------------------------------
A dynamic check-and-fetch guard target (check-engine-submodule) is injected
into infra/make/base.mk:

  .PHONY: check-engine-submodule

  check-engine-submodule:
	@if [ ! -f "$(ENGINE_DIR)/CMakeLists.txt" ]; then \
		echo "[irislime] Missing engine submodule detected at '$(ENGINE_DIR)'."; \
		echo "[irislime] Hydrating submodule on-demand via git..."; \
		git submodule update --init --recursive $(ENGINE_DIR); \
	fi

4. MODULE BINDING
-------------------------------------------------------------------------------
All engine target Makefiles (infra/make/vulkan.mk, sycl.mk, openvino.mk) list
check-engine-submodule as a strict prerequisite:

  build-vulkan: check-engine-submodule
  build-sycl: check-engine-submodule
  build-openvino: bootstrap-headers check-engine-submodule

5. VERIFICATION
-------------------------------------------------------------------------------
Verified during AGY Task 40. The runner intercepted the un-hydrated submodule
state (-660e63f), triggered an on-demand clone, checked out the target commit,
and proceeded to compile 7,918 SPIR-V compute modules without failure.
DOC1

cat << 'DOC2' > pr-36/docs/AGY_RUNNER_AND_FORENSIC_LOGGING.txt
===============================================================================
AGY TASK EXECUTION AND FORENSIC LOGGING PROTOCOL
===============================================================================

1. OVERVIEW
-------------------------------------------------------------------------------
The AGY task framework provides an isolated, deterministic execution wrapper
for review mechanics, task queuing, and automated remediation passes inside
pr-36/agy/.

2. CORE PRINCIPLES
-------------------------------------------------------------------------------
* Zero Stream Loss (No Null Piping):
  All stdout and stderr streams remain fully un-piped and visible to the
  terminal while simultaneously tee'd into timestamped log files.

* Forensic Traceability and Log Locking:
  Upon execution completion, task logs are set to read-only (chmod 444) to
  ensure forensic integrity:
  - Log location: pr-36/agy/logs/agy_<TASK_ID>_<TIMESTAMP>_<NNN>.log
  - Immutable read-only mode prevents accidental modification or overwriting.

* Isolated Review Scope:
  All transient scripts, queues, and task runners are strictly contained
  within pr-36/ to preserve core codebase cleanliness:
  - pr-36/agy/run_agy_task.sh: Generic task wrapper.
  - pr-36/agy/run_queue.sh: Sequential batch queue runner.
  - pr-36/agy/QUEUE.md: Execution manifest.

3. USAGE
-------------------------------------------------------------------------------
To execute a single task:
  bash pr-36/agy/run_agy_task.sh <TASK_ID> bash <PATH_TO_SCRIPT>

To run the full queued task list:
  bash pr-36/agy/run_queue.sh
DOC2

cat << 'DOC3' > pr-36/docs/BUILD_RUNNER_MONITORING_SPEC.txt
===============================================================================
BUILD RUNNER SMART MONITORING AND GUARDRAIL SPECIFICATION
===============================================================================

1. OVERVIEW
-------------------------------------------------------------------------------
Specification for process watchdog monitoring, dynamic resource guardrails, and
automated build error handling within tools/build_runner.py.

2. SPECIFICATIONS
-------------------------------------------------------------------------------
* Dynamic Disk Space Guardrail:
  To prevent compiler swap thrashing or out-of-disk crashes during large parallel
  compilation passes, disk capacity checks are evaluated dynamically:

    Required Free Disk Space = Total System RAM + 1 GB

  - Implementation: Inspected via psutil.virtual_memory().total and
    shutil.disk_usage().
  - Enforcement: Halts target execution early if free disk space is less than
    the required threshold.

* Dual-Metric Smart Watchdog:
  Replaces naive silence timers with dual-metric activity sensing:
  - CPU Load Tracking: Polling process tree utilization via psutil. Sustained
    CPU activity above 5 percent automatically resets the silence budget.
  - Log Stream Context (tail -f): Monitors os.stat(log_file).st_mtime and
    captures active compilation output lines to report context during quiet
    phases.

* Automated Error Diagnostics:
  When compilation fails with a non-zero exit code:
  - Extracts the tail 50 lines of compiler diagnostic output.
  - Invokes tools/claude_spot_fix.py to summarize failure points and prepare
    actionable git patches.
DOC3

chmod 644 pr-36/docs/*.txt
git add pr-36/docs/
echo "[+] Documentation generated and staged successfully under pr-36/docs/"
