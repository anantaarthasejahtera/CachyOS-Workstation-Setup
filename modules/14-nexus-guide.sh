#!/usr/bin/env bash
# Module 14: Nexus Command Center & Guide System
source "$(dirname "$0")/00-common.sh"
header "Nexus Command Center & Guide System"

REPO_DIR="$(dirname "$0")/.."
mkdir -p "$HOME/.local/bin"

# --- Nexus Command Center ---
log "Installing Nexus v2 Command Center..."
if [ -f "$REPO_DIR/nexus.sh" ]; then
    cp "$REPO_DIR/nexus.sh" "$HOME/.local/bin/nexus"
else
    curl -fsSL -o "$HOME/.local/bin/nexus" \
        "https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/nexus.sh" 2>/dev/null || true
fi
chmod +x "$HOME/.local/bin/nexus"
ok "Nexus installed (Super+X to open)"
log "  Dynamic stats, smart toggles, live service detection"

# --- Guide v3 (Bilingual Interactive Reference) ---
log "Installing Guide v3..."
if [ -f "$REPO_DIR/guide.sh" ]; then
    cp "$REPO_DIR/guide.sh" "$HOME/.local/bin/guide"
else
    curl -fsSL -o "$HOME/.local/bin/guide" \
        "https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/guide.sh" 2>/dev/null || true
fi
chmod +x "$HOME/.local/bin/guide"
ok "Guide v2 installed"
log "  guide              → interactive fzf (preview + execute)"
log "  guide <keyword>    → filter by keyword"
log "  guide --popup      → rofi popup mode"
log "  guide --web <q>    → query cheat.sh (online)"
