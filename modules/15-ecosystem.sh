#!/usr/bin/env bash
# Module 15: Living Ecosystem (8 Integrated Tools)
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
skip_if_current
header "Living Ecosystem (8 Integrated Tools)"

# 1. Theme Engine, Wallpaper Picker, Nexus Chat, AI Power Fix
log "Installing Theme & Wallpaper Tools..."
install_ecosystem "theme-switch.sh"
# wallpaper-picker removed — using waypaper (GUI app) instead
install_ecosystem "nexus-chat.sh"
install_ecosystem "ai-power-fix.sh"
ok "Theme & Wallpaper tools installed"

# 2. Config Rollback
log "Installing Config Rollback Time Machine..."
install_ecosystem "config-rollback.sh"
ok "Config Rollback installed"

# 3. Dotfiles Cloud Sync
log "Installing Dotfiles Cloud Sync..."
install_ecosystem "dotfiles-sync.sh"
ok "Cloud Sync installed"

# 4. AI Auto-Tuner
log "Installing AI Auto-Tuner..."
install_ecosystem "ai-tuner.sh"
ok "AI Auto-Tuner installed"

# 5. Aesthetic GUI App Store
log "Installing Aesthetic GUI App Store..."
install_ecosystem "app-store.sh"
ok "GUI App Store installed"

# 6. Health Check (Post-Update Doctor)
log "Installing System Health Check..."
install_ecosystem "health-check.sh"
ok "Health Check installed"

# 7. Pacman hook — auto health check after system updates
log "Installing pacman post-update hook..."
sudo mkdir -p /etc/pacman.d/hooks
sudo tee /etc/pacman.d/hooks/99-cachy-health.hook > /dev/null << 'HOOKEOF'
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
install_ecosystem "post-install.sh" "post-install-wizard"
ok "Post-Install Wizard installed (runs once on first boot)"

log "Ecosystem utilities installed. Accessible via Nexus (Super+X)"
mark_module_done
