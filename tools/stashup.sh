# 1. Update the index only with changes to files we already track
git add -u

# 2. Add specific new files if we want them (like the new Makefile)
git add Makefile

# 3. Commit the state
git commit -m "chore: snapshot research state at $(date +%Y%m%d_%H%M%S)"
