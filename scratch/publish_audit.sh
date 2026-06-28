#!/usr/bin/env bash
# scratch/publish_audit.sh
# Portably aggregates remote branch configurations for portfolio tracking.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT_LOG="$PROJECT_ROOT/scratch/remote_branches_audit.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

{
    echo "# Remote Branch Architecture & Status Ledger"
    echo "Generated on: $TIMESTAMP"
    echo ""
    echo "This document logs the historical branch footprint on the remote server."
    echo "Per architectural mandates, historical development branches are preserved to maintain a forensic audit trail but are classified below by status."
    echo ""
    echo "## 1. IrisLime Remote Branches (\`irislime\`)"
    echo '```text'
    cd "$PROJECT_ROOT"
    git ls-remote --heads origin
    echo '```'
    echo ""
    echo "## 2. Inference Engine Remote Branches (\`llama.cpp\`)"
    echo '```text'
    if [ -d "../llama.cpp" ]; then
        cd ../llama.cpp
        git ls-remote --heads origin
    else
        echo "[!] Sibling tree llama.cpp missing."
    fi
    echo '```'
} > "$AUDIT_LOG"

cat "$AUDIT_LOG"
