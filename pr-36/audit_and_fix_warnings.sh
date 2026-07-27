#!/usr/bin/env bash
# PATH: pr-36/audit_and_fix_warnings.sh
# PURPOSE: Audit compiler warnings across logs and clean up SYCL dpct/helper.hpp warnings.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

echo "================================================================="
echo "[WarningAudit] Scanning Build Logs for Warning Telemetry"
echo "================================================================="

# 1. Collect warning counts by type across build logs
mkdir -p logs/reports/
REPORT_FILE="logs/reports/warning_summary_$(date +%Y%m%d_%H%M%S).txt"

echo "=== Compiler Warnings Summary ===" > "${REPORT_FILE}"
find build/ logs/ -type f -name "*.log" -exec grep -Hn "warning:" {} + 2>/dev/null | \
    sed 's/.*warning: //' | sort | uniq -c | sort -nr >> "${REPORT_FILE}" || true

echo "[+] Warning telemetry scan complete."
echo "[+] Summary report saved to: ${REPORT_FILE}"
echo "-----------------------------------------------------------------"
head -n 15 "${REPORT_FILE}" || true
echo "-----------------------------------------------------------------"

# 2. Fix SYCL dpct/helper.hpp warnings cleanly
HELPER_HPP="llama.cpp/ggml/src/ggml-sycl/dpct/helper.hpp"

if [ -f "${HELPER_HPP}" ]; then
    echo ""
    echo "[+] Remediation: Patching ${HELPER_HPP} inside submodule..."
    
    # Add [[noreturn]] attribute if not already present
    if ! grep -q "\[\[noreturn\]\]" "${HELPER_HPP}"; then
        sed -i 's/inline void _abort(/[[noreturn]] inline void _abort(/g' "${HELPER_HPP}"
        echo "  • Added [[noreturn]] to _abort()"
    fi

    # Ensure non-void control path at line 1029 terminates with _abort()
    if ! grep -q "_abort(\"Control path exit\");" "${HELPER_HPP}"; then
        sed -i '1029s|^|_abort("Control path exit");\n|' "${HELPER_HPP}"
        echo "  • Added explicit _abort() fallback to control path at line 1029"
    fi

    # Stage inside the submodule tree explicitly
    (cd llama.cpp && git add ggml/src/ggml-sycl/dpct/helper.hpp) || true
    echo "[+] ${HELPER_HPP} patched and staged inside submodule."
fi

echo ""
echo "================================================================="
echo "[WarningAudit] Audit Cycle Complete."
echo "================================================================="
