#!/usr/bin/env bash
# Module 13: Waybar Status Bar
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
skip_if_current
header "Waybar — Aesthetic Status Bar for Hyprland"

mkdir -p "$HOME/.config/waybar"

# Waybar config
safe_config "$HOME/.config/waybar/config.jsonc"
cat > "$HOME/.config/waybar/config.jsonc" << 'WBCONF'
{
    "layer": "top",
    "position": "top",
    "height": 36,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "backlight", "battery", "network", "bluetooth", "tray", "custom/power"],
    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": { "1": "󰲠", "2": "󰲢", "3": "󰲤", "4": "󰲦", "5": "󰲨", "urgent": "", "default": "" },
        "on-click": "activate"
    },
    "clock": {
        "format": "󰥔  {:%H:%M  󰃶  %a %d %b}",
        "tooltip-format": "<tt>{calendar}</tt>"
    },
    "battery": {
        "format": "{icon}  {capacity}%",
        "format-icons": ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"],
        "format-charging": "󰂄 {capacity}%"
    },
    "network": {
        "format-wifi": "󰤨  {signalStrength}%",
        "format-ethernet": "󰈀 Connected",
        "format-disconnected": "󰤭  Off",
        "tooltip-format": "{ifname}: {ipaddr}/{cidr}"
    },
    "pulseaudio": {
        "format": "{icon}  {volume}%",
        "format-muted": "󰝟 Muted",
        "format-icons": { "default": ["󰕿", "󰖀", "󰕾"] },
        "on-click": "pavucontrol"
    },
    "backlight": {
        "format": "󰃠  {percent}%"
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
    "custom/power": {
        "format": "⏻",
        "on-click": "rofi -show power-menu -modi power-menu:rofi-power-menu",
        "tooltip": false
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

#clock, #battery, #network, #pulseaudio, #backlight, #bluetooth, #tray, #custom-power {
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

ok "Waybar configured with Catppuccin glass theme"
mark_module_done

