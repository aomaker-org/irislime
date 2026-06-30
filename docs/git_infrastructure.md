3. The Onboarding Runbook: docs/git_infrastructure.md
This document serves as the human-readable architectural blueprint, explaining the engineering choices behind the repo configuration and detailing exact recovery commands for drift states.

Markdown
# Irislime Git Infrastructure & Telemetry Configuration Runbook

## Overview
To maintain an authentic, non-destructive, and un-squashed development chronicle, the **Irislime** architecture rejects brute-force `git reset` commands. Instead, it relies on an idempotent **Git Smudge and Clean Content Filter Framework** to automatically pass execution telemetry to both human engineers and out-of-process AI agents.

This document describes the mechanics of this pipeline and serves as an onboarding guide and diagnostic ledger.

---

## Technical Design Rationale

### The Metadata Loop Strategy
Hardcoding active branch states and git hashes directly into scripts causes immediate repository contamination; local environments drift, and git tracks the changes as local modifications. We solve this by splitting the files into two distinct physical contexts:

1. **The Object Store State (Clean):** Inside the central Git object tree, variables are held as immutable string declarations: `INTEGRITY_COMMIT="TODO"`.
2. **The Working Tree State (Smudged):** Upon checking out or cloning a branch, the local Git runtime routes the files through an inline stream editor (`sed`), injecting the active local commit hash and branch topology directly onto disk.

This keeps all tracking operations fully automated, isolated, and safe from unintended modifications.

---

## Operational Onboarding Steps

When setting up a clean clone of the repository, execute the initialization process exactly as outlined below:

```bash
# 1. Onboard the repository configuration suite
# This registers the smudge/clean algorithms into your localized .git/config binary footprint
bash infra/setup_filters.sh

# 2. Source your localized shell environment matrix
source config_env
Once executed, your terminal prompt dynamically updates to match the telemetry schema:
[irislime][active_branch:short_commit_sha] /working/directory $

Troubleshooting & Forensic Remediation Protocols
Symptom A: Metadata fields display old tracking states or literal "TODO" strings
This indicates the local Git configuration has either lost its filter mapping tracking data or the local files were instantiated prior to executing the initialization suite.

Remediation Script:

Bash
# Force-refresh the local tracking state
git config --unset-all filter.irislime_telemetry.smudge || true
bash infra/setup_filters.sh
Symptom B: Forcing an explicit Working Tree Re-Smudge
If you need to manually force Git to re-process all file templates across the smudge processing engines without modifying or dropping your uncommitted file edits:

Bash
# Force a clean, non-destructive index reload
git checkout HEAD -- config_env infra/bootstrap_models.sh
Symptom C: Recovering Raw Forensic Evidence from AI Drift Sessions
If an AI session causes significant architectural drift or consumes all API context tokens, do not squash or drop the history. Isolate the environment using a non-destructive tracking branch:

Bash
# 1. Snapshot the current drifted system state to an analytical track
git checkout -b forensics/ai-drift-session-$(date +%Y%m%d)

# 2. Add structural notes detailing the failure constraints
git commit -am "chore: capture raw telemetry and context state of drifted AI execution session"

# 3. Pivot back to your primary engineering line to cleanly port structural repairs
git checkout develop
end of git_infrastructure.md
