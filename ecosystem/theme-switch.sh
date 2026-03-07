#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Aesthetic Theme Switcher (Dynamic Engine)
#  Swaps colors across Hyprland, Waybar, Rofi, Kitty, Dunst
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

# --- 1. Define Theme Palettes ---
# Format:   bg      bg-alt  fg      accent  urgent  border1 border2 
# (Accent is usually Mauve/Purple, Urgent is Red, Borders are gradient colors)

declare -A THEMES

THEMES["Catppuccin Mocha"]="#1e1e2edd|#313244cc|#cdd6f4|#cba6f7|#f38ba8|cba6f7ee|89b4faee|Catppuccin-Mocha"
THEMES["Catppuccin Macchiato"]="#24273add|#363a4fcc|#cad3f5|#c6a0f6|#ed8796|c6a0f6ee|8aadf4ee|Catppuccin-Macchiato"
THEMES["Catppuccin Frappe"]="#303446dd|#414559cc|#c6d0f5|#ca9ee6|#e78284|ca9ee6ee|8caaeeee|Catppuccin-Frappe"
THEMES["Catppuccin Latte (Light)"]="#eff1f5dd|#e6e9efcc|#4c4f69|#8839ef|#d20f39|8839efee|1e66f5ee|Catppuccin-Latte"
THEMES["Tokyo Night"]="#1a1b26dd|#24283bcc|#c0caf5|#bb9af7|#f7768e|bb9af7ee|7aa2f7ee|Tokyo-Night"
THEMES["Dracula"]="#282a36dd|#44475acc|#f8f8f2|#bd93f9|#ff5555|bd93f9ee|8be9fdee|Dracula"
THEMES["Rose Pine"]="#191724dd|#26233acc|#e0def4|#c4a7e7|#eb6f92|c4a7e7ee|31748fee|Rosé-Pine"

# --- 2. Rofi UI Selection ---
# If argument provided, use it. Otherwise open Rofi.
chosen="${1:-}"
if [ -z "$chosen" ]; then
    chosen=$(printf "%s\n" "${!THEMES[@]}" | sort | rofi -dmenu -i -p "🎨 Select Theme")
fi

[ -z "$chosen" ] && exit 0
[ -z "${THEMES[$chosen]:-}" ] && { echo "Theme not found"; exit 1; }

# Parse values
IFS='|' read -r bg bg_alt fg accent urgent b1 b2 kitty_theme <<< "${THEMES[$chosen]}"

# --- 3. Apply to Rofi ---
ROFI_CONF="$HOME/.config/rofi/config.rasi"
if [ -f "$ROFI_CONF" ]; then
    sed -i -E "s|(bg:[ \t]+)#[0-9a-fA-F]+;|\1$bg;|" "$ROFI_CONF"
    sed -i -E "s|(bg-alt:[ \t]+)#[0-9a-fA-F]+;|\1$bg_alt;|" "$ROFI_CONF"
    sed -i -E "s|(fg:[ \t]+)#[0-9a-fA-F]+;|\1$fg;|" "$ROFI_CONF"
    sed -i -E "s|(accent:[ \t]+)#[0-9a-fA-F]+;|\1$accent;|" "$ROFI_CONF"
    sed -i -E "s|(urgent:[ \t]+)#[0-9a-fA-F]+;|\1$urgent;|" "$ROFI_CONF"
fi

# --- 4. Apply to Hyprland ---
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    sed -i -E "s|(col.active_border = rgba)\([0-9a-fA-F]+\)( rgba)\([0-9a-fA-F]+\)( [0-9]+deg)|\1($b1)\2($b2)\3|" "$HYPR_CONF"
    sed -i -E "s|(col.inactive_border = rgba)\([0-9a-fA-F]+\)|\1(${bg_alt:1:6}aa)|" "$HYPR_CONF"
    # Note: Hyprland auto-reloads when config changes
fi

# --- 5. Apply to Waybar ---
WAYBAR_CSS="$HOME/.config/waybar/style.css"
if [ -f "$WAYBAR_CSS" ]; then
    # We look for standard hex colors in Waybar and replace them.
    # Assuming standard Mocha colors were used initially, we replace them globally.
    # To be safe, we replace specific class colors
    
    # Backgrounds
    sed -i -E "s|background-color: #[0-9a-fA-F]+;|background-color: ${bg:0:7};|g" "$WAYBAR_CSS"
    # Text
    sed -i -E "s|color: #[0-9a-fA-F]+;|color: ${fg:0:7};|g" "$WAYBAR_CSS"
    # Gradient text (assuming it uses standard hex matching)
    sed -i -E "s|#[0-9a-fA-F]{6} 0%, #[0-9a-fA-F]{6}|${accent:0:7} 0%, #${b2:0:6}|g" "$WAYBAR_CSS"
    
    # Soft reload waybar
    killall -SIGUSR2 waybar 2>/dev/null || true
fi

# --- 6. Apply to Kitty ---
# Find Kitty executable
if command -v kitty >/dev/null; then
    kitty +kitten themes --reload-in=all "$kitty_theme" 2>/dev/null || true
fi

# --- 7. Apply to Dunst ---
DUNST_CONF="$HOME/.config/dunst/dunstrc"
if [ -f "$DUNST_CONF" ]; then
    sed -i -E "s|background = \"#[0-9a-fA-F]+\"|background = \"${bg:0:7}ee\"|g" "$DUNST_CONF"
    sed -i -E "s|foreground = \"#[0-9a-fA-F]+\"|foreground = \"${fg:0:7}\"|g" "$DUNST_CONF"
    sed -i -E "s|frame_color = \"#[0-9a-fA-F]+\"|frame_color = \"${accent:0:7}\"|g" "$DUNST_CONF"
    sed -i -E "s|highlight = \"#[0-9a-fA-F]+\"|highlight = \"${accent:0:7}\"|g" "$DUNST_CONF"
    
    # Reload dunst
    killall dunst 2>/dev/null || true
    disown dunst &>/dev/null || true
fi

# --- 8. Notification ---
command -v notify-send >/dev/null && \
    notify-send -a "Theme Switcher" -i "preferences-desktop-theme" \
    "Theme Applied: $chosen" "Hyprland, Waybar, Rofi, and Kitty updated!"

echo "Theme changed to $chosen"
