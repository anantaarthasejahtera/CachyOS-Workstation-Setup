#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Aesthetic GUI App Store
#  Curated Flatpak & AUR installer via Rofi
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

# ─── Categories & Apps ───
# Format: "App Name|package_name|manager"

declare -A BROWSERS=(
    ["Google Chrome"]="google-chrome|aur"
    ["Brave Browser"]="com.brave.Browser|flatpak"
    ["Firefox"]="firefox|pacman"
    ["Microsoft Edge"]="microsoft-edge-stable-bin|aur"
)

declare -A DEV_TOOLS=(
    ["Visual Studio Code"]="visual-studio-code-bin|aur"
    ["JetBrains Toolbox"]="jetbrains-toolbox|aur"
    ["Postman"]="postman-bin|aur"
    ["DBeaver"]="dbeaver|pacman"
    ["Docker Desktop"]="docker-desktop|aur"
)

declare -A GAMING=(
    ["Heroic Games Launcher"]="com.heroicgameslauncher.hgl|flatpak"
    ["Lutris"]="lutris|pacman"
    ["Discord"]="com.discordapp.Discord|flatpak"
    ["OBS Studio"]="obs-studio|pacman"
    ["RetroArch"]="org.libretro.RetroArch|flatpak"
)

declare -A MEDIA=(
    ["Spotify"]="com.spotify.Client|flatpak"
    ["Figma (Linux)"]="figma-linux-bin|aur"
    ["GIMP"]="gimp|pacman"
    ["VLC Media Player"]="vlc|pacman"
    ["Krita"]="org.kde.krita|flatpak"
)

declare -A UTILS=(
    ["1Password"]="1password|aur"
    ["AnyDesk"]="anydesk-bin|aur"
    ["Zoom"]="zoom|aur"
    ["Flameshot"]="flameshot|pacman"
    ["Nextcloud Desktop"]="nextcloud-client|pacman"
)

# ─── Custom User Apps ───
# Load from ~/.config/app-store-custom.conf
# Format: CategoryName|AppName|package_name|manager
CUSTOM_CONF="$HOME/.config/app-store-custom.conf"
declare -A CUSTOM=()
if [ -f "$CUSTOM_CONF" ]; then
    while IFS='|' read -r _cat app_name pkg_name manager; do
        [[ "$_cat" =~ ^#.*$ ]] && continue  # Skip comments
        [ -z "$app_name" ] && continue       # Skip empty lines
        CUSTOM["$app_name"]="$pkg_name|$manager"
    done < "$CUSTOM_CONF"
fi

# ─── Main Logic ───

# 1. Select Category
# Build category list (add Custom only if user has custom apps)
category_list="🌐 Browsers\n💻 Development Tools\n🎮 Gaming & Chat\n🎨 Design & Media\n🛡️ Utilities"
[ ${#CUSTOM[@]} -gt 0 ] && category_list+="\n⭐ My Custom Apps"

category=$(echo -e "$category_list" | rofi -dmenu -i -p "🏪 App Store" -width 400)
[ -z "$category" ] && exit 0

# 2. Extract apps based on category
declare -n current_dict
case "$category" in
    *"Browsers"*) current_dict=BROWSERS ;;
    *"Development"*) current_dict=DEV_TOOLS ;;
    *"Gaming"*) current_dict=GAMING ;;
    *"Design"*) current_dict=MEDIA ;;
    *"Utilities"*) current_dict=UTILS ;;
    *"Custom"*) current_dict=CUSTOM ;;
    *) exit 0 ;;
esac

# 3. Select App
app_names=""
for app in "${!current_dict[@]}"; do
    # Get manager
    IFS='|' read -r pkg_name manager <<< "${current_dict[$app]}"
    app_names+="$app [$manager]\n"
done

selected_display=$(echo -e "$app_names" | rofi -dmenu -i -p "📦 Select App" -width 600)
[ -z "$selected_display" ] && exit 0

# Extract raw app name (e.g. "Google Chrome")
selected_app=$(echo "$selected_display" | sed 's/ \[.*\]//')

IFS='|' read -r pkg_name manager <<< "${current_dict[$selected_app]}"

# 4. Confirm and Install
confirm=$(echo -e "Yes, Install\nCancel" | rofi -dmenu -i -p "🚀 Install $selected_app via $manager?")
[ "$confirm" != "Yes, Install" ] && exit 0

# Execute installation in Kitty
case "$manager" in
    "pacman")
        cmd="sudo pacman -S --noconfirm $pkg_name"
        ;;
    "aur")
        cmd="paru -S --noconfirm $pkg_name"
        ;;
    "flatpak")
        cmd="flatpak install -y flathub $pkg_name"
        ;;
esac

kitty --title "Installing $selected_app" -e bash -c "
echo -e '\033[1;36m🏪 CachyOS App Store\033[0m'
echo 'Installing: $selected_app'
echo 'Command: $cmd'
echo '-----------------------------------'
$cmd
echo '-----------------------------------'
echo -e '\033[1;32m✅ Done!\033[0m Press Enter to close.'
read
"

# Send notification
command -v notify-send >/dev/null && \
    notify-send -a "App Store" -i "software-store" \
    "Installation Complete" "$selected_app has been installed."
