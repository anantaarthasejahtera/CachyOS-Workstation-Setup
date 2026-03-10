package modules

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/state"
)

// InstallDesktopAndDotfiles implements 06-dotfiles, 08-desktop, 09-hyprland, 13-waybar.
func InstallDesktopAndDotfiles() error {
	fmt.Println("🌟 [Module 06-13: Desktop] Setting up Hyprland, Waybar & Dotfiles...")

	setupTerminalAndShell()
	setupDesktopAesthetic()
	setupHyprlandAndWaybar()

	fmt.Println("✅ [Module 06-13: Desktop] UI and Dotfiles configurations complete.")
	return nil
}

func setupTerminalAndShell() {
	fmt.Println("-> Installing Terminal & Shell...")
	pacman.Install("fish", "starship", "kitty")
	pacman.Install("ttf-jetbrains-mono-nerd", "ttf-firacode-nerd", "ttf-nerd-fonts-symbols-common")
	pacman.Install("ttf-inter")

	home := os.Getenv("HOME")
	os.MkdirAll(filepath.Join(home, "projects"), 0755)
	os.MkdirAll(filepath.Join(home, "scripts"), 0755)
	os.MkdirAll(filepath.Join(home, ".config/kitty"), 0755)
	os.MkdirAll(filepath.Join(home, ".config/fish"), 0755)
	os.MkdirAll(filepath.Join(home, ".config/bat"), 0755)
	os.MkdirAll(filepath.Join(home, ".config/bottom"), 0755)
	os.MkdirAll(filepath.Join(home, ".config/fastfetch"), 0755)

	// We use exec.Command for writing large configs originally handled by cat EOF
	// to avoid massive file bloat in this Go file, drawing from the ecosystem dots
	// Actually, porting them as pure Go strings ensures 100% dependency-free binary.

	writeConfig(filepath.Join(home, ".config/kitty/kitty.conf"), kittyConf)
	writeConfig(filepath.Join(home, ".config/starship.toml"), starshipConf)
	writeConfig(filepath.Join(home, ".config/fish/config.fish"), fishConf)
	writeConfig(filepath.Join(home, ".config/bat/config"), `--theme="Catppuccin Mocha"`+"\n")
	writeConfig(filepath.Join(home, ".config/bottom/bottom.toml"), bottomConf)
	writeConfig(filepath.Join(home, ".config/fastfetch/config.jsonc"), fastfetchConf)

	// Set Fish as default
	exec.Command("sudo", "chsh", "-s", "/usr/bin/fish", os.Getenv("USER")).Run()
}

func setupDesktopAesthetic() {
	fmt.Println("-> Installing Desktop Aesthetics (Catppuccin)...")
	pacman.Install("papirus-icon-theme", "kvantum", "fastfetch", "cmatrix")
	pacman.Install(
		"catppuccin-kde-theme-mocha", "papirus-folders-catppuccin",
		"catppuccin-cursors-mocha", "kvantum-theme-catppuccin-mocha",
		"catppuccin-gtk-theme-mocha", "sddm-theme-catppuccin-mocha",
	)

	// Wallpapers
	wallDir := filepath.Join(os.Getenv("HOME"), "Pictures/Wallpapers")
	os.MkdirAll(wallDir, 0755)
	fmt.Println("-> Generating Catppuccin Gradient Wallpaper...")
	pacman.Install("imagemagick")
	magickCmd := `magick -size 3840x2160 xc:'#1e1e2e' \
    \( -size 3840x2160 gradient:'#302d41'-'#1e1e2e' \) -compose overlay -composite \
    \( -size 200x200 xc:'#cba6f7' -blur 0x80 -resize 3840x2160\! \) -compose softlight -composite \
    \( -size 200x200 xc:'#89b4fa' -gravity southeast -blur 0x60 -resize 3840x2160\! \) -compose softlight -composite \
    ~/Pictures/Wallpapers/catppuccin-mocha-gradient.png`
	exec.Command("bash", "-c", magickCmd).Run()

	home := os.Getenv("HOME")
	os.MkdirAll(filepath.Join(home, ".config/gtk-3.0"), 0755)
	os.MkdirAll(filepath.Join(home, ".config/gtk-4.0"), 0755)
	os.MkdirAll(filepath.Join(home, ".config/qt6ct"), 0755)

	writeConfig(filepath.Join(home, ".config/gtk-3.0/settings.ini"), gtkConf)
	writeConfig(filepath.Join(home, ".config/gtk-4.0/settings.ini"), gtkConf)
	writeConfig(filepath.Join(home, ".config/qt6ct/qt6ct.conf"), qtConf)
}

func setupHyprlandAndWaybar() {
	fmt.Println("-> Installing Hyprland & Waybar ecosystem...")
	pacman.Install(
		"hyprland", "hyprpaper", "hyprlock", "hypridle", "xdg-desktop-portal-hyprland",
		"waybar", "rofi-wayland", "dunst", "grim", "slurp", "wl-clipboard",
		"cliphist", "brightnessctl", "playerctl", "polkit-kde-agent",
		"thunar", "nwg-look", "rofi-power-menu", "cava", "pavucontrol", "waypaper", "btop",
	)

	pacman.Remove("xdg-desktop-portal-kde")

	home := os.Getenv("HOME")
	os.MkdirAll(filepath.Join(home, ".config/hypr"), 0755)
	os.MkdirAll(filepath.Join(home, ".config/rofi"), 0755)
	os.MkdirAll(filepath.Join(home, ".config/rofi/scripts"), 0755)
	os.MkdirAll(filepath.Join(home, ".config/dunst"), 0755)
	os.MkdirAll(filepath.Join(home, ".config/waybar"), 0755)
	os.MkdirAll(filepath.Join(home, ".config/waybar/scripts"), 0755)
	os.MkdirAll(filepath.Join(home, ".config/cava"), 0755)

	writeConfig(filepath.Join(home, ".config/hypr/hyprland.conf"), hyprlandConf)
	writeConfig(filepath.Join(home, ".config/hypr/hyprpaper.conf"), hyprpaperConf)
	writeConfig(filepath.Join(home, ".config/hypr/hyprlock.conf"), hyprlockConf)
	writeConfig(filepath.Join(home, ".config/hypr/hypridle.conf"), hypridleConf)
	writeConfig(filepath.Join(home, ".config/hypr/cheatsheet.txt"), cheatsheetConf)

	showkeys := filepath.Join(home, ".config/hypr/show-keys.sh")
	writeConfig(showkeys, showkeysConf)
	exec.Command("chmod", "+x", showkeys).Run()

	writeConfig(filepath.Join(home, ".config/rofi/config.rasi"), rofiConf)
	writeConfig(filepath.Join(home, ".config/rofi/media.rasi"), rofiMediaConf)
	rofiWifi := filepath.Join(home, ".config/rofi/scripts/rofi-wifi-menu.sh")
	writeConfig(rofiWifi, rofiWifiConf)
	exec.Command("chmod", "+x", rofiWifi).Run()

	writeConfig(filepath.Join(home, ".config/dunst/dunstrc"), dunstConf)
	writeConfig(filepath.Join(home, ".config/cava/config"), cavaConf)

	writeConfig(filepath.Join(home, ".config/waybar/config.jsonc"), waybarConf)
	writeConfig(filepath.Join(home, ".config/waybar/style.css"), waybarStyle)
	waybarMedia := filepath.Join(home, ".config/waybar/scripts/media-hub.sh")
	writeConfig(waybarMedia, waybarMediaConf)
	exec.Command("chmod", "+x", waybarMedia).Run()
}

func writeConfig(path string, content string) {
	state.SafeWriteConfig(path, []byte(strings.TrimSpace(content)+"\n"), 0644)
}

// -------------------------------------------------------------------------
// HARDCODED CONFIGURATIONS (PORTED FROM BASH HEREDOCS)
// -------------------------------------------------------------------------

const kittyConf = `
# — Kitty — Catppuccin Mocha —
font_family      JetBrainsMono Nerd Font
font_size        12.0
window_padding_width     12
background_opacity       0.92
dynamic_background_opacity yes
confirm_os_window_close  0
hide_window_decorations  no
cursor_shape             beam
scrollback_lines         10000
enable_audio_bell        no
tab_bar_style            powerline
tab_powerline_style      slanted

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

color0  #45475A
color1  #F38BA8
color2  #A6E3A1
color3  #F9E2AF
color4  #89B4FA
color5  #F5C2E7
color6  #94E2D5
color7  #BAC2DE
color8  #585B70
color9  #F38BA8
color10 #A6E3A1
color11 #F9E2AF
color12 #89B4FA
color13 #F5C2E7
color14 #94E2D5
color15 #A6ADC8
`

const starshipConf = `
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
`

const fishConf = `
# — CachyOS Fish Config — Aesthetic + Productive —
set -g fish_greeting ""

if command -v starship &>/dev/null
    starship init fish | source
end

if command -v fnm &>/dev/null
    fnm env --use-on-cd --shell fish | source
end
if command -v zoxide &>/dev/null
    zoxide init fish | source
end

fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/go/bin"

set -gx EDITOR "nvim"
set -gx VISUAL "nvim"
set -gx TERMINAL "kitty"
set -gx BROWSER "zen-browser"

alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias cat='bat --style=auto'
alias grep='rg'
alias find='fd'
alias top='btm'
alias cd='z'

alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias lg='lazygit'

set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'

if command -v fastfetch &>/dev/null
    fastfetch 2>/dev/null
end
`

const bottomConf = `
[flags]
color = "default"
dot_marker = true
group_processes = true
hide_table_gap = true
rate = "500ms"
`

const fastfetchConf = `
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "display": { "separator": " → " },
    "modules": [
        "title", "separator", "os", "host", "kernel", "uptime", "packages",
        "shell", "de", "wm", "terminal", "terminalfont", "cpu", "gpu", "memory",
        "swap", "disk", "localip", "battery", "separator", "colors"
    ]
}
`

const gtkConf = `
[Settings]
gtk-theme-name=catppuccin-mocha-mauve-standard+default
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=catppuccin-mocha-dark-cursors
gtk-cursor-theme-size=24
gtk-font-name=Inter 10
gtk-application-prefer-dark-theme=1
`

const qtConf = `
[Appearance]
style=kvantum-dark
color_scheme_path=/usr/share/qt6ct/colors/catppuccin-mocha.conf
custom_palette=false
standard_dialogs=default
[Fonts]
fixed="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
general="Inter,10,-1,5,50,0,0,0,0,0"
`

const hyprlandConf = `
# — Hyprland Config — CachyOS —
monitor=,preferred,auto,1

exec-once = waybar
exec-once = dunst
exec-once = hyprpaper
exec-once = wl-paste --type text --watch cliphist store
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = hypridle

env = XCURSOR_SIZE,24
env = XCURSOR_THEME,catppuccin-mocha-dark-cursors
env = QT_QPA_PLATFORMTHEME,qt6ct

input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
    sensitivity = 0
}

general {
    gaps_in = 4
    gaps_out = 8
    border_size = 2
    col.active_border = rgba(cba6f7ee) rgba(89b4faee) 45deg
    col.inactive_border = rgba(585b70aa)
    layout = dwindle
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 6
        passes = 3
        vibrancy = 0.17
    }
}

animations {
    enabled = true
    bezier = smooth, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 5, smooth
    animation = border, 1, 8, default
    animation = fade, 1, 5, smooth
    animation = workspaces, 1, 4, smooth, slide
}

dwindle {
    pseudotile = true
    preserve_split = true
}

windowrule {
    match:class = ^(floating-helper)$
    float = 1
    center = 1
    size = 640 480
}

windowrule = float 1, match:class ^(pavucontrol)$
windowrule = opacity 0.92 override 0.85 override, match:class ^(kitty)$

$mainMod = SUPER

bind = $mainMod, Return, exec, kitty
bind = $mainMod, Q, killactive
bind = $mainMod, M, exit
bind = $mainMod, D, exec, rofi -show drun -show-icons
bind = $mainMod, X, exec, /usr/local/bin/nexus
bind = $mainMod, F, fullscreen
bind = $mainMod, Space, togglefloating
bind = $mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
bind = $mainMod, L, exec, hyprlock
bind = $mainMod, slash, exec, ~/.config/hypr/show-keys.sh

bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3

bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

bind = , Print, exec, grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindl = , XF86AudioPlay, exec, playerctl play-pause
bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
`

const hyprpaperConf = `
splash = false
ipc = on
`

const hyprlockConf = `
background {
    monitor =
    path = screenshot
    blur_passes = 4
    blur_size = 6
    brightness = 0.6
}
input-field {
    monitor =
    size = 280, 50
    outline_thickness = 2
    dots_center = true
    outer_color = rgba(203, 166, 247, 0.6)
    inner_color = rgba(30, 30, 46, 0.85)
    font_color = rgb(205, 214, 244)
    placeholder_text = <span foreground="##6c7086">  Enter Password...</span>
    rounding = 14
    position = 0, -130
    halign = center
    valign = center
}
`

const hypridleConf = `
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}
listener {
    timeout = 300
    on-timeout = loginctl lock-session
}
listener {
    timeout = 480
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
`

const cheatsheetConf = `
—  🎮 HYPRLAND KEYBINDING CHEATSHEET —
Super + Enter   → Terminal
Super + Q       → Close window
Super + D       → App Launcher
Super + X       → Nexus
Super + L       → Lock screen
Super + Space   → Float
`

const showkeysConf = `#!/usr/bin/env bash
kitty --class floating-helper \
      --override background_opacity=0.95 \
      --override initial_window_width=68c \
      --override initial_window_height=40c \
      -e sh -c "cat ~/.config/hypr/cheatsheet.txt; read -n1 -s -r -p ''"
`

const rofiConf = `
configuration {
    modi: "drun,run,window,filebrowser";
    show-icons: true;
    icon-theme: "Papirus-Dark";
    font: "Inter 11";
}
* {
    bg: #1e1e2edd;
    bg-alt: #313244cc;
    fg: #cdd6f4;
    sel: #cba6f744;
    accent: #cba6f7;
}
window { width: 600px; background-color: @bg; border: 2px solid @accent; padding: 20px; }
inputbar { children: [prompt, entry]; background-color: @bg-alt; padding: 10px; margin: 0 0 16px 0; }
prompt { text-color: @accent; background-color: transparent; }
entry { text-color: @fg; background-color: transparent; }
listview { lines: 7; background-color: transparent; }
element { padding: 8px; text-color: @fg; background-color: transparent; }
element selected { background-color: @sel; text-color: @accent; }
element-text { background-color: transparent; text-color: inherit; }
element-icon { background-color: transparent; }
`

const rofiMediaConf = `
configuration { show-icons: false; }
* { bg: #1e1e2edd; bg-alt: #313244cc; fg: #cdd6f4; accent: #cba6f7; sel: #cba6f744; font: "Inter 12"; background-color: transparent; }
window { width: 600px; background-color: @bg; border: 2px solid @accent; padding: 24px; }
mainbox { orientation: horizontal; children: [ left-box, listview ]; }
left-box { orientation: vertical; width: 250px; children: [ cover-art, message ]; }
cover-art { width: 250px; height: 150px; }
message { background-color: @bg-alt; padding: 16px; border: 1px solid @accent; }
textbox { text-color: @fg; }
listview { lines: 5; }
element { padding: 14px; text-color: @fg; }
element selected { background-color: @accent; text-color: @bg; }
element-text { background-color: inherit; text-color: inherit; }
`

const rofiWifiConf = `#!/usr/bin/env bash
# Managed by Nexus - Basic stub for UI
nmcli device wifi list
`

const dunstConf = `
[global]
    width = 350
    height = 150
    origin = top-right
    offset = 12x12
    font = Inter 10
    frame_width = 2
    corner_radius = 12
[urgency_normal]
    background = "#1e1e2eee"
    foreground = "#cdd6f4"
    frame_color = "#cba6f7"
`

const cavaConf = `
[general]
framerate = 60
[color]
gradient = 1
gradient_color_1 = '#89b4fa'
gradient_color_2 = '#cba6f7'
gradient_color_3 = '#f5c2e7'
`

const waybarConf = `
{
    "layer": "top",
    "position": "top",
    "height": 36,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock", "custom/media"],
    "modules-right": ["custom/wallpaper", "pulseaudio", "backlight", "battery", "network", "bluetooth", "tray", "custom/power"],
    "hyprland/workspaces": {
        "format": "{icon}"
    },
    "clock": {
        "format": "󰉔  {:%H:%M  󰃶  %a %d %b}"
    },
    "custom/media": {
        "format": "{icon} {text}",
        "escape": true,
        "return-type": "json",
        "on-click": "~/.config/waybar/scripts/media-hub.sh",
        "exec": "playerctl -a metadata --format '{\\\"text\\\": \\\"{{artist}} - {{markup_escape(title)}}\\\", \\\"class\\\": \\\"{{status}}\\\"}' -F"
    }
}
`

const waybarStyle = `
* { font-family: "Inter", "JetBrainsMono Nerd Font", sans-serif; font-size: 13px; }
window#waybar { background: rgba(30,30,46,0.85); border-bottom: 2px solid rgba(203,166,247,0.4); color: #cdd6f4; }
#workspaces button { color: #6c7086; }
#workspaces button.active { background: linear-gradient(135deg, #cba6f7, #89b4fa); color: #1e1e2e; }
#clock, #custom-media, #battery, #network, #pulseaudio { padding: 0 12px; background: rgba(49,50,68,0.6); }
#clock { color: #cba6f7; }
`

const waybarMediaConf = `#!/usr/bin/env bash
# Managed by Nexus - Basic stub
playerctl status
`
