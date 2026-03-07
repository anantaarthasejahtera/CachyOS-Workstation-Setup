#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  🚀 CachyOS Workstation Setup                                      ║
# ║  One-shot modular installer with TUI module selector                ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
# Usage:
#   ./setup.sh              Interactive mode (TUI module selector)
#   ./setup.sh --all        Install everything (no picker)
#   ./setup.sh --dry-run    Preview what will be installed (no changes)
#
# Configure your identity below before running.

set -euo pipefail

# ─── Configuration (EDIT THESE) ───────────────────────────
export GIT_NAME="Your Name"          # ← CHANGE THIS
export GIT_EMAIL="you@example.com"   # ← CHANGE THIS

# ─── Dry-run Mode ────────────────────────────────────────
if [[ "${1:-}" == "--dry-run" ]]; then
    echo ""
    echo -e "\033[1;35m  ╔══════════════════════════════════════╗\033[0m"
    echo -e "\033[1;35m  ║  🔍 DRY-RUN MODE (no changes made)  ║\033[0m"
    echo -e "\033[1;35m  ╚══════════════════════════════════════╝\033[0m"
    echo ""
    echo -e "\033[1;36m  Configuration:\033[0m"
    echo "    GIT_NAME:  $GIT_NAME"
    echo "    GIT_EMAIL: $GIT_EMAIL"
    echo ""
    echo -e "\033[1;36m  Available Modules:\033[0m"
    echo "    01-base.sh            GPU auto-detect, paru, makepkg         ~2 GB"
    echo "    02-kernel.sh          sysctl, NVMe, THP, Zram               ~0 MB"
    echo "    03-security.sh        UFW, SSH key, DNS, auto-cleanup       ~50 MB"
    echo "    04-dev.sh             Docker, Node, Python, Rust, Go        ~4 GB"
    echo "    05-mobile.sh          Flutter, Android SDK, Kotlin          ~5 GB"
    echo "    06-dotfiles.sh        Zsh, Kitty, Starship, fzf            ~100 MB"
    echo "    07-editors.sh         Antigravity, Neovim, Ollama AI        ~700 MB"
    echo "    08-desktop.sh         KDE Catppuccin, GRUB theme            ~300 MB"
    echo "    09-hyprland.sh        WM config, keybinds, lock screen      ~200 MB"
    echo "    10-apps.sh            Browser, tmux, Flatpak, Bluetooth     ~500 MB"
    echo "    11-gaming.sh          Steam, PCSX2, PrismLauncher           ~3 GB"
    echo "    12-vm.sh              QEMU/KVM, Bottles, LibreOffice        ~2 GB"
    echo "    13-waybar.sh          Status bar config + CSS               ~5 MB"
    echo "    14-nexus-guide.sh     Installs Nexus + Guide                ~1 MB"
    echo "    15-ecosystem.sh       6 Living Ecosystem tools              ~1 MB"
    echo ""
    echo -e "\033[1;36m  Ecosystem Tools (installed to /usr/local/bin/):\033[0m"
    echo "    theme-switch          Dynamic Catppuccin theme hot-swapper"
    echo "    config-rollback       Time Machine config restoration"
    echo "    dotfiles-sync         Cloud Git backup for ~/.config"
    echo "    ai-tuner              Local AI system telemetry optimizer"
    echo "    app-store             GUI App Store (pacman/AUR/flatpak)"
    echo "    health-check          Post-update system integrity checker"
    echo ""
    echo -e "\033[1;36m  Estimated Total:\033[0m ~16 GB (all modules)"
    echo -e "\033[1;36m  Estimated Time:\033[0m  15-30 min (depends on internet)"
    echo ""
    echo -e "\033[1;33m  To install, run:\033[0m ./setup.sh"
    echo ""
    exit 0
fi

# ─── Launch Installer ────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$SCRIPT_DIR/installer.sh" "$@"
