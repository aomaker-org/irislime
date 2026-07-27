#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

echo "[+] Applying Makefile guard and target binding fixes..."

# 1. Add include guard to infra/make/base.mk
if ! grep -q "BASE_MK_INCLUDED" infra/make/base.mk 2>/dev/null; then
    sed -i '1s|^|ifndef BASE_MK_INCLUDED\nBASE_MK_INCLUDED := 1\n|' infra/make/base.mk
    echo "endif" >> infra/make/base.mk
fi

# 2. Ensure base.mk is included in sycl.mk and openvino.mk
for mk in infra/make/sycl.mk infra/make/openvino.mk; do
    if [ -f "$mk" ] && ! grep -q "base.mk" "$mk"; then
        sed -i '1s|^|-include infra/make/base.mk\n|' "$mk"
    fi
done

# 3. Update task70_debug_sweep.sh with accurate targets and stderr capture
cat << 'TASK70' > pr-36/agy/task70_debug_sweep.sh
#!/usr/bin/env bash
# PATH: pr-36/agy/task70_debug_sweep.sh
# PURPOSE: AGY Task 70 - Sweep debug targets with live error tailing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${PROJECT_ROOT}"

echo "================================================================="
echo "[AGY TASK 70] Launching Full Debug Build Sweep"
echo "================================================================="

# Valid Makefile targets
DEBUG_TARGETS=("build-vulkan" "build-sycl" "build-openvino")

for target in "${DEBUG_TARGETS[@]}"; do
    echo ""
    echo "-----------------------------------------------------------------"
    echo "[AGY TASK 70] Triggering target: ${target}"
    echo "-----------------------------------------------------------------"
    
    # Capture stderr to a target-specific transient log for instant tailing
    ERR_LOG="logs/builds/${target}_last_err.log"
    mkdir -p logs/builds/

    if make "${target}" 2> >(tee "${ERR_LOG}" >&2); then
        echo "[+] Target ${target} compiled successfully."
    else
        echo "[!] Target ${target} failed!"
        echo "=================== ERROR TAILER OUTPUT ==================="
        tail -n 25 "${ERR_LOG}" || true
        echo "==========================================================="
        python3 tools/claude_spot_fix.py "${ERR_LOG}"
    fi
done

echo ""
echo "================================================================="
echo "[AGY TASK 70] Full Debug Sweep Completed."
echo "================================================================="
TASK70

chmod +x pr-36/agy/task70_debug_sweep.sh
git add infra/make/base.mk infra/make/sycl.mk infra/make/openvino.mk pr-36/agy/task70_debug_sweep.sh
echo "[+] Matrix build fixes successfully applied and staged."
