# IrisLime Git Forensics Guide: File Discovery & Retrieval
# Filename:    docs/laboratory/git_forensics.md
# Purpose:     Reference manual for locating, inspecting, and extracting deleted or historical assets from the Git object history.
# Attribution: fekerr @ gemini
# Timestamp:   20260630_1058

## 1. Finding Historically Deleted Assets

If an asset has been deleted from the active workspace disk layout, you can locate exactly when it existed and what commits modified or removed it using high-speed index scanning.

### 1.1 List All Deleted Files in Git History
To locate the paths of files that were once part of the repository but have been pruned:
```bash
git log --diff-filter=D --summary | grep delete
