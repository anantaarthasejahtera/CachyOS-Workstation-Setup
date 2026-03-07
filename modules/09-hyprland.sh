#!/usr/bin/env bash
# Module 09: Hyprland Window Manager
source "$(dirname "$0")/00-common.sh"
header "Hyprland — Tiling Window Manager + Cheatsheet"

log "Installing Hyprland ecosystem..."
# Hyprland core + CachyOS-optimized components
install_pkg hyprland hyprpaper hyprlock hypridle xdg-desktop-portal-hyprland

# Supporting apps for Hyprland
install_pkg waybar rofi-wayland dunst swww grim slurp wl-clipboard \
    cliphist brightnessctl playerctl polkit-kde-agent

# File manager & app launcher
install_pkg thunar nwg-look

ok "Hyprland packages installed"

# --- Hyprland keybinding cheatsheet ---
log "Creating Hyprland cheatsheet helper..."
mkdir -p "$HOME/.config/hypr"
cat > "$HOME/.config/hypr/cheatsheet.txt" << 'CHEATEOF'
—
—  ðŸŽ® HYPRLAND KEYBINDING CHEATSHEET — CachyOS Edition        —
—
—                                                               —
—  — ESSENTIALS —  —
—  Super + Enter          → Open Kitty Terminal                 —
—  Super + Q              → Close focused window                —
—  Super + D              → App Launcher (rofi)                 —
—  Super + X              → Nexus Command Center                —
—  Super + M              → Exit Hyprland                       —
—  Super + V              → Clipboard history                   —
—  Super + L              → Lock screen                         —
—                                                               —
—  — WINDOW MANAGEMENT —  —
—  Super + Arrow Keys     → Move focus between windows          —
—  Super + Shift + Arrows → Move window position                —
—  Super + F              → Toggle fullscreen                   —
—  Super + Space          → Toggle floating mode                —
—  Super + P              → Toggle pseudo-tiling                —
—  Super + J              → Toggle split direction              —
—  Super + Mouse Drag     → Move/resize floating window         —
—                                                               —
—  — WORKSPACES —  —
—  Super + 1-9            → Switch to workspace 1-9             —
—  Super + Shift + 1-9    → Move window to workspace 1-9        —
—  Super + Scroll          → Cycle through workspaces           —
—  Super + Tab            → Overview (if plugin enabled)        —
—                                                               —
—  — SCREENSHOTS —  —
—  Print                  → Screenshot full screen              —
—  Super + Shift + S      → Screenshot region (select area)     —
—                                                               —
—  — MEDIA —  —
—  Volume Up/Down/Mute    → Audio control                       —
—  Brightness Up/Down     → Screen brightness                   —
—                                                               —
—  — HELPER —  —
—  Super + /              → Show this cheatsheet                —
—  Type 'keys' in term    → Also shows this cheatsheet          —
—                                                               —
—
CHEATEOF

# --- Helper script to display cheatsheet via rofi ---
cat > "$HOME/.config/hypr/show-keys.sh" << 'KEYSEOF'
#!/usr/bin/env bash
# Display Hyprland keybinding cheatsheet in a floating kitty window
kitty --class floating-helper \
      --override background_opacity=0.95 \
      --override initial_window_width=68c \
      --override initial_window_height=40c \
      -e sh -c "cat ~/.config/hypr/cheatsheet.txt; read -n1 -s -r -p ''"
KEYSEOF
chmod +x "$HOME/.config/hypr/show-keys.sh"

# --- Hyprland config ---
cat > "$HOME/.config/hypr/hyprland.conf" << 'HYPREOF'
# — Hyprland Config — CachyOS Advan WorkPro —
# Monitor (auto-detect)
monitor=,preferred,auto,1

# Autostart
exec-once = waybar
exec-once = dunst
exec-once = hyprpaper
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = hypridle

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
}

animations {
    enabled = true
    bezier = smooth, 0.05, 0.9, 0.1, 1.05
    bezier = wind, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 5, smooth
    animation = windowsOut, 1, 5, smooth, popin 80%
    animation = border, 1, 8, default
    animation = borderangle, 1, 6, default
    animation = fade, 1, 5, smooth
    animation = workspaces, 1, 4, wind, slide
}

dwindle {
    pseudotile = true
    preserve_split = true
}

gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
}

# — Window Rules —
windowrulev2 = float, class:^(floating-helper)$
windowrulev2 = center, class:^(floating-helper)$
windowrulev2 = size 640 480, class:^(floating-helper)$
windowrulev2 = float, class:^(pavucontrol)$
windowrulev2 = float, class:^(blueman-manager)$
windowrulev2 = float, title:^(File Operation Progress)$
windowrulev2 = opacity 0.92 0.85, class:^(kitty)$
windowrulev2 = opacity 0.92 0.85, class:^(Code)$

# — Keybindings —
$mainMod = SUPER

bind = $mainMod, Return, exec, kitty
bind = $mainMod, Q, killactive
bind = $mainMod, M, exit
bind = $mainMod, E, exec, thunar
bind = $mainMod, D, exec, rofi -show drun -show-icons
bind = $mainMod, X, exec, ~/.local/bin/nexus
bind = $mainMod, F, fullscreen
bind = $mainMod, Space, togglefloating
bind = $mainMod, P, pseudo
bind = $mainMod, J, togglesplit
bind = $mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
bind = $mainMod, L, exec, hyprlock
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
HYPREOF

# --- Screenshot directory ---
mkdir -p "$HOME/Pictures/Screenshots"

ok "Hyprland configured with cheatsheet helper (Super + / to view)"

# --- Rofi Catppuccin Theme ---
log "Writing Rofi Catppuccin theme..."
mkdir -p "$HOME/.config/rofi"
cat > "$HOME/.config/rofi/config.rasi" << 'ROFIEOF'
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
ROFIEOF
ok "Rofi Catppuccin glass theme written"

# --- Dunst Catppuccin Notifications ---
log "Writing Dunst notification config..."
mkdir -p "$HOME/.config/dunst"
cat > "$HOME/.config/dunst/dunstrc" << 'DUNSTEOF'
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
    format = "<b>%s</b>\n%b"
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
DUNSTEOF
ok "Dunst Catppuccin notifications configured"

# --- Hyprlock (Aesthetic Lock Screen) ---
log "Writing Hyprlock config..."
cat > "$HOME/.config/hypr/hyprlock.conf" << 'LOCKEOF'
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
LOCKEOF
ok "Hyprlock aesthetic lock screen configured"

# --- Hyprpaper (wallpaper daemon) ---
log "Writing Hyprpaper config..."
WALL_DEFAULT=$(find "$HOME/Pictures/Wallpapers" -type f \( -name '*.png' -o -name '*.jpg' \) 2>/dev/null | head -1)
if [ -n "$WALL_DEFAULT" ]; then
    cat > "$HOME/.config/hypr/hyprpaper.conf" << PAPEREOF
preload = $WALL_DEFAULT
wallpaper = ,$WALL_DEFAULT
splash = false
ipc = off
PAPEREOF
    ok "Hyprpaper configured with wallpaper: $(basename "$WALL_DEFAULT")"
else
    cat > "$HOME/.config/hypr/hyprpaper.conf" << 'PAPEREOF'
# Add your wallpaper path here:
# preload = ~/Pictures/Wallpapers/your-wallpaper.png
# wallpaper = ,~/Pictures/Wallpapers/your-wallpaper.png
splash = false
ipc = off
PAPEREOF
    warn "No wallpaper found. Edit ~/.config/hypr/hyprpaper.conf manually"
fi

# --- Hypridle (auto-lock + screen off) ---
log "Writing Hypridle config..."
cat > "$HOME/.config/hypr/hypridle.conf" << 'IDLEEOF'
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

# Dim screen after 3 min
listener {
    timeout = 180
    on-timeout = brightnessctl -s set 30%
    on-resume = brightnessctl -r
}

# Lock screen after 5 min
listener {
    timeout = 300
    on-timeout = loginctl lock-session
}

# Screen off after 8 min
listener {
    timeout = 480
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
IDLEEOF
ok "Hypridle auto-lock configured"

