#!/usr/bin/env bash
# ==============================================================================
# Script Name: setup_filters.sh
# Timestamp:   20260629_1931
# Attribution: fekerr @ gemini (flash 3.5 + extended)
# Integrity:   SCRIPT_SHA256="TODO"
# Description: Idempotent environment configuration script. Automates local 
#              registration of the Irislime content telemetry pipelines.
# Lifecycle:   Repository Onboarding / Troubleshooting / Post-Clone Setup
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# --- Logging Utilities ---
log_info()  { echo -e "\033[0;34m[INFRA-SETUP]\033[0m $*" >&2; }
log_warn()  { echo -e "\033[0;33m[INFRA-WARN]\033[0m $*" >&2; }
log_error() { echo -e "\033[0;31m[INFRA-ERROR]\033[0m $*" >&2; }

# --- Git Environment Guard ---
verify_git_context() {
    if ! command -v git &> /dev/null; then
        log_error "Git binary missing from host execution path. Aborting."
        exit 1
    fi

    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        log_error "Current working directory is not a valid Git tree."
        log_error "Please execute this script from within the root of the irislime repository."
        exit 2
    fi
}

# --- Idempotent Filter Registration ---
configure_telemetry_filters() {
    log_info "Registering local content tracking macros..."

    # 1. Define Smudge Expression (Hydrate placeholders on checkout)
    # Uses triple-escaped structures to bypass local subshell expansion during configuration injection
    local smudge_cmd
    smudge_cmd="sed \
        -e \"s/INTEGRITY_COMMIT=\\\"TODO\\\"/INTEGRITY_COMMIT=\\\"\$(git rev-parse --short HEAD 2>/dev/null || echo 'detached')\\\"/\" \
        -e \"s/INTEGRITY_BRANCH=\\\"TODO\\\"/INTEGRITY_BRANCH=\\\"\$(git branch --show-current 2>/dev/null || echo 'HEAD')\\\"/\""

    # 2. Define Clean Expression (Scrub metrics back to baseline before staging)
    local clean_cmd
    clean_cmd="sed \
        -e 's/INTEGRITY_COMMIT=\".*\"/INTEGRITY_COMMIT=\"TODO\"/' \
        -e 's/INTEGRITY_BRANCH=\".*\"/INTEGRITY_BRANCH=\"TODO\"/'"

    log_info "Writing parameters to local .git/config node..."
    git config filter.irislime_telemetry.smudge "$smudge_cmd"
    git config filter.irislime_telemetry.clean "$clean_cmd"

    log_info "Content filter structures successfully committed to Git config index."
}

# --- Force Refresh Execution ---
hydrate_working_tree() {
    log_info "Refreshing working tree to apply active filter matrix..."
    
    # Force Git to pass key infrastructure scripts through the newly registered smudge processing engine
    local target_files=("config_env" "infra/bootstrap_models.sh")
    
    for file in "${target_files[@]}"; do
        if [ -f "$file" ]; then
            log_info "Hydrating telemetry metadata inside: $file"
            # Touching the checkout state forces a smudge computation pass without generating local diff noise
            rm -f "$file"
            git checkout HEAD -- "$file"
        else
            log_warn "Target file '$file' not found in current branch state. Skipping hydration."
        fi
    done
}

# --- Main Flow ---
main() {
    log_info "Initializing Irislime Git Configuration Suite..."
    verify_git_context
    configure_telemetry_filters
    hydrate_working_tree
    log_info "Infrastructure setup completed successfully. Execution scopes are synchronized."
}

main

# end of setup_filters.sh
