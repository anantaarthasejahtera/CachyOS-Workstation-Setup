#!/usr/bin/env bash
# Module 14: Nexus Command Center & Guide System
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
skip_if_current
header "Nexus Command Center & Guide System"

# --- Nexus Command Center ---
log "Installing Nexus v2 Command Center..."
install_ecosystem "nexus.sh" "nexus"
ok "Nexus installed (Super+X to open)"
log "  Dynamic stats, smart toggles, live service detection"

# --- Guide v3 (Bilingual Interactive Reference) ---
log "Installing Guide v3..."
install_ecosystem "guide.sh" "guide"
ok "Guide v3 installed"
log "  guide              → interactive fzf (preview + execute)"
log "  guide <keyword>    → filter by keyword"
log "  guide --popup      → rofi popup mode"
log "  guide --web <q>    → query cheat.sh (online)"
mark_module_done
