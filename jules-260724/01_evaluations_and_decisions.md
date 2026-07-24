# Evaluation and Decisions Log

This document records the evaluation of the user's prompt based on best practices, outlining which suggestions are accepted, adapted, or challenged.

## 1. Refactoring to `irislime/irislime`
**User Prompt:** Consider refactoring irislime into new anchor root irislime and "push" everything else down to `./irislime/irislime`.
**Evaluation (Challenged):** Moving everything down one extra directory layer (`irislime/irislime/`) creates unnecessary deep nesting. It also poses a significant risk to the environment due to Windows path-length limits (as this is developed on a Windows host using WSL2). Additionally, this repository explicitly uses a symlink structure for `llama.cpp` (it expects to be a sibling of the root), and deeply nesting the repo would require re-linking or breaking the current integration logic.
**Decision:** Do not push the repo down to `irislime/irislime`. Instead, maintain the current structure but consider placing any new isolated tools in dedicated top-level directories (e.g. `jules-ai/`) without disrupting the root `irislime` environment constraints.

## 2. OCI Standard Containers
**User Prompt:** Consider open oci standard and define multiple containers to build with various build settings and targets.
**Evaluation (Accepted):** A solid best practice for reproducible builds and standardizing test environments.
**Decision:** Implement an initial `Containerfile.matrix` in the `infra/` folder mapping out multi-stage builds. Since release builds are an eventual target for benchmarking, the container will map stages for Debug, Profile, and RelWithDebInfo targets.

## 3. Read-Only Filesystem Attributes
**User Prompt:** Always append or create new files. Do not overwrite files. Consider maintaining read-only a filesystem attributes on all files to facilitate/assist this.
**Evaluation (Challenged for source, Accepted for logs):** Applying read-only filesystem attributes to all files globally breaks typical `git` workflows (e.g. checking out branches, running `git reset`, standard developer iteration).
**Decision:** I will respect the "append or create new files" mandate for my own agent actions. For filesystem attributes, I will create a script `tools/enforce_readonly.sh` that demonstrates selectively locking down specific archived logs and old source data to enforce immutability without crippling Git operations.

## 4. Gitoxide (`gix`) and Manifest Tools
**User Prompt:** Look at gix* Rust tools that are Git-compatible. Consider manifest tools and methods to track the repo... that can be "rcloned".
**Evaluation (Accepted):** Managing large logs efficiently in Git is notoriously difficult. `gix` is faster for read-only Git repository interactions. Utilizing external manifests and syncing tools like `rclone` (which the user is already using as evidenced by `rclone_20260714_1240p_metadata.sh`) makes sense for "cold storage."
**Decision:** Recommend DVC (Data Version Control) or Git-LFS if large logs are to remain tracked, or sticking strictly to `rclone` with checksum manifests for cold storage to avoid bloating the Git history. No sweeping structural changes to Git will be forced at this time without explicit `gix` toolchain installation, but it will be documented as the path forward for telemetry.

## 5. Dynamic Makefile
**User Prompt:** Consider Makefile that can dynamically adapt depending on enabled *.mk in subdirectories... allow missing trees.
**Evaluation (Accepted):** Make natively supports dynamic inclusion and missing trees via `wildcard` and `-include`.
**Decision:** Create a prototype `Makefile.dynamic` to demonstrate how Make can optionally build targets based on the presence of `.mk` versus disabled `_mk` extensions.