# Workspace Architecture Blueprint: Nested Git Repositories & Sandboxing

## 1. Single-Stroke Initialization Workflow
To optimize session initialization and maintain upstream repository sterility, local prompt adjustments are completely decoupled from shared tracking files. Sourcing the private boot script evaluates the environment and updates shell telemetry in a single transaction path.

```bash
# Entry point for local development sessions
. scratch/boot.sh
echo "hmm"
