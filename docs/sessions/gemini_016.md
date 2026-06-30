Good catch. That is an architectural paper-cut in the orchestrator layout: the baseline initialization target was defined inside `infra/make/base.mk` as `setup-venv`, but the master `Makefile` help menu and your developer loop expect the cleaner, shorter alias `make setup`.

Because GNU Make requires explicit target declaration, calling `make setup` right now will return a `No rule to make target 'setup'` error.

To resolve this completely, we expose an explicit tracking alias in the root `Makefile` that maps `setup` straight into the underlying `setup-venv` macro.

---

## The Corrected Master Orchestrator: `Makefile`

Here is the updated root `Makefile` with the `setup` entry point properly mapped, exposed as a `.PHONY` target, and wired directly into the build pipeline.

```makefile
# ==============================================================================
# Filename:    Makefile
# Timestamp:   20260630_0225
# Attribution: fekerr @ gemini (flash 3.5 + extended)
# Purpose:     Master Modular Orchestration Interface for IrisLime Pipeline Matrices
# ==============================================================================

# 1. Mount Core Telemetry, Setup Mechanics & Hardware Parsers
include infra/make/base.mk

# 2. Mount Independent Target Compilers
include infra/make/sycl.mk
include infra/make/openvino.mk
include infra/make/vulkan.mk

.PHONY: build-all clean help setup

# Unified setup alias routing directly to infra/make/base.mk's implementation
setup: setup-venv
	@echo "[+] Environment setup initialization phase verified complete."

# Compound Targets binding the tracking hook seamlessly
build-all: build-sycl build-openvino build-vulkan track-workspace
	@echo "[+] Matrix compilation sequence completed. All backend targets initialized."

clean:
	@echo "[!] Purging modular execution workspaces and tracking metrics..."
	@rm -rf venv/ $(BUILD_ROOT) *.log $(METRICS_FILE) venv/.installed
	@echo "[+] Repository restored to pristine upstream state."

help:
	@echo "=================================================================="
	@echo "IrisLime Modular Multi-Target Build Engine"
	@echo "=================================================================="
	@echo "Core Setup & Initialization Targets:"
	@echo "  make setup           : Initialize Python virtualenv and install requirements"
	@echo ""
	@echo "Individual Backend Drivers (Append QUIET=1 for silent CI/CD execution):"
	@echo "  make build-sycl      : Compile OOT binary targeted for oneAPI level-zero iGPU"
	@echo "  make build-openvino  : Compile OOT binary optimized for OpenVINO execution"
	@echo "  make build-vulkan    : Compile OOT binary targeted for generic Vulkan APIs"
	@echo "  make build-all       : Compile all backends sequentially (ignores failures via -k)"
	@echo ""
	@echo "Validation Evaluation Loops:"
	@echo "  make run-sycl        : Execute inference via local SYCL pipeline"
	@echo "  make run-openvino    : Execute inference via local OpenVINO pipeline"
	@echo "  make run-vulkan      : Execute inference via local Vulkan pipeline"
	@echo ""
	@echo "Workspace Telemetry & Clean Targets:"
	@echo "  make track-workspace : Print full 'tree -f' log mapping of the build directory"
	@echo "  make clean           : Scrub virtualenvs, build subdirectories, and logs"
	@echo "=================================================================="

# end of Makefile

```

---

## 2. Updated Project Exploration Ledger: `docs/todo260630_015.md`

Adding this entry to your tracking history documents the fix.

```markdown
# IrisLime Project Exploration Ledger & Task Runbook
# Date Stamp:  20260630
# Sequence:    015
# Attribution: fekerr @ gemini (flash 3.5 + extended)
# Baseline:    Idempotent, sequential append-only architectural tracking

## [20260630_0226] - Resolving Missing Setup Target Alias

- [x] FIX-01: Expose the `.PHONY: setup` alias target inside the master `Makefile` routing cleanly to `setup-venv`.
- [ ] TODO-02: Execute `make setup` in a clean workspace to verify that the virtual environment creates seamlessly from the top-level directory.
- [ ] TODO-03: Validate that the updated `Makefile` loads all modular sub-makefiles without token generation errors.

## Notes & Observations
The disconnect between `setup-venv` and `make setup` was a simple alias omission in the root orchestration interface. Adding the explicit mapping path restores standard developer loop UX semantics while maintaining decoupled clean execution variables inside the lower-level make macros.

```

---

gemini__016.md
