#!/usr/bin/env bash
# tools/checkpoint.sh

# Get the directory where this script lives
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root (assuming tools/ is inside the root)
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"
# Define the target directory
TARGET_DIR="$PROJECT_ROOT/docs/context"

# Ensure the directory exists
mkdir -p "$TARGET_DIR"

# Define the file
CHECKPOINT_FILE="$TARGET_DIR/latest_checkpoint.md"

echo "--- CHECKPOINT: $(date) ---" > "$CHECKPOINT_FILE"
echo "## Objective: " >> "$CHECKPOINT_FILE"
echo "## Current Blocker: " >> "$CHECKPOINT_FILE"
echo "## Next Action: " >> "$CHECKPOINT_FILE"
echo "## Environment State (Flags):" >> "$CHECKPOINT_FILE"
env | grep -E "(ZET_|ONEAPI|LD_)" >> "$CHECKPOINT_FILE"

echo "Checkpoint saved to $CHECKPOINT_FILE."
