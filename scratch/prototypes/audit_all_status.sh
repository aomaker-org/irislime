#!/usr/bin/env bash
# ==========================================================================
# DIAGNOSTIC ENGINE: scratch/audit_all_status.sh
# Purpose: Compiles an exhaustive status audit across irislime and llama.cpp
# ==========================================================================
set -u

IRISLIME_DIR="$HOME/src/irislime"
LLAMACPP_DIR="$HOME/src/llama.cpp"
REPORT_FILE="$IRISLIME_DIR/scratch/wonky_status_report.md"

mkdir -p "$(dirname "$REPORT_FILE")"

{
    echo "# Exhaustive Forensic Workspace Status Audit Ledger"
    echo "Timestamp: $(date -Iseconds)"
    echo "Host:      $(uname -n)"
    echo "========================================================"
    echo ""

    # ----------------------------------------------------------------------
    # LAYER 1: PARENT WORKSPACE (irislime)
    # ----------------------------------------------------------------------
    echo "## 💻 PART A: PARENT REPOSITORY [irislime]"
    if [ -d "$IRISLIME_DIR" ]; then
        cd "$IRISLIME_DIR"
        
        echo "### 1. Working Tree & Index Status"
        echo "\`\`\`text"
        git status -u
        echo "\`\`\`"
        echo ""

        echo "### 2. Branch Track Comparison (-vv)"
        echo "\`\`\`text"
        git branch -a -vv
        echo "\`\`\`"
        echo ""

        echo "### 3. Recent Commit Graph Head"
        echo "\`\`\`text"
        git log --graph --oneline --decorate -n 8
        echo "\`\`\`"
        echo ""

        echo "### 4. Remote Server Head Line Refs"
        echo "\`\`\`text"
        git ls-remote --heads origin 2>/dev/null || echo "Remote connection deferred"
        echo "\`\`\`"
        echo ""

        echo "### 5. GitHub Pull Request Matrix"
        echo "\`\`\`text"
        gh pr list --state all --limit 10 2>/dev/null || echo "GH CLI pr query failed"
        echo "\`\`\`"
        echo ""

        echo "### 6. GitHub Tracking Issue Matrix"
        echo "\`\`\`text"
        gh issue list --state all --limit 10 2>/dev/null || echo "GH CLI issue query failed"
        echo "\`\`\`"
        echo ""
    else
        echo "[!] CRITICAL ERROR: irislime directory missing at $IRISLIME_DIR"
    fi

    # ----------------------------------------------------------------------
    # LAYER 2: INFERENCE ENGINE FORK (llama.cpp)
    # ----------------------------------------------------------------------
    echo "## 🦙 PART B: SIBLING ENGINE FORK [llama.cpp]"
    if [ -d "$LLAMACPP_DIR" ]; then
        cd "$LLAMACPP_DIR"
        
        echo "### 1. Working Tree & Index Status"
        echo "\`\`\`text"
        git status -u
        echo "\`\`\`"
        echo ""

        echo "### 2. Branch Track Comparison (-vv)"
        echo "\`\`\`text"
        git branch -a -vv
        echo "\`\`\`"
        echo ""

        echo "### 3. Recent Commit Graph Head"
        echo "\`\`\`text"
        git log --graph --oneline --decorate -n 5
        echo "\`\`\`"
        echo ""

        echo "### 4. Remote Server Head Line Refs"
        echo "\`\`\`text"
        git ls-remote --heads origin 2>/dev/null || echo "Remote connection deferred"
        echo "\`\`\`"
        echo ""
    else
        echo "[!] WARNING: Sibling llama.cpp directory missing or unlinked at $LLAMACPP_DIR"
    fi

} > "$REPORT_FILE"

# Bridge the output stream back to the host clipboard
cat "$REPORT_FILE" | clip.exe

echo "[+]"
echo "[+] Forensic status sweep compiled successfully."
echo "[+] Output written to local storage: scratch/wonky_status_report.md"
echo "[+] EXHAUSTIVE PAYLOAD SAFELY LOCKED INSIDE WINDOWS CLIPBOARD."
echo "[+]"
echo "[*] Please paste the clipboard payload back into this channel to initialize triage."

