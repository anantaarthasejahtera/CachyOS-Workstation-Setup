#!/usr/bin/env bash
# Module 06: Shell, Terminal & Dotfiles
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
skip_if_current
# Shell, Terminal & Dotfiles Configuration
# =====================================================================
header "Shell & Terminal Aesthetic"

# --- Fish Shell ---
log "Installing Fish shell..."
install_pkg fish

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
# Dotfiles & Configuration
# =====================================================================
header "Dotfiles & Configuration"

# --- Directory structure ---
log "Creating project directories..."
mkdir -p "$HOME/projects" "$HOME/scripts" "$HOME/docker" "$HOME/.config"

# --- Kitty config (Catppuccin Mocha) ---
log "Writing Kitty config..."
mkdir -p "$HOME/.config/kitty"
safe_config "$HOME/.config/kitty/kitty.conf"
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
safe_config "$HOME/.config/starship.toml"
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
Arch = "󰣇 "
Linux = "🐧 "

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
symbol = "🌱 "
style = "bg:#F5C2E7 fg:#1E1E2E"
format = '[ $symbol $branch ]($style)'

[git_status]
style = "bg:#F5C2E7 fg:#1E1E2E"
format = '[$all_status$ahead_behind ]($style)'

[nodejs]
symbol = "󰎙 "
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[python]
symbol = "󰌠 "
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[rust]
symbol = "🦀 "
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[golang]
symbol = "󰟓 "
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[docker_context]
symbol = "󰡨 "
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol $context ]($style)'

[java]
symbol = " "
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[kotlin]
symbol = "🅺 "
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[dart]
symbol = "🎯 "
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[time]
disabled = false
time_format = "%R"
style = "bg:#F9E2AF fg:#1E1E2E"
format = '[ 󰥔 $time ]($style)'

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

# --- Fish config ---
log "Writing Fish config..."
mkdir -p "$HOME/.config/fish"
safe_config "$HOME/.config/fish/config.fish"
cat > "$HOME/.config/fish/config.fish" << 'FISHEOF'
# — CachyOS Fish Config — Aesthetic + Productive —

# Suppress Fish greeting
set -g fish_greeting ""

# — Starship Prompt —
if command -v starship &>/dev/null
    starship init fish | source
end

# — Tool Initialization (only if installed) —
if command -v fnm &>/dev/null
    fnm env --use-on-cd --shell fish | source
end
if command -v zoxide &>/dev/null
    zoxide init fish | source
end
if command -v direnv &>/dev/null
    direnv hook fish | source
end

# Cargo/Rust
if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
else if test -d "$HOME/.cargo/bin"
    fish_add_path "$HOME/.cargo/bin"
end

# uv (Python) + local bin
fish_add_path "$HOME/.local/bin"

# Go
set -gx GOPATH "$HOME/go"
fish_add_path "$GOPATH/bin"

# Antigravity
fish_add_path "$HOME/.local/share/antigravity/bin"

# Flutter & Android SDK
set -gx ANDROID_HOME "$HOME/Android/Sdk"
fish_add_path "$ANDROID_HOME/cmdline-tools/latest/bin"
fish_add_path "$ANDROID_HOME/platform-tools"
fish_add_path "$ANDROID_HOME/emulator"
fish_add_path "$HOME/.flutter-sdk/bin"
set -gx JAVA_HOME "/usr/lib/jvm/java-17-openjdk"

# Chrome executable for Flutter
if command -v zen-browser &>/dev/null
    set -gx CHROME_EXECUTABLE (command -v zen-browser)
else if command -v firefox &>/dev/null
    set -gx CHROME_EXECUTABLE (command -v firefox)
end

# ── System defaults (enforced by setup) ───────────────────
set -gx EDITOR "nvim"
set -gx VISUAL "nvim"
set -gx TERMINAL "kitty"
if command -v zen-browser &>/dev/null
    set -gx BROWSER (command -v zen-browser)
else
    set -gx BROWSER "firefox"
end

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
alias ..='z ..'
alias ...='z ../..'
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
alias lg='lazygit'

# System aliases
alias ff='fastfetch'
alias keys='cat ~/.config/hypr/cheatsheet.txt 2>/dev/null; or echo "Hyprland cheatsheet not found"'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me; and echo ""'
alias weather='curl -s wttr.in/?format=3'
alias record='wf-recorder -f ~/Videos/recording-(date +%Y%m%d-%H%M%S).mp4'
alias clip='wf-recorder -g (slurp) -f ~/Videos/clip-(date +%Y%m%d-%H%M%S).mp4'
alias screenshot='grim ~/Pictures/Screenshots/(date +%Y%m%d-%H%M%S).png'
alias cleanup='sudo pacman -Sc --noconfirm; and pacman -Qdtq | xargs -r sudo pacman -Rns --noconfirm 2>/dev/null; echo "— Cleanup done"'

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

# — FZF Config —
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -gx FZF_DEFAULT_OPTS "\
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --border rounded --margin 1 --padding 1"

# — Greeting (safe: won't break shell if fastfetch fails) —
if command -v fastfetch &>/dev/null
    fastfetch 2>/dev/null
end
FISHEOF
ok "Fish config.fish written"

# --- Set Fish as default shell ---
log "Setting Fish as default shell..."
if [ "$SHELL" != "$(which fish)" ]; then
    # Ensure fish is in /etc/shells before changing
    grep -q "$(which fish)" /etc/shells 2>/dev/null || which fish | sudo tee -a /etc/shells
    chsh -s "$(which fish)"
fi

# --- bat theme ---
log "Configuring bat theme..."
mkdir -p "$HOME/.config/bat"
echo '--theme="Catppuccin Mocha"' > "$HOME/.config/bat/config"

# --- btm (bottom) config ---
mkdir -p "$HOME/.config/bottom"
cat > "$HOME/.config/bottom/bottom.toml" << 'BTMEOF'
[flags]
color = "default"
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

ok "All dotfiles written"
mark_module_done

