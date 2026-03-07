#!/usr/bin/env bash
# Module 15: Living Ecosystem (Theme Switcher, Rollback, Cloud Sync)
source "$(dirname "$0")/00-common.sh"
header "Phase 4: Living Ecosystem Utilities"

REPO_DIR="$(dirname "$0")/.."
mkdir -p "$HOME/.local/bin"

# 1. Theme Engine
log "Installing Theme Switcher..."
if [ -f "$REPO_DIR/theme-switch.sh" ]; then
    cp "$REPO_DIR/theme-switch.sh" "$HOME/.local/bin/theme-switch"
else
    curl -fsSL -o "$HOME/.local/bin/theme-switch" \
        "https://raw.githubusercontent.com/rixzkiye/CachyOS-Workstation-Setup/main/theme-switch.sh" 2>/dev/null || true
fi
chmod +x "$HOME/.local/bin/theme-switch"
ok "Theme Switcher installed"

# 2. Config Rollback
log "Installing Config Rollback Time Machine..."
if [ -f "$REPO_DIR/config-rollback.sh" ]; then
    cp "$REPO_DIR/config-rollback.sh" "$HOME/.local/bin/config-rollback"
else
    curl -fsSL -o "$HOME/.local/bin/config-rollback" \
        "https://raw.githubusercontent.com/rixzkiye/CachyOS-Workstation-Setup/main/config-rollback.sh" 2>/dev/null || true
fi
chmod +x "$HOME/.local/bin/config-rollback"
ok "Config Rollback installed"

# 3. Dotfiles Cloud Sync
log "Installing Dotfiles Cloud Sync..."
if [ -f "$REPO_DIR/dotfiles-sync.sh" ]; then
    cp "$REPO_DIR/dotfiles-sync.sh" "$HOME/.local/bin/dotfiles-sync"
else
    curl -fsSL -o "$HOME/.local/bin/dotfiles-sync" \
        "https://raw.githubusercontent.com/rixzkiye/CachyOS-Workstation-Setup/main/dotfiles-sync.sh" 2>/dev/null || true
fi
chmod +x "$HOME/.local/bin/dotfiles-sync"
ok "Cloud Sync installed"

# 4. AI Auto-Tuner
log "Installing AI Auto-Tuner..."
if [ -f "$REPO_DIR/ai-tuner.sh" ]; then
    cp "$REPO_DIR/ai-tuner.sh" "$HOME/.local/bin/ai-tuner"
else
    curl -fsSL -o "$HOME/.local/bin/ai-tuner" \
        "https://raw.githubusercontent.com/rixzkiye/CachyOS-Workstation-Setup/main/ai-tuner.sh" 2>/dev/null || true
fi
chmod +x "$HOME/.local/bin/ai-tuner"
ok "AI Auto-Tuner installed"

# 5. Aesthetic GUI App Store
log "Installing Aesthetic GUI App Store..."
if [ -f "$REPO_DIR/app-store.sh" ]; then
    cp "$REPO_DIR/app-store.sh" "$HOME/.local/bin/app-store"
else
    curl -fsSL -o "$HOME/.local/bin/app-store" \
        "https://raw.githubusercontent.com/rixzkiye/CachyOS-Workstation-Setup/main/app-store.sh" 2>/dev/null || true
fi
chmod +x "$HOME/.local/bin/app-store"
ok "GUI App Store installed"

log "Ecosystem utilities installed. Accessible via Nexus (Super+X)"
