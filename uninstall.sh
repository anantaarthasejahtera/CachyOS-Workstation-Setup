#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Uninstall Script for CachyOS Workstation Setup
# This will safely remove Nexus, Guide, Ecosystem tools, and hooks.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

# Colors
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_TEXT='\033[0;37m'
NC='\033[0m'

echo -e "\n${C_BLUE}╭─────────────────────────────────────────────────────────╮${NC}"
echo -e "${C_BLUE}│${NC}  ${C_YELLOW}CachyOS Workstation Setup — Uninstaller${NC}                ${C_BLUE}│${NC}"
echo -e "${C_BLUE}╰─────────────────────────────────────────────────────────╯${NC}\n"

echo -e "${C_TEXT}This script will remove:${NC}"
echo -e "  ${C_RED}1.${NC} Ecosystem scripts from /usr/local/bin/"
echo -e "  ${C_RED}2.${NC} Nexus Command Center and Guide v3"
echo -e "  ${C_RED}3.${NC} Rofi custom themes and app store configs"
echo -e "  ${C_RED}4.${NC} System Health Check Pacman Hooks"
echo -e "  ${C_RED}5.${NC} Internal state tracking (~/.config/cachy-setup)"
echo -e "\n${C_YELLOW}It will NOT:${NC}"
echo -e "  - Uninstall packages (Docker, Steam, etc.)"
echo -e "  - Delete your personal files or dotfiles backups"
echo -e "  - Remove Ollama AI models you downloaded"

read -p "$(echo -e "\n${C_RED}Are you sure you want to proceed? (y/N): ${NC}")" confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${C_YELLOW}Uninstallation aborted.${NC}"
    exit 0
fi

echo -e "\n${C_BLUE}[1/5] Removing Ecosystem Tools & Executables...${NC}"
ECO_TOOLS=("guide" "nexus" "theme-switch" "config-rollback" "dotfiles-sync" "ai-tuner" "app-store" "health-check" "post-install")
for tool in "${ECO_TOOLS[@]}"; do
    if [ -f "/usr/local/bin/$tool" ]; then
        sudo rm -f "/usr/local/bin/$tool"
        echo -e "  ${C_GREEN}✓ Removed${NC} /usr/local/bin/$tool"
    fi
done

echo -e "\n${C_BLUE}[2/5] Removing Health Check Pacman Hooks...${NC}"
if [ -f "/etc/pacman.d/hooks/99-cachy-health.hook" ]; then
    sudo rm -f "/etc/pacman.d/hooks/99-cachy-health.hook"
    echo -e "  ${C_GREEN}✓ Removed${NC} build-in pacman hooks"
else
    echo -e "  ${C_TEXT}- No hooks found${NC}"
fi

echo -e "\n${C_BLUE}[3/5] Cleaning up Rofi UI Themes...${NC}"
if [ -d "$HOME/.config/rofi/cachy-setup" ]; then
    rm -rf "$HOME/.config/rofi/cachy-setup"
    rm -f "$HOME/.config/app-store-custom.conf"
    echo -e "  ${C_GREEN}✓ Removed${NC} Custom UI elements"
else
    echo -e "  ${C_TEXT}- No custom UI elements found${NC}"
fi

echo -e "\n${C_BLUE}[4/5] Removing State Tracking...${NC}"
if [ -d "$HOME/.config/cachy-setup" ]; then
    rm -rf "$HOME/.config/cachy-setup"
    echo -e "  ${C_GREEN}✓ Removed${NC} State tracker"
else
    echo -e "  ${C_TEXT}- No state tracker found${NC}"
fi

echo -e "\n${C_BLUE}[5/5] Reverting Hyprland Keybinds...${NC}"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    # Attempt to safely remove Nexus and Guide keybinds and restore defaults
    sed -i '/bind = SUPER, X, exec, nexus/d' "$HYPR_CONF"
    sed -i '/bind = SUPER, D, exec, rofi -show run -theme/d' "$HYPR_CONF"
    # Ensure default Rofi keybind exists if we removed the custom one
    if ! grep -q "bind = SUPER, D, exec, rofi" "$HYPR_CONF"; then
        echo "bind = SUPER, D, exec, rofi -show drun" >> "$HYPR_CONF"
    fi
    echo -e "  ${C_GREEN}✓ Removed${NC} Nexus and Guide keybinds"
else
    echo -e "  ${C_TEXT}- hyprland.conf not found${NC}"
fi

echo -e "\n${C_GREEN}🎉 Uninstallation Complete!${NC}"
echo -e "\n${C_YELLOW}To restore your original configs (Waybar, Hyprland, etc.):${NC}"
echo -e "  1. Look inside ${C_BLUE}~/.config-backup/${NC}"
echo -e "  2. Copy your original files back to ${C_BLUE}~/.config/${NC}"
echo -e "\nTo see what packages were installed, check ${C_BLUE}~/cachy-setup.log${NC}"
echo -e "Thank you for trying CachyOS Workstation Setup! Goodbye.\n"
