#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  CachyOS Workstation Setup — One-Liner Bootstrap Installer
#  Usage: curl -fsSL https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/install.sh | bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

# ── Catppuccin Mocha Colors ──
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BOLD='\033[1m'
RESET='\033[0m'

REPO_URL="https://github.com/anantaarthasejahtera/CachyOS-Workstation-Setup.git"
INSTALL_DIR="$HOME/.cache/cachy-workstation-setup"

# ── Banner ──
echo ""
echo -e "${MAGENTA}  ╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${MAGENTA}  ║${RESET}  ${BOLD}🚀 CachyOS Workstation Setup${RESET}                        ${MAGENTA}║${RESET}"
echo -e "${MAGENTA}  ║${RESET}  ${CYAN}One-command transformation for your CachyOS${RESET}         ${MAGENTA}║${RESET}"
echo -e "${MAGENTA}  ║${RESET}  ${GREEN}15 modules · 50+ tools · Catppuccin Mocha${RESET}          ${MAGENTA}║${RESET}"
echo -e "${MAGENTA}  ╚══════════════════════════════════════════════════════╝${RESET}"
echo ""

# ── Preflight Checks ──
preflight_ok=true

# 1. Must be CachyOS or Arch-based
if [ ! -f /etc/pacman.conf ]; then
    echo -e "${RED}  ✗ This script requires an Arch-based distro (CachyOS recommended)${RESET}"
    preflight_ok=false
fi

# 2. Must have git
if ! command -v git &>/dev/null; then
    echo -e "${YELLOW}  ⚠ git not found — installing...${RESET}"
    sudo pacman -S --noconfirm --needed git 2>/dev/null || {
        echo -e "${RED}  ✗ Failed to install git. Please install manually: sudo pacman -S git${RESET}"
        exit 1
    }
    echo -e "${GREEN}  ✓ git installed${RESET}"
fi

# 3. Must have curl
if ! command -v curl &>/dev/null; then
    echo -e "${YELLOW}  ⚠ curl not found — installing...${RESET}"
    sudo pacman -S --noconfirm --needed curl 2>/dev/null || {
        echo -e "${RED}  ✗ Failed to install curl${RESET}"
        exit 1
    }
    echo -e "${GREEN}  ✓ curl installed${RESET}"
fi

# 4. Must have dialog (for TUI installer)
if ! command -v dialog &>/dev/null; then
    echo -e "${YELLOW}  ⚠ dialog not found — installing...${RESET}"
    sudo pacman -S --noconfirm --needed dialog 2>/dev/null || {
        echo -e "${RED}  ✗ Failed to install dialog${RESET}"
        exit 1
    }
    echo -e "${GREEN}  ✓ dialog installed${RESET}"
fi

if [ "$preflight_ok" = false ]; then
    echo -e "${RED}  Preflight checks failed. Aborting.${RESET}"
    exit 1
fi

echo -e "${GREEN}  ✓ All preflight checks passed${RESET}"
echo ""

# ── Clone or Update Repository ──
if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e "${BLUE}  ↻ Updating existing installation...${RESET}"
    cd "$INSTALL_DIR"
    git pull --ff-only origin main 2>/dev/null || {
        echo -e "${YELLOW}  ⚠ Pull failed, re-cloning...${RESET}"
        cd ~
        rm -rf "$INSTALL_DIR"
        git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
    }
else
    echo -e "${BLUE}  ↓ Cloning CachyOS Workstation Setup...${RESET}"
    rm -rf "$INSTALL_DIR"
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

echo -e "${GREEN}  ✓ Repository ready${RESET}"
echo ""

# ── Configure Identity ──
cd "$INSTALL_DIR"

# Prompt for Git identity if not set in setup.sh
current_name=$(grep 'GIT_NAME=' setup.sh | cut -d'"' -f2)
current_email=$(grep 'GIT_EMAIL=' setup.sh | cut -d'"' -f2)

if [ "$current_name" = "Kamu" ] || [ "$current_name" = "Your Name" ] || [ -z "$current_name" ]; then
    echo -e "${CYAN}  Configure your identity (used for Git commits):${RESET}"
    echo ""
    
    # Try to get from existing git config
    default_name=$(git config --global user.name 2>/dev/null || echo "")
    default_email=$(git config --global user.email 2>/dev/null || echo "")
    
    read -rp "    Name [$default_name]: " input_name
    input_name="${input_name:-$default_name}"
    
    read -rp "    Email [$default_email]: " input_email
    input_email="${input_email:-$default_email}"
    
    if [ -n "$input_name" ] && [ -n "$input_email" ]; then
        sed -i "s|GIT_NAME=\".*\"|GIT_NAME=\"$input_name\"|" setup.sh
        sed -i "s|GIT_EMAIL=\".*\"|GIT_EMAIL=\"$input_email\"|" setup.sh
        echo ""
        echo -e "${GREEN}  ✓ Identity set: $input_name <$input_email>${RESET}"
    else
        echo -e "${YELLOW}  ⚠ Skipped — using defaults. Edit setup.sh later to change.${RESET}"
    fi
    echo ""
fi

# ── Launch Installer ──
echo -e "${MAGENTA}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  Launching TUI Installer...${RESET}"
echo -e "${MAGENTA}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${CYAN}Tip:${RESET} Select modules with ${BOLD}Space${RESET}, confirm with ${BOLD}Enter${RESET}"
echo -e "  ${CYAN}Tip:${RESET} All changes are backed up automatically"
echo ""

sleep 1

chmod +x setup.sh installer.sh
bash setup.sh
