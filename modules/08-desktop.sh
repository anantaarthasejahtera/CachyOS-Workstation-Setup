#!/usr/bin/env bash
# Module 08: Desktop Aesthetic (KDE + Catppuccin)
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
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

