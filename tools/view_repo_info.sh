echo "=== Git Status ===" && git status -s
echo "=== Active Submodules ===" && git submodule status
echo "=== Remotes Matrix ===" && git remote -v
echo "=== Workspace Mapping ===" && find . -maxdepth 2 -not -path '*/.*' | sort | grep -vE 'build|logs|models'

