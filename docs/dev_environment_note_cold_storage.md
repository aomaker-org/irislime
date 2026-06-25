# Dev Environment Note: Cold Storage (Local + Cloud-Aware)

Scope: local developer environment policy for this laptop/user, not irislime application behavior.

## Why this note exists

Your workspace needs a predictable way to keep active development fast while moving infrequently used large artifacts to cheaper storage.

This note defines a private, local strategy using:
- Windows-host-managed cold storage on G: and H:
- Windows-host-managed cloud sync via `rclone`
- WSL access to staged artifacts as a fallback/consumer path (not the primary storage control plane)

## Preferred architecture (recommended)

### Control plane: Windows host

Run storage-heavy operations on Windows directly:
- file moves between C:/G:/H:
- `rclone` sync/check/copy jobs
- retention cleanup and scheduling

Why:
- Avoids WSL mount edge cases and path translation surprises.
- Avoids heavy metadata I/O over `/mnt/*` from Linux userspace.
- Keeps storage management aligned with real laptop drive constraints.

### Compute plane: WSL

Use WSL for builds/inference/debugging only, and consume staged files from host-managed locations.

## Fallback architecture (acceptable, not primary)

WSL-driven archive/sync using `/mnt/g` and `/mnt/h` is still usable, but should be treated as secondary mode.

## Current environment check (2026-06-22)

- `rclone`: installed
- `/mnt/g`: mounted
- `/mnt/h`: not currently mounted in this WSL session

## Storage tiers

### Tier A: Hot (keep local in workspace)

Keep these in active workspace storage:
- Source code, build scripts, and small config files
- Active build target currently being debugged (e.g., `build/sycl_release`)
- Latest logs needed for current issue reproduction

### Tier B: Warm (local but outside workspace)

Move these to local archives on G:/H: and link back only when needed:
- Old build trees (`build/*` except current target)
- Historical benchmark outputs and matrix logs
- Old crash artifacts and debug traces

### Tier C: Cold (cloud/NAS/archive)

Store these off primary disk:
- Model variants not currently used
- Build snapshots by date
- Archived logs older than a retention window (e.g., 14-30 days)
- Forensic bundles from completed investigations

## What to move first (highest impact, lowest risk)

1. Non-active model files in `models/` (GGUF variants not under active test)
2. Old build matrix logs under `logs/build/matrix_*`
3. Old smoke/benchmark logs under `logs/test/*`
4. Non-active build targets under `build/`

## Recommended local folder layout on Windows drives

```text
G:/irislime_cold/
  models/
  build_snapshots/
  logs_archive/
  forensic_bundles/
  manifests/
```

If H: is available, use it as a second local copy:

```text
H:/irislime_mirror/
```

## rclone approach (multi-cloud aware, host-managed)

Use `rclone` to abstract one or more cloud remotes, with optional encrypted overlay.

### 1) Configure remotes (private, user-level)

```bash
rclone config
```

Suggested structure:
- `cloud_primary:` (e.g., OneDrive/Drive/S3)
- `cloud_backup:` (second provider)
- `cloud_primary_crypt:` (encrypted overlay on primary)

### 2) Keep secrets out of repo

- `rclone` credentials remain in user config (`~/.config/rclone/rclone.conf`)
- Do not commit credentials or tokens into workspace files

### 3) Sync patterns

Archive logs (dry-run first):

```bash
rclone sync G:/irislime_cold/logs_archive cloud_primary_crypt:irislime/logs_archive --dry-run
rclone sync G:/irislime_cold/logs_archive cloud_primary_crypt:irislime/logs_archive
```

Archive non-active models:

```bash
rclone copy G:/irislime_cold/models cloud_primary_crypt:irislime/models_archive --progress
```

Mirror cloud archive to second remote:

```bash
rclone sync cloud_primary_crypt:irislime cloud_backup:irislime_backup --progress
```

### 4) Verify after transfer

```bash
rclone check G:/irislime_cold/models cloud_primary_crypt:irislime/models_archive
```

## Minimal retention policy

- Keep in workspace:
  - Current model(s)
  - Current build target
  - Last 7 days of logs
- Archive to G:/H:/cloud:
  - Logs older than 7 days
  - Build trees not touched in 3+ days
  - Model variants unused in current sprint

## Safety rules

1. Copy, verify, then delete (never delete first)
2. Use `--dry-run` before first sync/move commands
3. Keep one local cold copy (G:/H:) plus one cloud copy for critical artifacts
4. Track archive actions in `copilot_20260622.md` for forensics

## Commands for quick visibility

Workspace pressure:

```bash
du -sh build logs models 2>/dev/null
```

Largest files in workspace:

```bash
find . -type f -size +200M -print | sort
```

Check cold storage mounts from WSL (fallback mode):

```bash
ls -ld /mnt/g /mnt/h 2>/dev/null
```

## Suggested next step

Create one lightweight, local-only script (not app logic) to:
- report large candidates
- stage archive to G:/irislime_cold (host-managed)
- optionally call `rclone` remotes if configured
