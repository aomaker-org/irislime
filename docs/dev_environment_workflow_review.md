# Dev Environment Workflow Review

Scope: local/private workflow hygiene for this laptop user. This is not application logic.

Date: 2026-06-22

## Summary

Current workflow is functional but shows a few anti-patterns that can cause inconsistency:
- Mixing Linux root free-space checks with Windows C: constraints.
- Starting long builds without a single preflight that validates storage mounts/remotes.
- Allowing archive behavior to depend on ad-hoc mount availability (`/mnt/g`, `/mnt/h`).
- Treating all cloud remotes equally even though capacities differ.

This review proposes a cleaner, deterministic policy.

## Architecture decision

Primary mode:
- Storage and cloud sync are managed at Windows host level.
- WSL is used for compute tasks (build/test/inference) and consumes staged files.

Fallback mode:
- WSL mount-driven storage workflows (`/mnt/g`, `/mnt/h`) are permitted only when host automation is unavailable.

## Observed environment facts

- `rclone` is installed.
- Current remotes detected: `gaom:`, `onedrive:`, `onedrive0:`.
- `/mnt/g` currently mounted.
- `/mnt/h` may be unavailable in some sessions.
- User constraint: keep at least 40 GB free on Windows C: (`/mnt/c`).

## Likely anti-patterns and corrective actions

### Anti-pattern 1: Disk guard reads wrong filesystem

Symptom:
- WSL root (`/`) showed large free space while C: was constrained.

Fix:
- Always run space policy against `/mnt/c` (or explicit guard path).
- Keep threshold as a hard gate before build/archive workflows.

### Anti-pattern 2: Manual archive decisions per run

Symptom:
- Different targets moved each time based on what feels large.

Fix:
- Define deterministic archive classes:
  1. stale build trees
  2. old logs
  3. inactive model variants
- Apply retention windows (e.g., 7/14/30 days) consistently.

### Anti-pattern 3: Mount-dependent failures

Symptom:
- `/mnt/h` absent can break assumptions.

Fix:
- Prefer host-managed storage orchestration (Windows path semantics, host scheduler).
- If WSL fallback is used, enforce mount fallback chain:
  1. stage to `/mnt/g/irislime_cold`
  2. mirror to `/mnt/h/irislime_mirror` only if mounted
  3. cloud sync remains optional but preferred for long-term retention

### Anti-pattern 4: Cloud target ambiguity

Symptom:
- Sending large archives to smaller OneDrive tier can overflow or fragment policy.

Fix:
- Prioritize remotes by expected capacity and role:
  1. `gaom:` -> primary bulk archive (Google space)
  2. `onedrive:` / `onedrive0:` -> metadata + high-value compact artifacts (smaller capacity tier)

### Anti-pattern 5: Running storage control plane under WSL by default

Symptom:
- Heavy move/sync tasks executed from WSL can inherit mount quirks and performance penalties.

Fix:
- Run storage control-plane tasks from Windows host.
- Keep WSL scripts focused on compute and local reporting.

## Recommended storage policy

### Local-first staging

Primary staging root:
- `G:/irislime_cold/` (host-managed)

Optional mirror:
- `H:/irislime_mirror/` (host-managed)

### Cloud policy

Primary cloud (bulk):
- `gaom:irislime_archive/`

Secondary cloud (compact, high value):
- `onedrive:irislime_index/` or `onedrive0:irislime_index/`

### What goes where

- Bulk binaries/models/build snapshots -> `gaom:`
- Manifests/indexes/reports/checksums -> OneDrive remote
- Keep latest active artifacts local for performance

## Suggested operational workflow (clean)

1. Run preflight check (free-space policy + remotes + fallback mount status).
2. Run build/workload in WSL.
3. Stage archives via host path policy (G: primary, H: mirror if available).
4. Sync staged archive to `gaom:`.
5. Sync only indexes/manifests/checksums to OneDrive.
6. Verify (`rclone check`) before deleting local originals.

## Safety controls

- Never delete originals before successful verification.
- Always use `--dry-run` for first invocation after policy changes.
- Record archive action summary in `copilot_20260622.md`.

## Notes on privacy/scope

- This workflow remains private to this user/laptop.
- Secrets remain in `~/.config/rclone/rclone.conf` and never in repo files.
