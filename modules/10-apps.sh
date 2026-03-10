#!/usr/bin/env bash
# Module 10: Extra Apps (Browser, Native Apps, tmux)
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
skip_if_current
header "Extra Apps — Browser, Multiplexer, Tools"

# ── Deprecated packages (auto-removed on re-run) ──────────
# CachyOS BORE scheduler + gamemode handles power management; auto-cpufreq conflicts.
cleanup_deprecated \
    auto-cpufreq    # redundant with BORE scheduler + gamemode

# --- Zen Browser ---
log "Installing Zen Browser..."
install_aur zen-browser-bin 2>/dev/null || warn "Zen Browser AUR install failed, try manually"

# --- Set XDG MIME defaults (system defaults for desktop apps) ---
log "Setting XDG MIME defaults..."
mkdir -p "$HOME/.config"

# Determine browser .desktop file
browser_desktop="zen-browser.desktop"
if ! command -v zen-browser &>/dev/null; then
    browser_desktop="firefox.desktop"
fi

# Write mimeapps.list — sets defaults for URLs, file manager, text editor
safe_config "$HOME/.config/mimeapps.list"
cat > "$HOME/.config/mimeapps.list" << MIMEEOF
[Default Applications]
# Browser — all web-related MIME types
x-scheme-handler/http=${browser_desktop}
x-scheme-handler/https=${browser_desktop}
x-scheme-handler/about=${browser_desktop}
x-scheme-handler/unknown=${browser_desktop}
text/html=${browser_desktop}
application/xhtml+xml=${browser_desktop}

# File manager — Thunar
inode/directory=thunar.desktop

# Terminal — Kitty
x-scheme-handler/terminal=kitty.desktop

# Text editor — Neovim (terminal) / Antigravity (GUI)
text/plain=nvim.desktop
application/x-shellscript=nvim.desktop
MIMEEOF

# Also set via xdg-settings for maximum compatibility
xdg-settings set default-web-browser "${browser_desktop}" 2>/dev/null || true
ok "XDG MIME defaults set (browser: ${browser_desktop}, files: thunar, editor: nvim)"

# --- Tmux + Catppuccin ---
log "Installing tmux..."
install_pkg tmux

# Tmux Plugin Manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

mkdir -p "$HOME/.config/tmux"
safe_config "$HOME/.config/tmux/tmux.conf"
cat > "$HOME/.config/tmux/tmux.conf" << 'TMUXEOF'
# — Tmux — Catppuccin Mocha —
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

# Prefix: Ctrl+A (easier than Ctrl+B)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Mouse support
set -g mouse on

# Start windows/panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# Split panes with | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Reload config
bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

# History
set -g history-limit 50000

# Vi mode
setw -g mode-keys vi

# — Catppuccin Theme —
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'catppuccin/tmux#v2.1.0'

set -g @catppuccin_flavor 'mocha'
set -g @catppuccin_window_status_style 'rounded'

set -g status-right-length 100
set -g status-left-length 100
set -g status-left ""
set -g status-right "#{E:@catppuccin_status_session}"
set -agF status-right "#{E:@catppuccin_status_date_time}"

# Initialize TPM (keep at very bottom)
run '~/.tmux/plugins/tpm/tpm'
TMUXEOF
ok "tmux + Catppuccin configured"

# --- direnv ---
log "Installing direnv..."
install_pkg direnv
ok "direnv installed"

# auto-cpufreq: redundant — CachyOS BORE scheduler + gamemode handles power management.
# cleanup_deprecated auto-disables the service before removal.

# --- Bluetooth ---
log "Setting up Bluetooth..."
install_pkg bluez bluez-utils blueman
sudo systemctl enable --now bluetooth.service
ok "Bluetooth ready"

# --- Communication & Media Apps (Native Arch/AUR) ---
log "Installing communication & media apps..."
install_pkg telegram-desktop discord
install_aur spotify-launcher
ok "Apps installed (Spotify, Telegram, Discord) — native packages"

# --- Productivity apps (moved from module 12 for better organization) ---
log "Installing productivity apps..."
install_pkg libreoffice-fresh
ok "LibreOffice installed (opens .docx, .xlsx, .pptx natively)"

install_pkg kdeconnect
ok "KDE Connect installed (pair phone for file transfer, notifications)"

install_aur obsidian-bin 2>/dev/null || warn "Obsidian AUR install failed — install manually from https://obsidian.md"
ok "Obsidian installed (markdown note-taking)"

install_pkg keepassxc
ok "KeePassXC installed (encrypted password manager, works offline)"

# --- Screen recording ---
log "Installing screen recording tools..."
install_pkg obs-studio wf-recorder
ok "OBS Studio + wf-recorder installed"

mark_module_done

