#!/usr/bin/env bash
# Module 15: Living Ecosystem (Theme Switcher, Rollback, Cloud Sync)
source "$(dirname "$0")/00-common.sh"
header "Living Ecosystem (7 Integrated Tools)"

REPO_DIR="$(dirname "$0")/.."
INSTALL_DIR="/usr/local/bin"

# 1. Theme Engine
log "Installing Theme Switcher..."
if [ -f "$REPO_DIR/ecosystem/theme-switch.sh" ]; then
    sudo cp "$REPO_DIR/ecosystem/theme-switch.sh" "$INSTALL_DIR/theme-switch"
else
    sudo curl -fsSL -o "$INSTALL_DIR/theme-switch" \
        "https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/ecosystem/theme-switch.sh" 2>/dev/null || true
fi
sudo chmod +x "$INSTALL_DIR/theme-switch"
ok "Theme Switcher installed"

# 2. Config Rollback
log "Installing Config Rollback Time Machine..."
if [ -f "$REPO_DIR/ecosystem/config-rollback.sh" ]; then
    sudo cp "$REPO_DIR/ecosystem/config-rollback.sh" "$INSTALL_DIR/config-rollback"
else
    sudo curl -fsSL -o "$INSTALL_DIR/config-rollback" \
        "https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/ecosystem/config-rollback.sh" 2>/dev/null || true
fi
sudo chmod +x "$INSTALL_DIR/config-rollback"
ok "Config Rollback installed"

# 3. Dotfiles Cloud Sync
log "Installing Dotfiles Cloud Sync..."
if [ -f "$REPO_DIR/ecosystem/dotfiles-sync.sh" ]; then
    sudo cp "$REPO_DIR/ecosystem/dotfiles-sync.sh" "$INSTALL_DIR/dotfiles-sync"
else
    sudo curl -fsSL -o "$INSTALL_DIR/dotfiles-sync" \
        "https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/ecosystem/dotfiles-sync.sh" 2>/dev/null || true
fi
sudo chmod +x "$INSTALL_DIR/dotfiles-sync"
ok "Cloud Sync installed"

# 4. AI Auto-Tuner
log "Installing AI Auto-Tuner..."
if [ -f "$REPO_DIR/ecosystem/ai-tuner.sh" ]; then
    sudo cp "$REPO_DIR/ecosystem/ai-tuner.sh" "$INSTALL_DIR/ai-tuner"
else
    sudo curl -fsSL -o "$INSTALL_DIR/ai-tuner" \
        "https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/ecosystem/ai-tuner.sh" 2>/dev/null || true
fi
sudo chmod +x "$INSTALL_DIR/ai-tuner"
ok "AI Auto-Tuner installed"

# 5. Aesthetic GUI App Store
log "Installing Aesthetic GUI App Store..."
if [ -f "$REPO_DIR/ecosystem/app-store.sh" ]; then
    sudo cp "$REPO_DIR/ecosystem/app-store.sh" "$INSTALL_DIR/app-store"
else
    sudo curl -fsSL -o "$INSTALL_DIR/app-store" \
        "https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/ecosystem/app-store.sh" 2>/dev/null || true
fi
sudo chmod +x "$INSTALL_DIR/app-store"
ok "GUI App Store installed"

# 6. Health Check (Post-Update Doctor)
log "Installing System Health Check..."
if [ -f "$REPO_DIR/ecosystem/health-check.sh" ]; then
    sudo cp "$REPO_DIR/ecosystem/health-check.sh" "$INSTALL_DIR/health-check"
else
    sudo curl -fsSL -o "$INSTALL_DIR/health-check" \
        "https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/ecosystem/health-check.sh" 2>/dev/null || true
fi
sudo chmod +x "$INSTALL_DIR/health-check"
ok "Health Check installed"

# 7. Pacman hook — auto health check after system updates
log "Installing pacman post-update hook..."
sudo mkdir -p /etc/pacman.d/hooks
sudo tee /etc/pacman.d/hooks/99-health-check.hook > /dev/null << 'HOOKEOF'
[Trigger]
Operation = Upgrade
Type = Package
Target = linux*
Target = hyprland*
Target = waybar*
Target = nvidia*

[Action]
Description = Running CachyOS Workstation Health Check...
When = PostTransaction
Exec = /bin/bash -c 'if command -v health-check &>/dev/null; then health-check; fi'
NeedsTargets
HOOKEOF
ok "Pacman hook installed (auto health check after kernel/WM/GPU updates)"

# 8. Post-Install First-Boot Wizard
log "Installing Post-Install Wizard..."
if [ -f "$REPO_DIR/ecosystem/post-install.sh" ]; then
    sudo cp "$REPO_DIR/ecosystem/post-install.sh" "$INSTALL_DIR/post-install-wizard"
else
    sudo curl -fsSL -o "$INSTALL_DIR/post-install-wizard" \
        "https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/ecosystem/post-install.sh" 2>/dev/null || true
fi
sudo chmod +x "$INSTALL_DIR/post-install-wizard"
ok "Post-Install Wizard installed (runs once on first boot)"

log "Ecosystem utilities installed. Accessible via Nexus (Super+X)"
