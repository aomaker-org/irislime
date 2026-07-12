#!/usr/bin/env bash
# ==============================================================================
# IrisLime Infrastructure Preferences Map
# Filename:    config_prefs.sh
# Purpose:     Shared baseline environment rules and prompt configuration
# Attribution: fekerr & Gemini (20260706_1136 / Preference Layer Pass)
# ==============================================================================

# --- GLOBAL FALLBACK INITIALIZATION ---
export ISLM_USER="${ISLM_USER:-default_node}"

# --- DYNAMIC INTERACTIVE PROMPT ENGINE ---
# Only bind the custom colorized PS1 string if the shell session is active/interactive
if [[ $- == *i* ]]; then
    export PS1='\[\e]0;\u@\h: \w\a\]\n\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;35m\]${ISLM_RUN_TYPE:+[$ISLM_RUN_TYPE]: }\[\033[00m\]\[\033[01;37m\]\w\[\033[00m\] \[\033[01;33m\]\D{%y%m_%H%M}_\!\[\033[00m\]\n; '
fi

echo "[+] IrisLime shared configuration preferences cleanly evaluated."
