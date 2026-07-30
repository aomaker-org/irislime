# Workspace Specification & AI Directives (`AI.md`)

**Last Synced State:** July 29, 2026  
**Host Architecture:** Windows 11 (Intel Core 12th Gen) / WSL2 Ubuntu 26.04 LTS  
**Primary Repository Workspace:** `irislime`  
**Master Directives Specification:** [AI_DIRECTIVES_CONSOLIDATED.txt](file:///home/fekerr/src/irislime-pr-36/AI_DIRECTIVES_CONSOLIDATED.txt)

---

## Executive Overview & Architectural Directives

All AI agents (AGY, Jules, Copilot, Gemini, ChatGPT) operating within this codebase must adhere strictly to the consolidated specification defined in [AI_DIRECTIVES_CONSOLIDATED.txt](file:///home/fekerr/src/irislime-pr-36/AI_DIRECTIVES_CONSOLIDATED.txt).

### Core Guardrails Summary:
1. **System Comprehension & Boundaries**:
   - Host OS: Windows 11 64-bit (Intel Core 12th Gen Workstation).
   - Linux Environment: Ubuntu 26.04 LTS WSL2.
   - Python Execution: Route exclusively through `uv run` inside local `.venv`.
   - External Model Storage: Decoupled sibling path `../models/`.

2. **AGY Inbox / Outbox & Logging Workflow**:
   - Check `./inbox` on every turn for `*agy*` files, ingest, and move to `./inbox/archive/`.
   - Output turn status report in `./outbox/agy_nnn_turn_report.md` on every turn (Timestamp, incrementing index `nnn`, turn counter).
   - Log all prompts and responses in `./agy/log/`.

3. **Simple ASCII Text Standard**:
   - Primary working docs are maintained in `.txt` using structured ASCII headers to avoid markdown rendering truncation issues.
   - Convert to Markdown via `uv run python tools/ascii2md.py <input.txt> [output.md]`.

4. **Immutable Archival & Git History**:
   - Edits are strictly additive; historical AI directive files are archived under `docs/archive/ai_directives/`.
   - Historical Git commits remain preserved on remote branches; local removals are tracked in `agy/log/archival.log`.

5. **Observability & Token Preservation**:
   - Zero `/dev/null` stream discarding without explicit justification.
   - AGY token quota monitoring: engage throttling gates (10-minute cooldowns) if 5-hour usage exceeds 50%.

6. **Master Backlog Ledger**:
   - Consolidated master task list maintained in `TODO_CONSOLIDATED.txt`, numbered by 10s (`10.`, `20.`, `30.`, ...).
