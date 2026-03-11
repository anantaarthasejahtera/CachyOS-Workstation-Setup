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
echo -e "${MAGENTA}  ╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${MAGENTA}  ║${RESET}  ${BOLD}🚀 CachyOS Workstation Setup${RESET}                    ${MAGENTA}║${RESET}"
echo -e "${MAGENTA}  ║${RESET}  ${CYAN}One-command system transformation${RESET}                ${MAGENTA}║${RESET}"
echo -e "${MAGENTA}  ║${RESET}  ${GREEN}15 modules · 50+ tools · Catppuccin Mocha${RESET}      ${MAGENTA}║${RESET}"
echo -e "${MAGENTA}  ╚══════════════════════════════════════════════════╝${RESET}"
echo ""

# ── Preflight Checks ──

# 1. Must be CachyOS or Arch-based — exit immediately if not
if [ ! -f /etc/pacman.conf ]; then
    echo -e "${RED}  ✗ This script requires an Arch-based distro (CachyOS recommended)${RESET}"
    echo -e "${RED}  Preflight check failed. Aborting.${RESET}"
    exit 1
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

# 4. Must have zenity (for GUI Wizard)
if ! command -v zenity &>/dev/null; then
    echo -e "${YELLOW}  ⚠ zenity not found — installing...${RESET}"
    sudo pacman -S --noconfirm --needed zenity 2>/dev/null || {
        echo -e "${RED}  ✗ Failed to install zenity${RESET}"
        exit 1
    }
    echo -e "${GREEN}  ✓ zenity installed${RESET}"
fi

# All preflight checks passed

echo -e "${GREEN}  ✓ All preflight checks passed${RESET}"
echo ""

# ── Clone or Update Repository ──
if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e "${BLUE}  ↻ Updating existing installation...${RESET}"
    if ! (cd "$INSTALL_DIR" && git pull --ff-only origin main 2>/dev/null); then
        echo -e "${YELLOW}  ⚠ Pull failed, re-cloning...${RESET}"
        rm -rf "$INSTALL_DIR"
        git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
    fi
else
    echo -e "${BLUE}  ↓ Cloning CachyOS Workstation Setup...${RESET}"
    rm -rf "$INSTALL_DIR"
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

echo -e "${GREEN}  ✓ Repository ready${RESET}"
echo ""

# ── Configure Identity (GUI Wizard) ──
cd "$INSTALL_DIR"

ENV_FILE="$INSTALL_DIR/.env"

# Load existing .env if present (validate format first to prevent code injection)
if [ -f "$ENV_FILE" ]; then
    if grep -qP '^[A-Z_]+=.*$' "$ENV_FILE" && ! grep -qP '[;|&`]|\$\(' "$ENV_FILE"; then
        # shellcheck source=/dev/null
        source "$ENV_FILE"
    else
        echo -e "${YELLOW}  ⚠ .env file contains unexpected content — skipping${RESET}"
    fi
fi

current_name="${GIT_NAME:-}"
current_email="${GIT_EMAIL:-}"

if [ -z "$current_name" ] || [ "$current_name" = "Your Name" ] || [ "$current_name" = "Kamu" ] || [ "$current_name" = "your name" ]; then
    # ── Detect identity from multiple sources ──
    gh_name="" ; gh_email=""
    git_name="" ; git_email=""

    # Source 1: GitHub CLI (if authenticated)
    if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
        gh_name=$(gh api user --jq '.name // empty' 2>/dev/null || echo "")
        gh_email=$(gh api user --jq '.email // empty' 2>/dev/null || echo "")
        if [ -z "$gh_email" ]; then
            gh_email=$(gh api user/emails --jq '[.[] | select(.primary)][0].email // empty' 2>/dev/null || echo "")
        fi
    fi

    # Source 2: Existing git config
    git_name=$(git config --global user.name 2>/dev/null || echo "")
    git_email=$(git config --global user.email 2>/dev/null || echo "")

    # ── Build zenity list items ──
    list_items=()
    default_set=false

    if [ -n "$gh_name" ] && [ -n "$gh_email" ]; then
        if [ "$default_set" = false ]; then
            list_items+=(TRUE "GitHub" "🐙 $gh_name <$gh_email>")
            default_set=true
        else
            list_items+=(FALSE "GitHub" "🐙 $gh_name <$gh_email>")
        fi
    fi

    if [ -n "$git_name" ] && [ -n "$git_email" ]; then
        if [ "$git_name" != "$gh_name" ] || [ "$git_email" != "$gh_email" ]; then
            if [ "$default_set" = false ]; then
                list_items+=(TRUE "GitConfig" "⚙️  $git_name <$git_email>")
                default_set=true
            else
                list_items+=(FALSE "GitConfig" "⚙️  $git_name <$git_email>")
            fi
        fi
    fi

    if [ "$default_set" = false ]; then
        list_items+=(TRUE "Manual" "✏️  Enter name and email manually")
    else
        list_items+=(FALSE "Manual" "✏️  Enter name and email manually")
    fi
    list_items+=(FALSE "Skip" "⏭️  Skip for now (edit .env later)")

    # ── Show identity wizard popup ──
    identity_choice=$(zenity --list --radiolist \
        --title="👤 Git Identity Setup" \
        --text="How would you like to configure your Git identity?\nThis is used for commits and SSH key generation." \
        --column="" --column="Source" --column="Identity" \
        --width=550 --height=320 \
        --print-column=2 --hide-column=2 \
        "${list_items[@]}" 2>/dev/null) || identity_choice="Skip"

    input_name="" ; input_email=""

    case "$identity_choice" in
        "GitHub")
            input_name="$gh_name"
            input_email="$gh_email"
            ;;
        "GitConfig")
            input_name="$git_name"
            input_email="$git_email"
            ;;
        "Manual")
            input_name=$(zenity --entry \
                --title="👤 Your Name" \
                --text="Enter your full name (for Git commits):" \
                --entry-text="$git_name" \
                --width=400 2>/dev/null) || input_name=""
            if [ -n "$input_name" ]; then
                input_email=$(zenity --entry \
                    --title="📧 Your Email" \
                    --text="Enter your email (for Git commits):" \
                    --entry-text="$git_email" \
                    --width=400 2>/dev/null) || input_email=""
            fi
            ;;
        *)
            # Skip
            ;;
    esac

    # ── Confirm and save ──
    if [ -n "$input_name" ] && [ -n "$input_email" ]; then
        if zenity --question \
            --title="✅ Confirm Identity" \
            --text="Save this identity?\n\n  <b>Name:</b>  $input_name\n  <b>Email:</b> $input_email\n\nThis will be written to .env (gitignored)." \
            --width=400 2>/dev/null
        then
            cat > "$ENV_FILE" << ENVEOF
# CachyOS Workstation — User Configuration
# This file is auto-generated and gitignored. Safe to edit manually.
GIT_NAME="$input_name"
GIT_EMAIL="$input_email"
ENVEOF
            echo -e "${GREEN}  ✓ Identity saved: $input_name <$input_email>${RESET}"
            echo ""
        else
            echo -e "${YELLOW}  ⚠ Identity not saved. Edit .env manually later.${RESET}"
            echo ""
        fi
    else
        echo -e "${YELLOW}  ⚠ Skipped — edit .env or run install.sh again later.${RESET}"
        echo ""
    fi
fi

# ── Launch Wizard ──
echo -e "${MAGENTA}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  Compiling & Launching Setup Wizard...${RESET}"
echo -e "${MAGENTA}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Ensure golang is installed
if ! command -v go &>/dev/null; then
    echo "Installing Go compiler..."
    sudo pacman -S --noconfirm --needed go
fi

# Build the nexus binary
echo -e "${BLUE}  ⚙️  Compiling Nexus v2...${RESET}"
bash build.sh

echo -e "${BLUE}  ⚙️  Installing Nexus globally...${RESET}"
sudo cp ./nexus /usr/local/bin/nexus
sudo chmod +x /usr/local/bin/nexus

echo -e "${GREEN}  ✓ Nexus deployed successfully. Booting wizard...${RESET}"
sleep 1

# Launch the new Go-native installer
nexus install


