#!/usr/bin/env bash
# — Wallpaper Picker — Rofi + Hyprpaper —
# Scans ~/Pictures/Wallpapers and lets you pick one.

set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
HYPR_CONF="$HOME/.config/hypr/hyprpaper.conf"

# Ensure directory exists
mkdir -p "$WALLPAPER_DIR"

# Get list of images
files=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.avif" -o -name "*.bmp" \) -printf "%f\n" | sort)

if [ -z "$files" ]; then
    notify-send -a "Wallpaper Picker" -i "dialog-error" "Error" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Select wallpaper via Rofi
chosen=$(echo "$files" | rofi -dmenu -i -p "󰸉 Wallpapers" -config ~/.config/rofi/config.rasi)

[ -z "$chosen" ] && exit 0

full_path="$WALLPAPER_DIR/$chosen"

# Apply instantly via IPC
# Try IPC first, if it fails, restart hyprpaper with a dummy config
if ! hyprctl hyprpaper listloaded &>/dev/null; then
    echo "IPC failed or hyprpaper not responsive, restarting..."
    pkill hyprpaper || true
    # Create basic config to start
    cat > "$HYPR_CONF" << EOF
preload = $full_path
splash = false
ipc = on
EOF
    hyprpaper &
    sleep 1
fi

# Preload the new wallpaper
hyprctl hyprpaper preload "$full_path" 2>/dev/null || true

# Get all monitors and apply wallpaper to each
monitors=$(hyprctl monitors | grep "Monitor" | awk '{print $2}')

# Update config for persistence (one entry per monitor)
cat > "$HYPR_CONF" << EOF
preload = $full_path
splash = false
ipc = on
EOF

for mon in $monitors; do
    echo "wallpaper = $mon,$full_path" >> "$HYPR_CONF"
    # Apply via IPC for instant change
    hyprctl hyprpaper wallpaper "$mon,$full_path" 2>/dev/null || true
done

notify-send -a "Wallpaper Picker" -i "preferences-desktop-wallpaper" "Wallpaper Updated" "Applied: $chosen"
