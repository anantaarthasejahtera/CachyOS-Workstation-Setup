#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  CachyOS Workstation Setup — GUI Bootstrap Installer
#  Usage: curl -fsSL https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/install.sh | bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

REPO_URL="https://github.com/anantaarthasejahtera/CachyOS-Workstation-Setup.git"
INSTALL_DIR="$HOME/.cache/cachy-workstation-setup"

# ── Setup Sudo ──
# Request administrator privileges upfront natively in terminal
echo -e "\e[33m🔑 Nexus Setup needs administrator privileges to configure your system.\e[0m"
if ! sudo -v; then
    echo -e "\e[31m❌ Authentication failed. Installer cannot proceed.\e[0m"
    exit 1
fi

# Keep sudo session alive in background
(while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) &

# ── Preflight Checks ──
echo -e "\e[34m[1/3] Starting Preflight Checks...\e[0m"

echo -e "  \e[90m-> Checking OS compatibility...\e[0m"
if [ ! -f /etc/pacman.conf ]; then
    echo -e "\e[31m❌ This script requires an Arch-based distro (CachyOS recommended). Aborting.\e[0m"
    exit 1
fi

if ! command -v git &>/dev/null; then
    echo -e "  \e[90m-> Installing git...\e[0m"
    sudo pacman -S --noconfirm --needed git >/dev/null 2>&1 || {
        echo -e "\e[31m❌ Failed to install git. Please install manually: sudo pacman -S git\e[0m"
        exit 1
    }
fi

if ! command -v curl &>/dev/null; then
    echo -e "  \e[90m-> Installing curl...\e[0m"
    sudo pacman -S --noconfirm --needed curl >/dev/null 2>&1 || {
        echo -e "\e[31m❌ Failed to install curl.\e[0m"
        exit 1
    }
fi

echo -e "\e[32m✔ All checks passed.\e[0m\n"

# ── Clone or Update Repository ──
echo -e "\e[34m[2/3] Preparing Repository...\e[0m"

if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e "  \e[90m-> Updating existing installation...\e[0m"
    if ! (cd "$INSTALL_DIR" && git pull --ff-only origin main >/dev/null 2>&1); then
        echo -e "  \e[90m-> Update failed, re-cloning repository...\e[0m"
        rm -rf "$INSTALL_DIR"
        git clone --depth=1 "$REPO_URL" "$INSTALL_DIR" >/dev/null 2>&1
    fi
else
    echo -e "  \e[90m-> Cloning CachyOS Workstation Setup...\e[0m"
    rm -rf "$INSTALL_DIR"
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR" >/dev/null 2>&1
fi
echo -e "\e[32m✔ Repository ready.\e[0m\n"

# ── Launch Wizard ──
echo -e "\e[34m[3/3] Deploying Nexus TUI...\e[0m"
cd "$INSTALL_DIR"

echo -e "  \e[90m-> Fetching latest pre-built Nexus binary...\e[0m"
LATEST_RELEASE_URL=$(curl -sL https://api.github.com/repos/anantaarthasejahtera/CachyOS-Workstation-Setup/releases/latest | grep "browser_download_url.*nexus-linux-amd64.tar.gz" | cut -d '"' -f 4 | head -n 1)

if [ -n "$LATEST_RELEASE_URL" ]; then
    echo -e "  \e[90m-> Found pre-built binary. Downloading...\e[0m"
    curl -#L "$LATEST_RELEASE_URL" -o nexus.tar.gz >/dev/null 2>&1
    tar -xzf nexus.tar.gz nexus >/dev/null 2>&1
    rm nexus.tar.gz
else
    echo -e "  \e[90m-> Pre-built binary not found. Falling back to local compilation...\e[0m"
    if ! command -v go &>/dev/null; then
        echo -e "  \e[90m-> Installing Go compiler...\e[0m"
        sudo pacman -S --noconfirm --needed go >/dev/null 2>&1
    fi
    echo -e "  \e[90m-> Compiling Nexus v2... (This may take a minute)\e[0m"
    bash build.sh >/dev/null 2>&1
fi

echo -e "  \e[90m-> Installing Nexus globally...\e[0m"
sudo cp ./nexus /usr/local/bin/nexus
sudo chmod +x /usr/local/bin/nexus

echo -e "\e[32m✔ Nexus deployed successfully. Booting TUI...\e[0m\n"
sleep 1

# Launch the new Go-native installer TUI
exec nexus install



