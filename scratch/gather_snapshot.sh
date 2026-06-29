#!/usr/bin/env bash
# ==========================================================================
# INGESTION HEADER: scratch/gather_snapshot.sh
# Purpose: Compiles a dynamic point-in-time snapshot ledger before trunk merges.
# ==========================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

TS="$(date +%Y%m%d_%H%M%S)"
SNAPSHOT_LOG="$PROJECT_ROOT/logs/test/pre_merge_snapshot_${TS}.md"

mkdir -p "$(dirname "$SNAPSHOT_LOG")"

{
    echo "# Forensic Workspace Snapshot Ledger"
    echo "Generated on: $(date -Iseconds)"
    echo "Host Kernel:  $(uname -srm)"
    echo "--------------------------------------------------------"
    echo ""
    
    echo "## 1. Parent Workspace Context (irislime)"
    echo "\`\`\`text"
    echo "Active Branch:  $(git branch --show-current 2>/dev/null)"
    echo "Current Commit: $(git rev-parse HEAD 2>/dev/null)"
    echo "Index Status:"
    git status --short
    echo "\`\`\`"
    echo ""

    echo "## 2. Submodule Engine Context (llama.cpp)"
    echo "\`\`\`text"
    if [ -d "llama.cpp" ]; then
        cd llama.cpp
        echo "Submodule Branch: $(git branch --show-current 2>/dev/null)"
        echo "Submodule Commit: $(git rev-parse HEAD 2>/dev/null)"
        echo "Submodule Status:"
        git status --short
        cd "$PROJECT_ROOT"
    else
        echo "[!] WARNING: Sibling symlink or submodule target missing at llama.cpp/"
    fi
    echo "\`\`\`"
    echo ""

    echo "## 3. Active Environmental Gate Variables"
    echo "\`\`\`text"
    echo "IRISLIME_READY=${IRISLIME_READY:-UNSET}"
    echo "ONEAPI_DEVICE_SELECTOR=${ONEAPI_DEVICE_SELECTOR:-UNSET}"
    echo "GGML_OPENVINO_DEVICE=${GGML_OPENVINO_DEVICE:-UNSET}"
    echo "\`\`\`"
    echo ""

    echo "## 4. Platform Tracker Backlog State"
    echo "### Open Issues:"
    echo "\`\`\`text"
    gh issue list --limit 10 2>/dev/null || echo "GitHub CLI Query Deferred"
    echo "\`\`\`"
    echo ""
    echo "### Open Pull Requests:"
    echo "\`\`\`text"
    gh pr list --limit 10 2>/dev/null || echo "GitHub CLI Query Deferred"
    echo "\`\`\`"
} > "$SNAPSHOT_LOG"

echo "[+] Workspace snapshot compiled successfully with live variables."
echo "    |-- Destination: logs/test/$(basename "$SNAPSHOT_LOG")"
echo "    \\-- Core Hash:   $(sha256sum "$SNAPSHOT_LOG" | awk '{print $1}')"

# ==========================================================================
# EPILOG: End of File Descriptor for scratch/gather_snapshot.sh
# ==========================================================================
