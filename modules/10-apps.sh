#!/usr/bin/env bash
# Module 10: Extra Apps (Browser, Flatpak, tmux)
source "$(dirname "$0")/00-common.sh"
header "Extra Apps — Browser, Multiplexer, Tools"

# --- Zen Browser ---
log "Installing Zen Browser..."
install_aur zen-browser-bin 2>/dev/null || warn "Zen Browser AUR install failed, try manually"

# --- Tmux + Catppuccin ---
log "Installing tmux..."
install_pkg tmux

# Tmux Plugin Manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

mkdir -p "$HOME/.config/tmux"
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

# --- auto-cpufreq (battery optimization) ---
log "Installing auto-cpufreq (battery optimizer)..."
install_aur auto-cpufreq 2>/dev/null || true
sudo systemctl enable --now auto-cpufreq.service 2>/dev/null || true
ok "auto-cpufreq enabled"

# --- Bluetooth ---
log "Setting up Bluetooth..."
install_pkg bluez bluez-utils blueman
sudo systemctl enable --now bluetooth.service
ok "Bluetooth ready"

# --- Flatpak apps ---
log "Installing Flatpak apps..."
install_pkg flatpak
flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
flatpak install --user -y flathub com.spotify.Client 2>/dev/null || true
flatpak install --user -y flathub org.telegram.desktop 2>/dev/null || true
flatpak install --user -y flathub com.discordapp.Discord 2>/dev/null || true
ok "Flatpak apps installed (Spotify, Telegram, Discord)"

