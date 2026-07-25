# Evaluation and Decisions Log

This document records the evaluation of the user's prompt based on best practices, outlining which suggestions are accepted, adapted, or challenged.

## 1. Refactoring the repository organization
**User Prompt:** Consider refactoring irislime into new anchor root irislime and "push" everything else down to `./irislime/irislime`.
**Evaluation and Refinement:** While pushing everything down to `irislime/irislime/` creates deep nesting, the repository organization *does* need to be refactored to align with the structure of the `aomaker/edge-ai` repository. The core identity of `irislime` as the repository root must be maintained.
**Decision:**
- Maintain `irislime` as the root of the repository.
- Keep `config_env`, the anchored root `Makefile`, and `AI.md` at the root as anchoring objects.
- Utilize dedicated subdirectories (e.g., `gemini*`, `agy*`, `jules*`) to track usage of AI coding tools and agents.
- Leverage OCI containerization to work around multi-platform build problems and ensure stable environments.
- Verify Intel oneAPI compilers on Linux (they are indeed natively available on Linux for both C/C++ and Fortran).

## 2. OCI Standard Containers
**User Prompt:** Consider open oci standard and define multiple containers to build with various build settings and targets.
**Evaluation (Accepted):** A solid best practice for reproducible builds and standardizing test environments.
**Decision:** Implement an initial `Containerfile.matrix` in the `infra/` folder mapping out multi-stage builds. Since release builds are an eventual target for benchmarking, the container will map stages for Debug, Profile, and RelWithDebInfo targets.

## 3. Read-Only Filesystem Attributes (Artifacts vs Source)
**User Prompt:** Always append or create new files. Do not overwrite files. Consider maintaining read-only a filesystem attributes on all files to facilitate/assist this.
**Evaluation and Refinement:** Applying read-only attributes to files under active Git management breaks typical workflows. While it was considered for generated artifacts, read-only enforcement remains an open idea and may not be actively utilized.
**Decision:**
- Keep active source code writable for normal Git operations.
- The concept of enforcing read-only states on generated artifacts and telemetry data remains an open exploration.
- Created `tools/enforce_readonly.sh` purely as an experimental demonstration for locking down archived logs, rather than an enforced rule.
- Explore manifest/ledger methods (like `.stub` or `.pointer` files) to replace large local zip/tarball files on constrained machines, pointing to where they have been migrated in colder cloud storage.

## 4. Gitoxide (`gix`), Manifest Tools, and AI Model Management
**User Prompt:** Look at gix* Rust tools that are Git-compatible. Consider manifest tools and methods to track the repo... that can be "rcloned".
**Evaluation (Accepted):** Managing large assets (logs, telemetry, and specifically AI models) is critical to prevent clogging Git. `gix` provides fast, read-only Git repository interactions.
**Decision:**
- Document the necessity of using DVC (Data Version Control) or Git-LFS for tracking large files without bloating the Git history.
- Use `rclone` and chunker mounts (with stub/pointer files locally) for cold storage migration.
- **AI Model Tracking:** Models themselves should be tracked via these manifest tools, not committed to Git.
- **AI Training & Modularity:** Investigate segmented/modular models. For example, Mixture of Experts (MoE) architectures only activate specific subsets of parameters during inference. This is a crucial concept for local, memory-constrained Edge AI and should be explored further to assist with the user's AI technology training.

## 5. Dynamic Makefile
**User Prompt:** Consider Makefile that can dynamically adapt depending on enabled *.mk in subdirectories... allow missing trees.
**Evaluation (Accepted):** Make natively supports dynamic inclusion and missing trees via `wildcard` and `-include`.
**Decision:** Create a prototype `Makefile.dynamic` to demonstrate how Make can optionally build targets based on the presence of `.mk` versus disabled `_mk` extensions.

## 6. Runner Execution Configuration Refactoring
**User Prompt:** Scaffold or document a plan to refactor `matrix_control.json` into a commentable source code format (e.g., YAML or Python) placed in `./runner/*` to allow granular toggling of build targets/tests, evolving cleanly with OCI.
**Evaluation (Accepted):** JSON does not support comments, which drastically reduces readability for human operators trying to toggle complex build matrices (like disabling `RelWithDebInfo` or experimental targets). Evolving this into YAML inside a dedicated `runner/` namespace aligns with standard CI/CD and OCI container practices.
**Decision:**
- Re-scaffolded `RelWithDebInfo` profiles but explicitly set them to `"enabled": false` to preserve the historical tree options without forcing them to build.
- Created `runner/matrix_control.yaml` as a blueprint showing how configuration can be nested with human-readable explanations, root-level and target-level switches, and parameter definitions.
- The next step in this project lifecycle will be updating `build_runner.py` and `test_runner.py` to ingest this YAML format natively, unifying the test and build pipelines under the `runner/` infrastructure.