#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Uninstall CLI Wizard for CachyOS Workstation Setup
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}╭────────────────────────────────────────────────────────────╮${NC}"
echo -e "${BLUE}│ 🗑️  CachyOS Workstation — Uninstaller                     │${NC}"
echo -e "${BLUE}╰────────────────────────────────────────────────────────────╯${NC}"
echo ""
echo -e "${CYAN}This wizard will remove:${NC}"
echo "  1. The Nexus Command Center binary (/usr/local/bin/nexus)"
echo "  2. Legacy Ecosystem scripts (V1 & V2)"
echo "  3. GUI enhancements (Rofi themes, Waypaper, SDDM configs)"
echo "  4. System Health Check Pacman Hooks"
echo "  5. Internal state tracking (~/.config/cachy-setup)"
echo ""
echo -e "${YELLOW}It will NOT:${NC}"
echo "  • Uninstall base packages (Docker, Steam, etc.)"
echo "  • Delete your personal files or dotfiles backups"
echo "  • Remove Ollama AI models you downloaded"
echo ""

read -p "$(echo -e ${RED}"Are you sure you want to proceed? [y/N] "${NC})" confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Uninstallation cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}Removing components...${NC}"

# 1. Nexus Binary and Legacy Ecosystem Tools
echo -e " ${GREEN}[1/5] Removing Ecosystem Tools & Executables...${NC}"
ECO_TOOLS=("nexus" "guide" "theme-switch" "config-rollback" "dotfiles-sync" "ai-tuner" "app-store" "health-check" "post-install-wizard" "nexus-chat" "ai-power-fix")
for tool in "${ECO_TOOLS[@]}"; do
    if [ -f "/usr/local/bin/$tool" ]; then
        sudo rm -f "/usr/local/bin/$tool"
    fi
    if [ -f "$HOME/.local/bin/$tool" ]; then
        rm -f "$HOME/.local/bin/$tool"
    fi
done

# 2. Pacman Hooks
echo -e " ${GREEN}[2/5] Removing Health Check Pacman Hooks...${NC}"
sudo rm -f /etc/pacman.d/hooks/99-cachy-health.hook 2>/dev/null || true

# 3. UI & Desktop Customizations
echo -e " ${GREEN}[3/5] Cleaning up UI Themes & Customizations...${NC}"
rm -rf "$HOME/.config/rofi/cachy-setup" 2>/dev/null || true
rm -f "$HOME/.config/app-store-custom.conf" 2>/dev/null || true
rm -rf "$HOME/.config/waypaper" 2>/dev/null || true
rm -rf "$HOME/Pictures/Wallpapers/orangci" 2>/dev/null || true

# Custom SDDM Reversion
if [ -f "/etc/sddm.conf.d/default-session.conf" ]; then
    echo -e "      ${YELLOW}→ Reverting SDDM Hyprland default session...${NC}"
    sudo rm -f "/etc/sddm.conf.d/default-session.conf" 2>/dev/null || true
fi
if [ -f "/etc/sddm.conf.d/theme.conf" ]; then
    echo -e "      ${YELLOW}→ Reverting SDDM Catppuccin Theme...${NC}"
    sudo rm -f "/etc/sddm.conf.d/theme.conf" 2>/dev/null || true
fi

# 4. State Tracking
echo -e " ${GREEN}[4/5] Removing State Tracking...${NC}"
rm -rf "$HOME/.config/cachy-setup" 2>/dev/null || true

# 5. Hyprland Keybinds
echo -e " ${GREEN}[5/5] Reverting Hyprland Keybinds...${NC}"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    # Remove Nexus keybind (matches both $mainMod and SUPER variants)
    sed -i '/exec.*nexus/d' "$HYPR_CONF"
    # Remove custom rofi keybind (with -show-icons added by installer)
    sed -i '/exec.*rofi -show drun -show-icons/d' "$HYPR_CONF"
    # Restore vanilla rofi drun keybind if no rofi drun bind exists
    if ! grep -q 'exec.*rofi.*-show drun' "$HYPR_CONF"; then
        echo 'bind = $mainMod, D, exec, rofi -show drun' >> "$HYPR_CONF"
    fi
fi

echo ""
echo -e "${BLUE}🎉 Uninstallation Complete!${NC}"
echo ""
echo -e "${YELLOW}To restore original configs:${NC}"
echo "  1. Look inside ~/.config-backup/"
echo "  2. Copy your original files back to ~/.config/"
echo ""
echo "Thank you for trying CachyOS Workstation Setup!"
