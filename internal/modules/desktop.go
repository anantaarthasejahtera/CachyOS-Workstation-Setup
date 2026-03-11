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
	// CachyOS/Arch recently restructured nerd-fonts. ttf-nerd-fonts-symbols-common can pull 
	// massive metapackages. We use specific minimal packages (~30MB) instead of 1.4GB metapackages.
	pacman.Install("ttf-jetbrains-mono-nerd", "ttf-nerd-fonts-symbols")
	pacman.Install("inter-font")

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
		"catppuccin-kde-theme-mocha", "papirus-folders-catppuccin-git",
		"catppuccin-cursors-mocha", "kvantum-theme-catppuccin-mocha",
		"catppuccin-gtk-theme-git", "sddm-theme-catppuccin-git",
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
		"wireguard-tools", // VPN Drag & Drop Support
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
# — Hyprland Config — CachyOS Advan WorkPro —
# Monitor (auto-detect)
monitor=,preferred,auto,1

# Autostart
exec-once = waybar
exec-once = dunst
exec-once = swww-daemon
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = hypridle
exec-once = post-install-wizard

# — Environment —
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,catppuccin-mocha-dark-cursors
env = QT_QPA_PLATFORMTHEME,qt6ct

# — Input —
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
        tap-to-click = true
        drag_lock = true
    }
    sensitivity = 0
}

# — Appearance — Catppuccin Mocha —
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
        new_optimizations = true
        vibrancy = 0.17
    }
    shadow {
        enabled = true
        range = 15
        render_power = 3
        color = rgba(1a1a2eee)
    }
    dim_inactive = true
    dim_strength = 0.15
}

animations {
    enabled = true
    bezier = overshot, 0.05, 0.9, 0.1, 1.1
    bezier = smooth, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 4, overshot, slide
    animation = windowsOut, 1, 4, overshot, slide
    animation = border, 1, 8, default
    animation = borderangle, 1, 80, default, loop
    animation = fade, 1, 5, smooth
    animation = workspaces, 1, 5, overshot, slide
}

dwindle {
    pseudotile = true
    preserve_split = true
}

# Gestures are configured via touchpad section in input {}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    vrr = 1
    vfr = true
}

render {
    direct_scanout = true
}

cursor {
    no_hardware_cursors = true
}

# ═══════════════════════════════════════════════════════════════════════
# Window Rules — Hyprland v0.54.1 (breaking change from v0.52 and below)
# ═══════════════════════════════════════════════════════════════════════
#
# IMPORTANT: Hyprland v0.53 completely overhauled window rule syntax.
# The old syntax (v0.52 and below) is NO LONGER VALID:
#
#   ❌ OLD (broken):  windowrule = float, class:^(kitty)$
#   ❌ OLD (broken):  windowrulev2 = opacity 0.9, class:^(kitty)$
#
# The NEW syntax (v0.53+ / v0.54.1) requires:
#
#   1. Use ` + "`" + `match:` + "`" + ` prefix for matching properties (class, title, etc)
#      ✅ match:class    instead of    class:
#      ✅ match:title    instead of    title:
#
#   2. Boolean effects need EXPLICIT value (1 = on, 0 = off)
#      ✅ float 1        instead of    float
#      ✅ center 1       instead of    center
#
#   3. Opacity uses ` + "`" + `override` + "`" + ` keyword for exact values
#      ✅ opacity 0.92 override 0.85 override
#         (0.92 = active, 0.85 = inactive, "override" = exact value not multiplier)
#
#   4. Two syntax styles available:
#      a) Inline:  windowrule = effect value, match:class ^(regex)$
#      b) Block:   windowrule { match:class = ^(regex)$  effect = value }
#         Block is useful for grouping multiple effects on one window.
#
# Reference: https://wiki.hyprland.org/Configuring/Window-Rules/
# ═══════════════════════════════════════════════════════════════════════
# Window & Layer Rules
# ═══════════════════════════════════════════════════════════════════════

# — Glassmorphism Layer Rules —
layerrule = blur 1, match:namespace waybar
layerrule = ignore_alpha 0, match:namespace waybar
layerrule = blur 1, match:namespace rofi
layerrule = ignore_alpha 0, match:namespace rofi

# Named block rule — groups multiple effects for the cheatsheet popup
windowrule = float 1, match:class ^(floating-helper)$
windowrule = center 1, match:class ^(floating-helper)$
windowrule = size 640 480, match:class ^(floating-helper)$

# Cava Audio Visualizer (Holographic effect)
windowrule = float 1, match:class ^(cava-floating)$
windowrule = center 1, match:class ^(cava-floating)$
windowrule = size 800 400, match:class ^(cava-floating)$
windowrule = pin 1, match:class ^(cava-floating)$

# Inline rules — one effect per line (simpler for single-effect rules)
windowrule = float 1, match:class ^(org.pulseaudio.pavucontrol)$       # PulseAudio volume control
windowrule = size 500 320, match:class ^(org.pulseaudio.pavucontrol)$
windowrule = move 1410 45, match:class ^(org.pulseaudio.pavucontrol)$
windowrule = animation slide top, match:class ^(org.pulseaudio.pavucontrol)$
windowrule = pin 1, match:class ^(org.pulseaudio.pavucontrol)$

windowrule = float 1, match:class ^(blueman-manager)$    # Bluetooth manager
windowrule = size 500 320, match:class ^(blueman-manager)$
windowrule = move 1410 45, match:class ^(blueman-manager)$
windowrule = animation slide top, match:class ^(blueman-manager)$
windowrule = pin 1, match:class ^(blueman-manager)$
windowrule = float 1, match:class ^(waypaper)$           # Make Waypaper float so you can see changes
windowrule = float 1, match:title ^(File Operation Progress)$  # Thunar file ops

# Opacity: active=0.92, inactive=0.85 (override = exact value, not multiplier)
windowrule = opacity 0.92 override 0.85 override, match:class ^(kitty)$
windowrule = opacity 0.92 override 0.85 override, match:class ^(Code)$

# — Keybindings —
$mainMod = SUPER

bind = $mainMod, Return, exec, kitty
bind = $mainMod, Q, killactive
bind = $mainMod, M, exit
bind = $mainMod, E, exec, thunar
bind = $mainMod, D, exec, rofi -show drun -show-icons
bind = $mainMod, X, exec, /usr/local/bin/nexus
bind = $mainMod, F, fullscreen
bind = $mainMod, Space, togglefloating
bind = $mainMod, P, pseudo
bind = $mainMod, J, layoutmsg, togglesplit
bind = $mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
bind = $mainMod, L, exec, hyprlock
bind = $mainMod, N, exec, dunstctl history-pop
bind = $mainMod, slash, exec, ~/.config/hypr/show-keys.sh

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Move windows
bind = $mainMod SHIFT, left, movewindow, l
bind = $mainMod SHIFT, right, movewindow, r
bind = $mainMod SHIFT, up, movewindow, u
bind = $mainMod SHIFT, down, movewindow, d

# Workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9

# Move to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9

# Scroll workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Mouse binds
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Screenshots
bind = , Print, exec, grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png

# Media keys
bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindl = , XF86AudioPlay, exec, playerctl play-pause
bindl = , XF86AudioNext, exec, playerctl next
bindl = , XF86AudioPrev, exec, playerctl previous
bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
`

const hyprpaperConf = `
splash = false
ipc = on
`

const hyprlockConf = `
# — Hyprlock — Catppuccin Mocha Lock Screen —
background {
    monitor =
    path = screenshot
    blur_passes = 4
    blur_size = 6
    noise = 0.015
    contrast = 0.9
    brightness = 0.6
    vibrancy = 0.17
}

input-field {
    monitor =
    size = 280, 50
    outline_thickness = 2
    dots_size = 0.25
    dots_spacing = 0.3
    dots_center = true
    dots_rounding = -1
    outer_color = rgba(203, 166, 247, 0.6)
    inner_color = rgba(30, 30, 46, 0.85)
    font_color = rgb(205, 214, 244)
    fade_on_empty = true
    fade_timeout = 2000
    placeholder_text = <span foreground="##6c7086">  Enter Password...</span>
    hide_input = false
    rounding = 14
    check_color = rgba(166, 227, 161, 0.6)
    fail_color = rgba(243, 139, 168, 0.6)
    fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
    capslock_color = rgba(249, 226, 175, 0.6)
    position = 0, -130
    halign = center
    valign = center
}

# Clock
label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%H:%M")"
    color = rgba(205, 214, 244, 0.9)
    font_size = 90
    font_family = JetBrainsMono Nerd Font
    position = 0, 60
    halign = center
    valign = center
}

# Date
label {
    monitor =
    text = cmd[update:60000] echo "$(date +"%A, %d %B")"
    color = rgba(186, 194, 222, 0.7)
    font_size = 18
    font_family = Inter
    position = 0, -20
    halign = center
    valign = center
}

# Greeting
label {
    monitor =
    text = Hi, $USER
    color = rgba(203, 166, 247, 0.8)
    font_size = 14
    font_family = Inter
    position = 0, -70
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
/* — Rofi — Catppuccin Mocha Glass — */
configuration {
    modi: "drun,run,window,filebrowser";
    show-icons: true;
    icon-theme: "Papirus-Dark";
    font: "Inter 11";
    display-drun: "  Apps";
    display-run: "  Run";
    display-window: "  Windows";
    display-filebrowser: "  Files";
    drun-display-format: "{name}";
}

* {
    bg:       #1e1e2edd;
    bg-alt:   #313244cc;
    fg:       #cdd6f4;
    sel:      #cba6f744;
    accent:   #cba6f7;
    urgent:   #f38ba8;
    border-r: 14px;
}

window {
    width: 600px;
    transparency: "real";
    background-color: @bg;
    border: 2px solid;
    border-color: @accent;
    border-radius: @border-r;
    padding: 20px;
}

inputbar {
    children: [prompt, entry];
    background-color: @bg-alt;
    border-radius: 10px;
    padding: 10px 16px;
    spacing: 10px;
    margin: 0 0 16px 0;
}

prompt {
    background-color: transparent;
    text-color: @accent;
    font: "JetBrainsMono Nerd Font 12";
}

entry {
    background-color: transparent;
    text-color: @fg;
    placeholder: "Search...";
    placeholder-color: #6c7086;
}

listview {
    lines: 7;
    columns: 1;
    background-color: transparent;
    spacing: 4px;
    fixed-height: true;
}

element {
    background-color: transparent;
    text-color: @fg;
    padding: 8px 12px;
    border-radius: 8px;
}

element selected {
    background-color: @sel;
    text-color: @accent;
}

element-icon {
    size: 24px;
    background-color: transparent;
    margin: 0 10px 0 0;
}

element-text {
    background-color: transparent;
    text-color: inherit;
    vertical-align: 0.5;
}

error-message {
    padding: 20px;
    background-color: @bg-alt;
    border: 2px solid;
    border-color: @urgent;
    border-radius: @border-r;
}

textbox {
    text-color: @fg;
    vertical-align: 0.5;
    horizontal-align: 0.0;
}
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
# — Dunst — Catppuccin Mocha —
[global]
    monitor = 0
    follow = mouse
    width = 350
    height = 150
    origin = top-right
    offset = 12x12
    progress_bar = true
    progress_bar_height = 10
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    indicate_hidden = yes
    shrink = no
    separator_height = 2
    padding = 16
    horizontal_padding = 16
    text_icon_padding = 16
    frame_width = 2
    sort = yes
    idle_threshold = 120
    font = Inter 10
    line_height = 0
    markup = full
    format = "<b>%s</b>
%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    word_wrap = yes
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    min_icon_size = 32
    max_icon_size = 64
    icon_theme = Papirus-Dark
    enable_recursive_icon_lookup = true
    corner_radius = 12
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[urgency_low]
    background = "#1e1e2eee"
    foreground = "#cdd6f4"
    frame_color = "#89b4fa"
    highlight = "#89b4fa"
    timeout = 5

[urgency_normal]
    background = "#1e1e2eee"
    foreground = "#cdd6f4"
    frame_color = "#cba6f7"
    highlight = "#cba6f7"
    timeout = 10

[urgency_critical]
    background = "#1e1e2eee"
    foreground = "#cdd6f4"
    frame_color = "#f38ba8"
    highlight = "#f38ba8"
    timeout = 0
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
        "format": "{icon}",
        "format-icons": {
            "1": "󰲠", "2": "󰲢", "3": "󰲤", "4": "󰲦", "5": "󰲨",
            "6": "󰲪", "7": "󰲬", "8": "󰲮", "9": "󰲰", "10": "󰿬",
            "urgent": "󰀨",
            "default": "󰋜"
        },
        "on-click": "activate"
    },
    "clock": {
        "format": "󰉔  {:%H:%M  󰃶  %a %d %b}",
        "tooltip-format": "<tt>{calendar}</tt>"
    },
    "battery": {
        "format": "{icon}  {capacity}%",
        "format-icons": ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"],
        "format-charging": "󰂄 {capacity}%",
        "tooltip-format": "{capacity}%
Left-click: Open btop",
        "on-click": "alacritty -e btop"
    },
    "network": {
        "format-wifi": "󰤨  {signalStrength}%",
        "format-ethernet": "󰈀 Connected",
        "format-disconnected": "󰤭  Off",
        "tooltip-format": "{ifname} via {gwaddr}\nLeft-click: Network Cockpit",
        "on-click": "nexus network"
    },
    "pulseaudio": {
        "format": "{icon}  {volume}%",
        "format-muted": "󰝟 Muted",
        "format-icons": { "default": ["󰕿", "󰖀", "󰕾"] },
        "tooltip": true,
        "tooltip-format": "Volume: {volume}%
Scroll: Adjust Volume
Right-click: Mute/Unmute
Left-click: Pavucontrol",
        "on-click": "hyprctl dispatch exec pavucontrol",
        "on-click-right": "pactl set-sink-mute @DEFAULT_SINK@ toggle",
        "on-scroll-up": "pactl set-sink-volume @DEFAULT_SINK@ +5%",
        "on-scroll-down": "pactl set-sink-volume @DEFAULT_SINK@ -5%"
    },
    "backlight": {
        "format": "󰃠  {percent}%",
        "tooltip": true,
        "tooltip-format": "Brightness: {percent}%
Scroll: Adjust Brightness
Left-click: 100% Brightness",
        "on-scroll-up": "brightnessctl set +5%",
        "on-scroll-down": "brightnessctl set 5%-",
        "on-click": "brightnessctl set 100%"
    },
    "bluetooth": {
        "format": "󰂯",
        "format-connected": "󰂱 {device_alias}",
        "format-disabled": "󰂲",
        "on-click": "blueman-manager"
    },
    "tray": {
        "icon-size": 16,
        "spacing": 8
    },
    "custom/wallpaper": {
        "format": "",
        "on-click": "waypaper",
        "tooltip": false
    },
    "custom/power": {
        "format": "⏻",
        "on-click": "rofi -show power-menu -modi power-menu:/usr/bin/rofi-power-menu",
        "tooltip": false
    },
    "custom/media": {
        "format": "{icon} {text}",
        "escape": true,
        "return-type": "json",
        "max-length": 40,
        "on-click": "~/.config/waybar/scripts/media-hub.sh",
        "on-click-right": "playerctl next",
        "smooth-scrolling-threshold": 10,
        "on-scroll-up": "playerctl next",
        "on-scroll-down": "playerctl previous",
        "exec": "playerctl -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F",
        "format-icons": {
            "Playing": "<span foreground='#a6e3a1'>󰈇</span>",
            "Paused": "<span foreground='#f38ba8'>󰈤</span>"
        }
    }
}
`

const waybarStyle = `
/* — Waybar — Catppuccin Mocha Glass — */
/* Uses locally installed Inter & JetBrainsMono Nerd Font (no internet needed) */

* {
    font-family: "Inter", "JetBrainsMono Nerd Font", sans-serif;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: rgba(30, 30, 46, 0.85);
    border-bottom: 2px solid rgba(203, 166, 247, 0.4);
    color: #cdd6f4;
}

#workspaces button {
    padding: 0 8px;
    color: #6c7086;
    border-radius: 8px;
    margin: 3px 2px;
    transition: all 0.2s ease;
}

#workspaces button.active {
    background: linear-gradient(135deg, #cba6f7, #89b4fa);
    color: #1e1e2e;
    font-weight: 600;
    box-shadow: 0 0 12px rgba(203, 166, 247, 0.4);
}

#workspaces button:hover {
    background: rgba(203, 166, 247, 0.2);
    color: #cdd6f4;
}

#clock, #custom-media, #battery, #network, #pulseaudio, #backlight, #bluetooth, #tray, #custom-power, #custom-wallpaper {
    padding: 0 12px;
    margin: 4px 2px;
    border-radius: 8px;
    background: rgba(49, 50, 68, 0.6);
    transition: all 0.2s ease;
}

#clock {
    font-weight: 600;
    color: #cba6f7;
}

#battery {
    color: #a6e3a1;
}

#battery.charging { color: #f9e2af; }
#battery.warning:not(.charging) { color: #fab387; }
#battery.critical:not(.charging) { color: #f38ba8; }

#network { color: #89dceb; }
#pulseaudio { color: #f5c2e7; }
#backlight { color: #f9e2af; }
#bluetooth { color: #89b4fa; }

#custom-power {
    color: #f38ba8;
    font-size: 15px;
    padding: 0 10px;
}

#custom-power:hover {
    background: rgba(243, 139, 168, 0.2);
}

tooltip {
    background: rgba(30, 30, 46, 0.95);
    border: 1px solid #cba6f7;
    border-radius: 10px;
    color: #cdd6f4;
}
`

const waybarMediaConf = `#!/usr/bin/env bash
# Managed by Nexus - Basic stub
playerctl status
`
