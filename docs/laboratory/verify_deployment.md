---

## 4. Verification Pass

To verify the setup is functioning perfectly after deployment:
1. Run `bash infra/setup_filters.sh`.
2. Open `.git/config` and verify that the `[filter "irislime_telemetry"]` parameters are present.
3. Run `cat config_env`. The fields at the top of the file will now show your active branch name and commit hash instead of `"TODO"`, confirming that the smudge system is actively tracking environment telemetry on disk.
