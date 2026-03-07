#!/usr/bin/env bash
# Module 06: Shell, Terminal & Dotfiles
source "$(dirname "$0")/00-common.sh"
# MODULE 4: Shell & Terminal Aesthetic
# =====================================================================
header "Shell & Terminal Aesthetic"

# --- Zsh + Oh My Zsh ---
install_pkg zsh

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ] && \
    git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ] && \
    git clone https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"

# --- Starship Prompt ---
log "Installing Starship prompt..."
install_pkg starship

# --- Kitty Terminal ---
log "Installing Kitty terminal..."
install_pkg kitty

# --- Nerd Fonts ---
log "Installing Nerd Fonts..."
install_pkg ttf-jetbrains-mono-nerd ttf-firacode-nerd ttf-nerd-fonts-symbols-common
install_aur ttf-inter 2>/dev/null || true

ok "Shell & terminal aesthetic ready"

# =====================================================================
# MODULE 5: Desktop Aesthetic (KDE Plasma + Catppuccin)
# =====================================================================
header "Desktop Aesthetic — Catppuccin Mocha Rice"

# --- Catppuccin KDE Theme ---
log "Installing Catppuccin theme suite..."
install_aur catppuccin-kde-theme-mocha 2>/dev/null || true

# --- Icons & Cursors ---
install_pkg papirus-icon-theme
install_aur papirus-folders-catppuccin 2>/dev/null || true
install_aur catppuccin-cursors-mocha 2>/dev/null || true

# --- Kvantum (Qt theming engine) ---
install_pkg kvantum
install_aur kvantum-theme-catppuccin-mocha 2>/dev/null || true

# --- GTK theme for consistency ---
install_aur catppuccin-gtk-theme-mocha 2>/dev/null || true

# --- SDDM Theme ---
install_aur sddm-theme-catppuccin-mocha 2>/dev/null || true

# --- Wallpapers ---
log "Downloading aesthetic wallpapers..."
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WALLPAPER_DIR"
# Catppuccin official wallpapers
if [ ! -d "/tmp/catppuccin-wallpapers" ]; then
    git clone --depth=1 https://github.com/zhichaoh/catppuccin-wallpapers.git /tmp/catppuccin-wallpapers 2>/dev/null || \
    git clone --depth=1 https://github.com/Gingeh/wallpapers.git /tmp/catppuccin-wallpapers 2>/dev/null || true
fi
cp -r /tmp/catppuccin-wallpapers/* "$WALLPAPER_DIR/" 2>/dev/null || true

# --- Extra visual apps ---
install_pkg fastfetch cmatrix

ok "Desktop aesthetic configured"

# --- GRUB Catppuccin Theme (boot screen) ---
log "Installing GRUB Catppuccin theme..."
GRUB_THEME_DIR="/usr/share/grub/themes/catppuccin-mocha"
if [ ! -d "$GRUB_THEME_DIR" ]; then
    cd /tmp
    git clone --depth=1 https://github.com/catppuccin/grub.git catppuccin-grub 2>/dev/null || true
    if [ -d "catppuccin-grub/src/catppuccin-mocha-grub-theme" ]; then
        sudo mkdir -p "$GRUB_THEME_DIR"
        sudo cp -r catppuccin-grub/src/catppuccin-mocha-grub-theme/* "$GRUB_THEME_DIR/"
        sudo sed -i 's|^#\?GRUB_THEME=.*|GRUB_THEME="/usr/share/grub/themes/catppuccin-mocha/theme.txt"|' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
        ok "GRUB Catppuccin Mocha theme installed"
    fi
    rm -rf /tmp/catppuccin-grub
    cd ~
fi

# --- GTK/Qt Font Configuration ---
log "Configuring system fonts..."
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

# GTK-3 settings
cat > "$HOME/.config/gtk-3.0/settings.ini" << 'GTK3EOF'
[Settings]
gtk-theme-name=catppuccin-mocha-mauve-standard+default
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=catppuccin-mocha-dark-cursors
gtk-cursor-theme-size=24
gtk-font-name=Inter 10
gtk-application-prefer-dark-theme=1
gtk-decoration-layout=appmenu:none
gtk-enable-animations=1
GTK3EOF

# GTK-4 settings (same)
cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"

# Qt font via qt6ct
mkdir -p "$HOME/.config/qt6ct"
cat > "$HOME/.config/qt6ct/qt6ct.conf" << 'QTEOF'
[Appearance]
style=kvantum-dark
color_scheme_path=/usr/share/qt6ct/colors/catppuccin-mocha.conf
custom_palette=false
standard_dialogs=default

[Fonts]
fixed="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
general="Inter,10,-1,5,50,0,0,0,0,0"
QTEOF

ok "System fonts configured (Inter + JetBrains Mono)"

# =====================================================================
# MODULE 6: Performance & Deep System Tuning
# =====================================================================
header "Performance & Deep System Tuning"

# --- Power management ---
# thermald only for Intel CPUs
if lscpu | grep -qi 'intel'; then
    install_pkg thermald powertop
    sudo systemctl enable --now thermald.service
    ok "Intel thermald enabled"
fi

# --- Earlyoom (prevent OOM freeze) ---
install_pkg earlyoom
sudo systemctl enable --now earlyoom.service

# --- GameMode (auto-boost CPU/GPU during gaming) ---
log "Installing GameMode..."
install_pkg gamemode lib32-gamemode
ok "GameMode installed (use: gamemoderun ./game)"

# --- PipeWire low-latency audio ---
log "Configuring PipeWire low-latency..."
mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
cat > "$HOME/.config/pipewire/pipewire.conf.d/99-lowlatency.conf" << 'PWEOF'
context.properties = {
    default.clock.rate          = 48000
    default.clock.quantum       = 512
    default.clock.min-quantum   = 32
    default.clock.max-quantum   = 2048
}
PWEOF
ok "PipeWire low-latency configured"

# --- Kernel tuning (sysctl) ---
log "Applying kernel performance tuning..."
sudo tee /etc/sysctl.d/99-performance.conf > /dev/null << 'SYSEOF'
# — Memory Management —
# Reduce swap aggressiveness (16GB RAM = less swap needed)
vm.swappiness = 10
# Keep filesystem metadata cached longer
vm.vfs_cache_pressure = 50
# Dirty page writeback tuning (better for NVMe)
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# — Network Performance —
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1

# — Kernel Hardening + Performance —
kernel.nmi_watchdog = 0
# Increase inotify watchers (for VS Code, Node.js file watching)
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
SYSEOF
sudo sysctl --system 2>/dev/null || true
ok "Kernel sysctl tuning applied"

# --- NVMe I/O scheduler optimization ---
log "Setting NVMe I/O scheduler..."
# 'none' is optimal for NVMe SSDs (no scheduling overhead needed)
for dev in /sys/block/nvme*/queue/scheduler; do
    [ -f "$dev" ] && echo 'none' | sudo tee "$dev" > /dev/null 2>&1 || true
done
# Make it persistent via udev rule
sudo tee /etc/udev/rules.d/60-ioscheduler.rules > /dev/null << 'IOEOF'
# NVMe: no scheduler (fastest)
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
# SATA SSD: mq-deadline
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# HDD: bfq
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
IOEOF
ok "I/O scheduler optimized (NVMe=none, SSD=mq-deadline, HDD=bfq)"

# --- Transparent Huge Pages ---
log "Setting transparent hugepages to madvise..."
echo 'madvise' | sudo tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null 2>&1 || true
# Persist via kernel parameter
sudo mkdir -p /etc/tmpfiles.d
echo 'w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise' | \
    sudo tee /etc/tmpfiles.d/thp.conf > /dev/null
ok "THP set to madvise (apps opt-in for huge pages)"

# --- Filesystem ---
sudo systemctl enable --now fstrim.timer

# --- Journal size limit ---
sudo journalctl --vacuum-size=256M 2>/dev/null || true
sudo mkdir -p /etc/systemd/journald.conf.d
echo -e "[Journal]\nSystemMaxUse=256M" | sudo tee /etc/systemd/journald.conf.d/size.conf >/dev/null

# --- Intel GuC/HuC firmware (Intel GPU only) ---
if lspci | grep -qi 'intel.*graphics\|intel.*iris'; then
    log "Enabling Intel GuC/HuC firmware..."
    sudo mkdir -p /etc/modprobe.d
    echo 'options i915 enable_guc=3' | sudo tee /etc/modprobe.d/i915.conf > /dev/null
    ok "Intel i915 GuC/HuC enabled (GPU hardware scheduling)"
fi

ok "Deep system tuning complete"

# =====================================================================
# MODULE 7: Security & Maintenance
# =====================================================================
header "Security & Maintenance"

install_pkg ufw timeshift

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw --force enable
sudo systemctl enable --now ufw.service

ok "Firewall & backup tools configured"

# --- SSH key auto-generate ---
log "Generating SSH key..."
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" -N "" -q
    eval "$(ssh-agent -s)" 2>/dev/null
    ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
    ok "SSH key generated (add to GitHub: cat ~/.ssh/id_ed25519.pub)"
else
    ok "SSH key already exists"
fi

# --- Cloudflare DNS (1.1.1.1 — faster + privacy) ---
log "Setting Cloudflare DNS..."
sudo mkdir -p /etc/systemd/resolved.conf.d
cat << 'DNSEOF' | sudo tee /etc/systemd/resolved.conf.d/dns.conf > /dev/null
[Resolve]
DNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
DNSOverTLS=yes
Domains=~.
DNSEOF
sudo systemctl restart systemd-resolved 2>/dev/null || true
ok "DNS set to Cloudflare 1.1.1.1 (encrypted)"

# --- Zram tuning ---
log "Optimizing Zram..."
if [ -f /sys/block/zram0/comp_algorithm ]; then
    # CachyOS already has zram, just optimize compression
    echo 'zstd' | sudo tee /sys/block/zram0/comp_algorithm > /dev/null 2>&1 || true
    ok "Zram compression set to zstd (best ratio)"
else
    install_pkg zram-generator
    sudo mkdir -p /etc/systemd
    cat << 'ZRAMEOF' | sudo tee /etc/systemd/zram-generator.conf > /dev/null
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
ZRAMEOF
    ok "Zram configured (50% of RAM, zstd compression)"
fi

# --- Weekly auto-cleanup (pacman cache + orphan packages) ---
log "Setting up weekly auto-cleanup..."
sudo mkdir -p /etc/systemd/system
cat << 'CLEANEOF' | sudo tee /etc/systemd/system/pacman-cleanup.service > /dev/null
[Unit]
Description=Clean pacman cache and orphan packages
[Service]
Type=oneshot
ExecStart=/usr/bin/paccache -rk 2
ExecStart=/bin/bash -c 'pacman -Qdtq | xargs -r sudo pacman -Rns --noconfirm 2>/dev/null || true'
CLEANEOF
cat << 'TIMEREOF' | sudo tee /etc/systemd/system/pacman-cleanup.timer > /dev/null
[Unit]
Description=Weekly pacman cache cleanup
[Timer]
OnCalendar=weekly
Persistent=true
[Install]
WantedBy=timers.target
TIMEREOF
sudo systemctl enable --now pacman-cleanup.timer 2>/dev/null || true
ok "Weekly auto-cleanup enabled (pacman cache + orphan removal)"

# --- Global .gitignore ---
log "Creating global .gitignore..."
cat > "$HOME/.gitignore_global" << 'GIEOF'
# OS files
.DS_Store
Thumbs.db
Desktop.ini
*~

# Editor files
.vscode/settings.json
.idea/
*.swp
*.swo
*~

# Dependencies
node_modules/
__pycache__/
*.pyc
.venv/
venv/
target/
build/
dist/

# Environment
.env
.env.local
.env.*.local

# Logs
*.log
npm-debug.log*

# Build artifacts
*.o
*.so
*.class
*.jar
GIEOF
git config --global core.excludesFile "$HOME/.gitignore_global"
ok "Global .gitignore configured"

# =====================================================================
# MODULE 8: Dotfiles & Configuration
# =====================================================================
header "Dotfiles & Configuration"

# --- Directory structure ---
log "Creating project directories..."
mkdir -p "$HOME/projects" "$HOME/scripts" "$HOME/docker" "$HOME/.config"

# --- Kitty config (Catppuccin Mocha) ---
log "Writing Kitty config..."
mkdir -p "$HOME/.config/kitty"
cat > "$HOME/.config/kitty/kitty.conf" << 'KITTYEOF'
# — Kitty — Catppuccin Mocha —
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        12.0

# Window
window_padding_width     12
background_opacity       0.92
dynamic_background_opacity yes
confirm_os_window_close  0
hide_window_decorations  no
remember_window_size     yes

# Cursor
cursor_shape             beam
cursor_beam_thickness    1.5
cursor_blink_interval    0.5

# Scrollback
scrollback_lines         10000

# Bell
enable_audio_bell        no

# Tab bar
tab_bar_style            powerline
tab_powerline_style      slanted
active_tab_font_style    bold

# — Catppuccin Mocha Colors —
# The basic 16 colors
foreground              #CDD6F4
background              #1E1E2E
selection_foreground     #1E1E2E
selection_background     #F5E0DC
cursor                  #F5E0DC
cursor_text_color       #1E1E2E
url_color               #F5E0DC
active_border_color     #B4BEFE
inactive_border_color   #6C7086
bell_border_color       #F9E2AF
active_tab_foreground   #11111B
active_tab_background   #CBA6F7
inactive_tab_foreground #CDD6F4
inactive_tab_background #181825
tab_bar_background      #11111B

# Normal
color0  #45475A
color1  #F38BA8
color2  #A6E3A1
color3  #F9E2AF
color4  #89B4FA
color5  #F5C2E7
color6  #94E2D5
color7  #BAC2DE

# Bright
color8  #585B70
color9  #F38BA8
color10 #A6E3A1
color11 #F9E2AF
color12 #89B4FA
color13 #F5C2E7
color14 #94E2D5
color15 #A6ADC8

mark1_foreground #1E1E2E
mark1_background #B4BEFE
mark2_foreground #1E1E2E
mark2_background #CBA6F7
mark3_foreground #1E1E2E
mark3_background #74C7EC
KITTYEOF
ok "Kitty config written"

# --- Starship config ---
log "Writing Starship config..."
mkdir -p "$HOME/.config"
cat > "$HOME/.config/starship.toml" << 'STAREOF'
# — Starship — Catppuccin Mocha —
palette = "catppuccin_mocha"

format = """
[—](#89B4FA)\
$os\
$username\
[](bg:#CBA6F7 fg:#89B4FA)\
$directory\
[](fg:#CBA6F7 bg:#F5C2E7)\
$git_branch\
$git_status\
[](fg:#F5C2E7 bg:#F38BA8)\
$nodejs\
$python\
$rust\
$golang\
$java\
$kotlin\
$dart\
$docker_context\
[](fg:#F38BA8 bg:#F9E2AF)\
$time\
[ ](fg:#F9E2AF)\
$line_break\
$character"""

[os]
disabled = false
style = "bg:#89B4FA fg:#1E1E2E"
[os.symbols]
Arch = "ó°£‡ "
Linux = " "

[username]
show_always = true
style_user = "bg:#89B4FA fg:#1E1E2E"
style_root = "bg:#89B4FA fg:#1E1E2E"
format = '[$user ]($style)'
disabled = false

[directory]
style = "bg:#CBA6F7 fg:#1E1E2E"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "—/"

[git_branch]
symbol = ""
style = "bg:#F5C2E7 fg:#1E1E2E"
format = '[ $symbol $branch ]($style)'

[git_status]
style = "bg:#F5C2E7 fg:#1E1E2E"
format = '[$all_status$ahead_behind ]($style)'

[nodejs]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[python]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[rust]
symbol = "ðŸ¦€"
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[golang]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[docker_context]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol $context ]($style)'

[java]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[kotlin]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[dart]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[time]
disabled = false
time_format = "%R"
style = "bg:#F9E2AF fg:#1E1E2E"
format = '[ ó°¥” $time ]($style)'

[character]
success_symbol = '[—](bold #A6E3A1)'
error_symbol = '[—](bold #F38BA8)'

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
subtext1 = "#bac2de"
subtext0 = "#a6adc8"
overlay2 = "#9399b2"
overlay1 = "#7f849c"
overlay0 = "#6c7086"
surface2 = "#585b70"
surface1 = "#45475a"
surface0 = "#313244"
base = "#1e1e2e"
mantle = "#181825"
crust = "#11111b"
STAREOF
ok "Starship config written"

# --- Zshrc ---
log "Writing .zshrc..."
cat > "$HOME/.zshrc" << 'ZSHEOF'
# — CachyOS Zsh Config — Aesthetic + Productive —
export ZSH="$HOME/.oh-my-zsh"

# Plugins
plugins=(
    git
    docker
    docker-compose
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    fzf-tab
    sudo
    command-not-found
    colored-man-pages
)

source $ZSH/oh-my-zsh.sh

# — Starship Prompt —
eval "$(starship init zsh)"

# — Tool Initialization —
eval "$(fnm env --use-on-cd)"
eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"      # auto-load .envrc per project

# Cargo/Rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# uv (Python)
export PATH="$HOME/.local/bin:$PATH"

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Antigravity
export PATH="$HOME/.local/share/antigravity/bin:$PATH"

# Flutter & Android SDK
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
export PATH="$HOME/.flutter-sdk/bin:$PATH"
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
export CHROME_EXECUTABLE="$(which zen-browser 2>/dev/null || which firefox 2>/dev/null || echo '')"

# — Modern Aliases —
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --icons --level=2'
alias la='eza -a --icons --group-directories-first'
alias cat='bat --style=auto'
alias grep='rg'
alias find='fd'
alias top='btm'
alias du='dust'
alias df='duf'
alias ps='procs'
alias cd='z'
alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -pv'

# Git aliases
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias ga='git add'
alias gco='git checkout'
alias gb='git branch'
alias gpl='git pull'

# System aliases
alias update='sudo pacman -Syu && flatpak update -y && rustup update 2>/dev/null; echo "— System updated"'
alias cleanup='sudo pacman -Sc --noconfirm && pacman -Qdtq | xargs -r sudo pacman -Rns --noconfirm 2>/dev/null; echo "— Cleanup done"'
alias ff='fastfetch'
alias keys='cat ~/.config/hypr/cheatsheet.txt 2>/dev/null || echo "Hyprland cheatsheet not found"'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me && echo ""'
alias weather='curl -s wttr.in/?format=3'
alias record='wf-recorder -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4'
alias clip='wf-recorder -g "$(slurp)" -f ~/Videos/clip-$(date +%Y%m%d-%H%M%S).mp4'
alias screenshot='grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png'

# Docker aliases
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlog='docker logs -f'
alias dex='docker exec -it'
alias lzd='lazydocker'

# Tmux
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux list-sessions'
alias tk='tmux kill-session -t'

# System
alias update='sudo pacman -Syu && paru -Sua'
alias cleanup='sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null; paru -Sc --noconfirm'
alias ff='fastfetch'
alias keys='cat ~/.config/hypr/cheatsheet.txt 2>/dev/null || echo "Hyprland not configured"'

# — FZF Config —
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --border rounded --margin 1 --padding 1"

# — Greeting —
fastfetch 2>/dev/null || true
ZSHEOF
ok ".zshrc written"

# --- Set zsh as default shell ---
log "Setting zsh as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
fi

# --- bat theme ---
log "Configuring bat theme..."
mkdir -p "$HOME/.config/bat"
echo '--theme="Catppuccin Mocha"' > "$HOME/.config/bat/config"

# --- btm (bottom) config ---
mkdir -p "$HOME/.config/bottom"
cat > "$HOME/.config/bottom/bottom.toml" << 'BTMEOF'
[flags]
color = "gruvbox"
dot_marker = true
group_processes = true
hide_table_gap = true
rate = "500ms"
BTMEOF

# --- fastfetch config ---
mkdir -p "$HOME/.config/fastfetch"
cat > "$HOME/.config/fastfetch/config.jsonc" << 'FFEOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "display": { "separator": " → " },
    "modules": [
        "title", "separator",
        "os", "host", "kernel",
        "uptime", "packages",
        "shell", "de", "wm",
        "terminal", "terminalfont",
        "cpu", "gpu", "memory",
        "swap", "disk",
        "localip", "battery",
        "separator", "colors"
    ]
}
FFEOF

# --- Antigravity / VS Code Catppuccin Settings ---
# Antigravity is a VS Code fork, uses same config path
log "Configuring Antigravity editor aesthetic..."
VSCODE_DIR="$HOME/.config/Code/User"
mkdir -p "$VSCODE_DIR"
cat > "$VSCODE_DIR/settings.json" << 'VSCEOF'
{
    "workbench.colorTheme": "Catppuccin Mocha",
    "workbench.iconTheme": "catppuccin-mocha",
    "workbench.productIconTheme": "catppuccin-mocha",
    "editor.fontFamily": "'JetBrainsMono Nerd Font', 'JetBrains Mono', monospace",
    "editor.fontSize": 14,
    "editor.fontLigatures": true,
    "editor.lineHeight": 1.6,
    "editor.cursorBlinking": "smooth",
    "editor.cursorSmoothCaretAnimation": "on",
    "editor.smoothScrolling": true,
    "editor.minimap.enabled": false,
    "editor.renderWhitespace": "boundary",
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": true,
    "editor.stickyScroll.enabled": true,
    "terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font'",
    "terminal.integrated.fontSize": 13,
    "terminal.integrated.cursorStyle": "line",
    "terminal.integrated.defaultProfile.linux": "zsh",
    "window.titleBarStyle": "custom",
    "window.menuBarVisibility": "toggle",
    "workbench.list.smoothScrolling": true,
    "workbench.tree.indent": 16,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000
}
VSCEOF

# Install Catppuccin extensions (will run on first VS Code launch)
cat > "$VSCODE_DIR/extensions.json" << 'VSCEXTEOF'
{
    "recommendations": [
        "catppuccin.catppuccin-vsc",
        "catppuccin.catppuccin-vsc-icons",
        "catppuccin.catppuccin-vsc-pack"
    ]
}
VSCEXTEOF
ok "VS Code Catppuccin configured"

# --- Neovim + Catppuccin (lazy.nvim) ---
log "Configuring Neovim with Catppuccin..."
NVIM_DIR="$HOME/.config/nvim"
mkdir -p "$NVIM_DIR/lua/plugins"

# Init lazy.nvim
cat > "$NVIM_DIR/init.lua" << 'NVIMINIT'
-- — Neovim — Catppuccin Mocha —
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({ "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- Catppuccin colorscheme
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
                transparent_background = true,
                integrations = {
                    treesitter = true,
                    telescope = { enabled = true },
                    which_key = true,
                    indent_blankline = { enabled = true },
                    mini = { enabled = true },
                },
            })
            vim.cmd.colorscheme("catppuccin")
        end,
    },
    -- File explorer
    { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" },
      config = function() require("nvim-tree").setup() end },
    -- Fuzzy finder
    { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    -- Statusline
    { "nvim-lualine/lualine.nvim", config = function()
        require("lualine").setup({ options = { theme = "catppuccin" } })
    end },
    -- Treesitter
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    -- Which-key (keybinding helper)
    { "folke/which-key.nvim", config = function() require("which-key").setup() end },
    -- Indent guides
    { "lukas-reineke/indent-blankline.nvim", main = "ibl",
      config = function() require("ibl").setup() end },
    -- Auto pairs
    { "windwp/nvim-autopairs", config = function() require("nvim-autopairs").setup() end },
    -- Git signs
    { "lewis6991/gitsigns.nvim", config = function() require("gitsigns").setup() end },
})
NVIMINIT
ok "Neovim + lazy.nvim + Catppuccin configured"

ok "All dotfiles written"

