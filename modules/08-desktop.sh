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

# --- Wallpapers (3-tier reliability) ---
# Ensures the user ALWAYS gets an aesthetic wallpaper on first boot.
# Tier 1: Clone community Catppuccin wallpaper repos
# Tier 2: Direct curl of individual known-good images
# Tier 3: Generate a Catppuccin Mocha gradient via ImageMagick (zero-net fallback)
log "Setting up aesthetic wallpapers..."
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WALLPAPER_DIR"

wallpapers_acquired=false

# --- Tier 1: Clone repos (multiple community sources) ---
log "  Tier 1: Trying community wallpaper repos..."
for repo in \
    "https://github.com/orangci/walls-catppuccin-mocha.git" \
    "https://github.com/zhichaoh/catppuccin-wallpapers.git" \
    "https://github.com/Gingeh/wallpapers.git"; do
    if [ "$wallpapers_acquired" = false ]; then
        rm -rf /tmp/cachy-wallpapers-clone
        if git clone --depth=1 "$repo" /tmp/cachy-wallpapers-clone 2>/dev/null; then
            # Copy only image files (skip READMEs, licenses, etc.)
            find /tmp/cachy-wallpapers-clone -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) \
                -exec cp {} "$WALLPAPER_DIR/" \; 2>/dev/null
            # Verify at least 1 image was copied
            if [ "$(find "$WALLPAPER_DIR" -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) 2>/dev/null | wc -l)" -gt 0 ]; then
                wallpapers_acquired=true
                ok "Wallpapers downloaded from: $(basename "$repo" .git)"
            fi
        fi
        rm -rf /tmp/cachy-wallpapers-clone
    fi
done

# --- Tier 2: Direct curl of individual images ---
if [ "$wallpapers_acquired" = false ]; then
    log "  Tier 2: Downloading individual wallpapers via curl..."
    # Known-good URLs from Catppuccin community (raw GitHub content)
    urls=(
        "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/main/01.png"
        "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/main/02.png"
        "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/main/03.png"
    )
    for url in "${urls[@]}"; do
        fname="catppuccin-$(basename "$url")"
        curl -fsSL "$url" -o "$WALLPAPER_DIR/$fname" 2>/dev/null && wallpapers_acquired=true || true
    done
    if [ "$wallpapers_acquired" = true ]; then
        ok "Individual wallpapers downloaded via curl"
    fi
fi

# --- Tier 3: Generate Catppuccin Mocha gradient (guaranteed, zero-net) ---
if [ "$wallpapers_acquired" = false ]; then
    log "  Tier 3: Generating Catppuccin gradient wallpaper locally..."
    # Use ImageMagick (convert/magick) which is commonly available
    if command -v magick &>/dev/null || command -v convert &>/dev/null; then
        magick_cmd="convert"
        command -v magick &>/dev/null && magick_cmd="magick"
        # Catppuccin Mocha gradient: Base (#1e1e2e) → Mauve (#cba6f7) → Blue (#89b4fa)
        $magick_cmd -size 3840x2160 \
            xc:'#1e1e2e' \
            \( -size 3840x2160 gradient:'#302d41'-'#1e1e2e' \) -compose overlay -composite \
            \( -size 200x200 xc:'#cba6f7' -blur 0x80 -resize 3840x2160! \) -compose softlight -composite \
            \( -size 200x200 xc:'#89b4fa' -gravity southeast -blur 0x60 -resize 3840x2160! \) -compose softlight -composite \
            "$WALLPAPER_DIR/catppuccin-mocha-gradient.png" 2>/dev/null
        wallpapers_acquired=true
        ok "Generated Catppuccin Mocha gradient wallpaper (4K)"
    else
        # Absolute last resort: install ImageMagick and generate
        install_pkg imagemagick 2>/dev/null || true
        if command -v magick &>/dev/null || command -v convert &>/dev/null; then
            magick_cmd="convert"
            command -v magick &>/dev/null && magick_cmd="magick"
            $magick_cmd -size 3840x2160 \
                xc:'#1e1e2e' \
                \( -size 3840x2160 gradient:'#302d41'-'#1e1e2e' \) -compose overlay -composite \
                \( -size 200x200 xc:'#cba6f7' -blur 0x80 -resize 3840x2160! \) -compose softlight -composite \
                "$WALLPAPER_DIR/catppuccin-mocha-gradient.png" 2>/dev/null
            wallpapers_acquired=true
            ok "Generated fallback gradient wallpaper"
        else
            warn "Could not generate wallpaper. Place images in ~/Pictures/Wallpapers/ manually."
        fi
    fi
fi

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

