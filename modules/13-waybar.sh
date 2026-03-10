#!/usr/bin/env bash
# Module 13: Waybar Status Bar
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
skip_if_current
header "Waybar — Aesthetic Status Bar for Hyprland"

mkdir -p "$HOME/.config/waybar"

# Ensure required packages are installed for interactive modules
install_pkg playerctl cava pavucontrol waypaper btop

# Waybar config
safe_config "$HOME/.config/waybar/config.jsonc"
cat > "$HOME/.config/waybar/config.jsonc" << 'WBCONF'
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
        "tooltip-format": "{capacity}%\nLeft-click: Open btop",
        "on-click": "kitty -e btop"
    },
    "network": {
        "format-wifi": "󰤨  {signalStrength}%",
        "format-ethernet": "󰈀 Connected",
        "format-disconnected": "󰤭  Off",
        "tooltip-format": "{ifname} via {gwaddr}\nLeft-click: Wi-Fi Menu",
        "on-click": "~/.config/rofi/scripts/rofi-wifi-menu.sh"
    },
    "pulseaudio": {
        "format": "{icon}  {volume}%",
        "format-muted": "󰝟 Muted",
        "format-icons": { "default": ["󰕿", "󰖀", "󰕾"] },
        "tooltip": true,
        "tooltip-format": "Volume: {volume}%\nScroll: Adjust Volume\nRight-click: Mute/Unmute\nLeft-click: Pavucontrol",
        "on-click": "hyprctl dispatch exec pavucontrol",
        "on-click-right": "pactl set-sink-mute @DEFAULT_SINK@ toggle",
        "on-scroll-up": "pactl set-sink-volume @DEFAULT_SINK@ +5%",
        "on-scroll-down": "pactl set-sink-volume @DEFAULT_SINK@ -5%"
    },
    "backlight": {
        "format": "󰃠  {percent}%",
        "tooltip": true,
        "tooltip-format": "Brightness: {percent}%\nScroll: Adjust Brightness\nLeft-click: 100% Brightness",
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
        "exec": "playerctl -a metadata --format '{\\\"text\\\": \\\"{{artist}} - {{markup_escape(title)}}\\\", \\\"tooltip\\\": \\\"{{playerName}} : {{markup_escape(title)}}\\\", \\\"alt\\\": \\\"{{status}}\\\", \\\"class\\\": \\\"{{status}}\\\"}' -F",
        "format-icons": {
            "Playing": "<span foreground='#a6e3a1'>󰈇</span>",
            "Paused": "<span foreground='#f38ba8'>󰈤</span>"
        }
    }
}
WBCONF

# Waybar Catppuccin style
safe_config "$HOME/.config/waybar/style.css"
cat > "$HOME/.config/waybar/style.css" << 'WBSTYLE'
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
WBSTYLE

# Create Media Hub script
mkdir -p "$HOME/.config/waybar/scripts"
cat << 'MHSCRIPT' > "$HOME/.config/waybar/scripts/media-hub.sh"
#!/usr/bin/env bash

# Media Hub Script for Waybar & Rofi
# Fetches current playing media and shows a beautiful dashboard

STATUS=$(playerctl status 2>/dev/null)

if [[ -z "$STATUS" ]]; then
    notify-send "Media Hub" "No media player is currently running."
    exit 1
fi

TITLE=$(playerctl metadata title 2>/dev/null | cut -c 1-35)
ARTIST=$(playerctl metadata artist 2>/dev/null | cut -c 1-35)
[[ ${#TITLE} -ge 35 ]] && TITLE="${TITLE}..."
[[ ${#ARTIST} -ge 35 ]] && ARTIST="${ARTIST}..."
# Define cover image path for rofi
COVER="/tmp/rofi-media-cover.png"

while true; do
    STATUS=$(playerctl status 2>/dev/null)
    if [[ -z "$STATUS" ]]; then
        exit 0
    fi

    TITLE=$(playerctl metadata title 2>/dev/null | cut -c 1-35)
    ARTIST=$(playerctl metadata artist 2>/dev/null | cut -c 1-35)
    [[ ${#TITLE} -ge 35 ]] && TITLE="${TITLE}..."
    [[ ${#ARTIST} -ge 35 ]] && ARTIST="${ARTIST}..."

    # Generate a unique cover path via md5 sum safely handling any UTF-8 strings
    TRACK_ID=$(echo "${ARTIST}-${TITLE}" | md5sum | cut -d' ' -f1)
    COVER="/tmp/rofi-media-cover-${TRACK_ID}.png"
    
    # Clean up old covers to prevent /tmp bloat
    find /tmp -name "rofi-media-cover-*.png" ! -name "rofi-media-cover-${TRACK_ID}.png" -type f -delete 2>/dev/null

    ART_URL=$(playerctl metadata mpris:artUrl 2>/dev/null | sed 's/file:\/\///')

    # Decode URL-encoded characters (like %20 for spaces)
    if command -v python3 >/dev/null 2>&1; then
        ART_URL=$(python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" "$ART_URL" 2>/dev/null || echo "$ART_URL")
    fi

    # Fetch or copy the cover art for the current track
    if [[ -n "$ART_URL" ]] && [[ ! -f "$COVER" ]]; then
        if [[ "$ART_URL" == http* ]]; then
            curl -s "$ART_URL" -o "$COVER"
        else
            cp "$ART_URL" "$COVER" 2>/dev/null || touch "$COVER"
        fi
    elif [[ ! -f "$COVER" ]]; then
        # Fallback to a blank image
        touch "$COVER"
    fi

    # Define menu options
    PREV="󰒮 Prev"
    NEXT="󰒭 Next"
    VISUALIZER="󱍙 Visualizer"

    if [[ "$STATUS" == "Playing" ]]; then
        PLAY_PAUSE="󰏤 Pause"
    else
        PLAY_PAUSE="󰐊 Play"
    fi

    OPTIONS="${PREV}\n${PLAY_PAUSE}\n${NEXT}\n${VISUALIZER}"

    CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu \
        -p "Media" \
        -mesg "<span weight='bold' size='large'>${TITLE}</span> - <span size='medium'>${ARTIST}</span>" \
        -hover-select \
        -me-select-entry '' \
        -me-accept-entry MousePrimary \
        -theme ~/.config/rofi/media.rasi \
        -theme-str "cover-art { background-image: url(\"${COVER}\", width); }")

    case "$CHOICE" in
        "$PREV")
            RAW_TITLE=$(playerctl metadata title 2>/dev/null)
            if playerctl previous 2>/dev/null; then
                # Wait up to 2 seconds for metadata to update
                for i in {1..20}; do
                    NEW_RAW=$(playerctl metadata title 2>/dev/null)
                    [[ "$NEW_RAW" != "$RAW_TITLE" ]] && break
                    sleep 0.1
                done
            fi
            ;;
        "$PLAY_PAUSE")
            playerctl play-pause 2>/dev/null
            ;;
        "$NEXT")
            RAW_TITLE=$(playerctl metadata title 2>/dev/null)
            if playerctl next 2>/dev/null; then
                # Wait up to 2 seconds for metadata to update
                for i in {1..20}; do
                    NEW_RAW=$(playerctl metadata title 2>/dev/null)
                    [[ "$NEW_RAW" != "$RAW_TITLE" ]] && break
                    sleep 0.1
                done
            fi
            ;;
        "$VISUALIZER")
            if command -v cava >/dev/null 2>&1; then
                kitty --class cava-floating -e cava &
            else
                notify-send "Visualizer" "Cava is not installed. Please install it via 'sudo pacman -S cava'."
            fi
            exit 0
            ;;
        *)
            # Exit if clicked outside or pressed ESC
            exit 0
            ;;
    esac
    # Small delay to let playerctl catch up before re-fetching status
    sleep 0.1
done
MHSCRIPT
chmod +x "$HOME/.config/waybar/scripts/media-hub.sh"

# Create aesthetic Cava config
mkdir -p "$HOME/.config/cava"
cat << 'CAVACONF' > "$HOME/.config/cava/config"
[general]
framerate = 60
sensitivity = 100
bars = 0
bar_width = 3
bar_spacing = 1
[color]
gradient = 1
gradient_count = 6
gradient_color_1 = '#89b4fa'
gradient_color_2 = '#cba6f7'
gradient_color_3 = '#f5c2e7'
gradient_color_4 = '#eba0ac'
gradient_color_5 = '#fab387'
gradient_color_6 = '#f9e2af'
[smoothing]
integral = 77
monstercat = 1
waves = 0
noise_reduction = 0.77
CAVACONF

# --- Rofi Main Catppuccin Theme ---
log "Writing Rofi Main Catppuccin theme..."
mkdir -p "$HOME/.config/rofi"
safe_config "$HOME/.config/rofi/config.rasi"
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
ROFIEOF

# Create Rofi Media Theme
mkdir -p "$HOME/.config/rofi"
cat << 'MEDIARASI' > "$HOME/.config/rofi/media.rasi"
configuration {
    show-icons: false;
}

* {
    /* Catppuccin Mocha Glass */
    bg:       #1e1e2edd;     /* Base transparent */
    bg-alt:   #313244cc;     /* Surface0 transparent */
    fg:       #cdd6f4;       /* Text */
    accent:   #cba6f7;       /* Mauve */
    sel:      #cba6f744;     /* Mauve transparent for selection */

    font:     "Inter Medium 12";
    background-color: transparent;
}

window {
    width: 600px;
    transparency: "real";
    background-color: @bg;
    border: 2px solid;
    border-color: @accent;
    border-radius: 16px;
    padding: 24px;
}

mainbox {
    orientation: horizontal;
    children: [ left-box, listview ];
    spacing: 24px;
}

left-box {
    orientation: vertical;
    width: 250px;
    expand: false;
    children: [ cover-art, message ];
    spacing: 16px;
}

cover-art {
    width: 250px;
    height: 150px;
    border-radius: 12px;
}

message {
    background-color: @bg-alt;
    padding: 16px;
    border-radius: 10px;
    border: 1px solid;
    border-color: rgba(203, 166, 247, 0.3); /* Subtle accent border */
}

textbox {
    text-color: @fg;
    horizontal-align: 0.5;
    vertical-align: 0.5;
    font: "Inter 11";
}

listview {
    lines: 5;
    columns: 1;
    spacing: 8px;
    dynamic: true;
    layout: vertical;
    fixed-height: false;
}

element {
    padding: 14px 18px;
    border-radius: 10px;
    background-color: transparent;
    text-color: @fg;
    cursor: pointer;
}

element-text {
    background-color: inherit;
    text-color: inherit;
    horizontal-align: 0.0;
    vertical-align: 0.5;
    cursor: pointer;
}

element selected {
    background-color: @accent;
    text-color: @bg;
}
MEDIARASI

# --- Deploy Rofi Wi-Fi Menu script ---
log "Writing Rofi Wi-Fi Menu script..."
mkdir -p "$HOME/.config/rofi/scripts"
cat << 'WIFISCRIPT' > "$HOME/.config/rofi/scripts/rofi-wifi-menu.sh"
#!/usr/bin/env bash
set -euo pipefail

# Rofi Wi-Fi Menu for Waybar — Catppuccin Glassmorphic
ROFI_OPTS="-dmenu -i -p Wi-Fi"

notify_info() { dunstify -a "NetworkManager" -i network-wireless -t 3000 "$1"; }
notify_err() { dunstify -a "NetworkManager" -u critical -i network-wireless-disconnected -t 5000 "$1"; }

# Handle Wi-Fi disabled state
if [[ $(nmcli -t -f WIFI g) == "disabled" ]]; then
    chosen_network=$(echo "Enable Wi-Fi" | rofi $ROFI_OPTS -mesg "Wi-Fi is currently disabled.")
    if [[ "$chosen_network" == "Enable Wi-Fi" ]]; then
        nmcli radio wifi on
        notify_info "Wi-Fi enabled. Please wait..."
        sleep 3
        exec "$0"
    fi
    exit 0
fi

# Get available networks
wifi_list=$(nmcli --fields "IN-USE,SSID,SECURITY,SIGNAL" device wifi list | sed 1d | sed -E 's/^ *//g')

toggle_off="󰤮 Disable Wi-Fi"

formatted_list=$(echo "$wifi_list" | awk -F'  +' '{
    active = ($1 == "*") ? "󰤨 " : "  "
    ssid = $2
    sec = ($3 == "--") ? "🔓 Open" : "🔒 "$3
    sig = $4"%"
    if (ssid != "--" && ssid != "") {
        printf "%s %-25s | %-12s | %s\n", active, ssid, sec, sig
    }
}' | sort -u)

all_options="$toggle_off\n$formatted_list"
chosen_line=$(echo -e "$all_options" | rofi $ROFI_OPTS -window-title "Networks")

[[ -z "$chosen_line" ]] && exit 0

if [[ "$chosen_line" == "$toggle_off" ]]; then
    nmcli radio wifi off
    notify_info "Wi-Fi Disabled"
    exit 0
fi

chosen_ssid=$(echo "$chosen_line" | awk -F' \\| ' '{print $1}' | sed 's/^[^ ]* //' | sed 's/ *$//')
is_active=$(echo "$chosen_line" | grep -q "󰤨" && echo "yes" || echo "no")

if [[ "$is_active" == "yes" ]]; then
    action=$(echo -e "Disconnect\nCancel" | rofi -dmenu -i -p "Active: $chosen_ssid")
    if [[ "$action" == "Disconnect" ]]; then
        nmcli connection down id "$chosen_ssid"
        notify_info "Disconnected from $chosen_ssid"
    fi
    exit 0
fi

is_saved=$(nmcli -t -f NAME connection show | grep -x "$chosen_ssid" || true)

if [[ -n "$is_saved" ]]; then
    notify_info "Connecting to known network: $chosen_ssid..."
    if nmcli connection up id "$chosen_ssid"; then
        notify_info "Connected to $chosen_ssid"
    else
        notify_err "Failed to connect to $chosen_ssid"
    fi
else
    needs_password=$(echo "$chosen_line" | grep -q "🔒" && echo "yes" || echo "no")
    if [[ "$needs_password" == "yes" ]]; then
        password=$(rofi -dmenu -p "Password for $chosen_ssid" -password)
        [[ -z "$password" ]] && exit 0
        notify_info "Connecting to $chosen_ssid..."
        if nmcli device wifi connect "$chosen_ssid" password "$password"; then
            notify_info "Connected to $chosen_ssid"
        else
            notify_err "Failed to connect. Bad password?"
        fi
    else
        notify_info "Connecting to open network: $chosen_ssid..."
        if nmcli device wifi connect "$chosen_ssid"; then
            notify_info "Connected to $chosen_ssid"
        else
            notify_err "Failed to connect to $chosen_ssid"
        fi
    fi
fi
WIFISCRIPT
chmod +x "$HOME/.config/rofi/scripts/rofi-wifi-menu.sh"
ok "Rofi Wi-Fi Menu deployed"

ok "Waybar and Media Hub configured with Catppuccin glass theme"
mark_module_done
