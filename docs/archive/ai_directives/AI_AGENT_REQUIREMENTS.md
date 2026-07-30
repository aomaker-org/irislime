---
**PATH**: `docs/AI_AGENT_REQUIREMENTS.txt`  
**PURPOSE**: `Authoritative Operating Requirements and Guardrails for AGY and AI Agents.`  
**TARGET**: `AGY, Jules, Copilot, Gemini, ChatGPT, and Autonomous Coding Agents.`  
**LINEAGE**: `fekerr-dev / irislime Infrastructure`  
**UPDATED**: `20260718_120000`  
**Integrity-Hash**: `7891a23b456c789d012e345f678a901b234c567d890e123f456a789b012c345d`  
---

1. SYSTEM COMPREHENSION & ENVIRONMENT BOUNDARIES
* Target Host OS: Windows 11 64-bit (Intel Core 12th Gen Workstation Architecture).
* Container Runtime: Ubuntu 26.04 LTS / WSL2 Subsystem ONLY.
* Compiler Layer: MSVC v144 / Windows 11 SDK on Host; GCC/Clang/ICX on Linux.
* Python Execution: MUST execute via 'uv run' within local virtual environments.
  Do not pollute global environment layers.

2. AGENT SPECIFICATION & INGESTION PROTOCOL
* AGY Ingestion Files: Agentic configuration specifications are declared in:
  - fekerr-dev/irislime_ubu26_init/AGY_INGEST.agy
  - fekerr-dev/irislime_ubu26_init/provision_ubuntu26_init.agy
* Agent Ingestion Rules: Agents MUST read and parse these files to align
  subsystem environment parameters prior to executing cross-boundary build tasks.

3. SIMPLE ASCII INTERCHANGE FORMAT STANDARD
* Native Markdown (.md) working files suffer from nested markdown bugs and UI
  rendering truncation when passed through Web UI bots and automated agents.
* All new operational guidelines, documentation, and backlog ledgers MUST be
  written in Simple ASCII Text Format (.txt) utilizing structured ASCII headers
  and clear section dividers.
* Conversion Utility: Simple ASCII text files can be converted to Markdown
  using 'python tools/ascii2md.py <input.txt> [output.md]'.

4. IMMUTABLE ARCHIVAL AND ADDITIVE RULES
* Additive State Modifications: All workspace edits are presumed to be strictly
  additive unless directly specified otherwise.
* Branch Preservation: NEVER delete local or remote Git branches. All branches
  are permanently retained for lineage tracking.
* File Archival: Files are never permanently deleted from the tree. Deprecated
  or historical assets must be migrated into archive directories (e.g.,
  docs/archive/) or synchronized to cloud storage (Google Drive/OneDrive via rclone).

5. OBSERVABILITY AND LOGGING REQUIREMENTS
* Never pipe output streams to /dev/null without explicit comment justification.
* Log all execution traces using 'pipe2log' or 'pipe2clip' helpers.
* Session logging must capture execution metadata (git commit hash, timestamp,
  hardware profile).

6. AGY CREDIT & TOKEN PRESERVATION PROTOCOL
* Rate Monitoring: AGY consumption rates must be evaluated over a 5-hour window.
* 50% Threshold Gate: If credit/token consumption rate exceeds 50% of the 5-hour quota
  budget limit, the agent MUST immediately engage rate preservation mode.
* Cooldown & Throttling Protocol:
  - Pause execution 10 minutes out of every 5-minute work cycle (or execute backoff
    cooldown timers).
  - Prune context window payloads by omitting redundant raw log dumps.
  - Rely on localized script execution receipts rather than repeatedly reading massive
    source manifests.

---
**Integrity-Hash**: `7891a23b456c789d012e345f678a901b234c567d890e123f456a789b012c345d`  
**EOF**: `docs/AI_AGENT_REQUIREMENTS.txt`  
---