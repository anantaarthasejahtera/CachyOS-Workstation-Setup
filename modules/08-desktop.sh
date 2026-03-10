#!/usr/bin/env bash
# Module 08: Desktop Aesthetic (KDE + Catppuccin)
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
skip_if_current
header "Desktop Aesthetic — Catppuccin Mocha Rice"

# --- Catppuccin Theme Suite (AUR) ---
log "Installing Catppuccin theme suite (KDE, GTK, Icons, Cursors, Kvantum, SDDM)..."
install_aur \
    catppuccin-kde-theme-mocha \
    papirus-folders-catppuccin \
    catppuccin-cursors-mocha \
    kvantum-theme-catppuccin-mocha \
    catppuccin-gtk-theme-mocha \
    sddm-theme-catppuccin-mocha \
    2>/dev/null || true

# --- Essential dependencies ---
install_pkg papirus-icon-theme kvantum

# --- Wallpapers (3-tier reliability) ---
# Ensures the user ALWAYS gets an aesthetic wallpaper on first boot.
# All sources are specifically chosen to match our Catppuccin Mocha theme.
# Tier 1: Clone repos with Catppuccin Mocha color-matched wallpapers
# Tier 2: Direct curl of specific Catppuccin Mocha wallpapers from raw GitHub
# Tier 3: Generate a Catppuccin Mocha gradient via ImageMagick (zero-net fallback)
log "Setting up aesthetic wallpapers..."
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WALLPAPER_DIR"

wallpapers_acquired=false

# --- Tier 1: Clone repos with Catppuccin-matched wallpapers ---
# NOTE: dharmx/walls is very large. We use shallow clones and pick a selection.
log "  Tier 1: Cloning Catppuccin wallpaper repositories..."
MAX_WALLPAPERS=15

for repo in \
    "https://github.com/orangci/walls-catppuccin-mocha.git" \
    "https://github.com/dharmx/walls.git"; do
    if [ "$wallpapers_acquired" = false ]; then
        log "    Cloning $(basename "$repo" .git)..."
        rm -rf /tmp/cachy-wallpapers-clone
        if git clone --depth=1 "$repo" /tmp/cachy-wallpapers-clone 2>/dev/null; then
            # Randomly select a few high-quality images to avoid disk bloat
            find /tmp/cachy-wallpapers-clone -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) \
                | shuf -n "$MAX_WALLPAPERS" | xargs -I {} cp {} "$WALLPAPER_DIR/" 2>/dev/null

            # Verify if images were copied
            img_count=$(find "$WALLPAPER_DIR" -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) 2>/dev/null | wc -l)
            if [ "$img_count" -gt 0 ]; then
                wallpapers_acquired=true
                ok "Acquired $img_count aesthetic wallpapers from: $(basename "$repo" .git)"
            fi
        fi
        rm -rf /tmp/cachy-wallpapers-clone
    fi
done

# --- Tier 2: Direct curl of Catppuccin Mocha wallpapers from raw GitHub ---
if [ "$wallpapers_acquired" = false ]; then
    log "  Tier 2: Downloading Catppuccin Mocha wallpapers via curl..."
    # These are from orangci/walls-catppuccin-mocha — guaranteed Catppuccin Mocha palette
    urls=(
        "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/master/dark-star.jpg"
        "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/master/eclipse.jpg"
        "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/master/droplets.png"
        "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/master/dragon.jpg"
        "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/refs/heads/master/day-forest-path.png"
        "https://w.wallhaven.cc/full/2y/wallhaven-2y16jm.png"
        "https://w.wallhaven.cc/full/ex/wallhaven-exj2yl.png"
    )
    for url in "${urls[@]}"; do
        fname="catppuccin-$(basename "$url")"
        curl -fsSL "$url" -o "$WALLPAPER_DIR/$fname" 2>/dev/null && wallpapers_acquired=true || true
    done
    if [ "$wallpapers_acquired" = true ]; then
        ok "Catppuccin Mocha wallpapers downloaded via curl"
    fi
fi

# --- Tier 3: Bundled wallpapers from repo (guaranteed, zero-network) ---
if [ "$wallpapers_acquired" = false ]; then
    log "  Tier 3: Copying bundled Catppuccin wallpapers..."
    ASSETS_WALLPAPER_DIR="$(dirname "$0")/../assets/wallpapers"
    if [ -d "$ASSETS_WALLPAPER_DIR" ]; then
        for wp in "$ASSETS_WALLPAPER_DIR"/*.png "$ASSETS_WALLPAPER_DIR"/*.jpg; do
            [ -f "$wp" ] || continue
            cp "$wp" "$WALLPAPER_DIR/" && wallpapers_acquired=true
        done
        [ "$wallpapers_acquired" = true ] && ok "Bundled Catppuccin wallpapers installed"
    fi
fi

# --- Tier 4: Generate Catppuccin Mocha gradient via ImageMagick (last resort) ---
if [ "$wallpapers_acquired" = false ]; then
    log "  Tier 4: Generating Catppuccin gradient wallpaper locally..."
    # Try with existing ImageMagick, or install it
    if ! generate_catppuccin_wallpaper "$WALLPAPER_DIR/catppuccin-mocha-gradient.png"; then
        install_pkg imagemagick 2>/dev/null || true
        generate_catppuccin_wallpaper "$WALLPAPER_DIR/catppuccin-mocha-gradient.png" || true
    fi
    if [ -f "$WALLPAPER_DIR/catppuccin-mocha-gradient.png" ]; then
        wallpapers_acquired=true
        ok "Generated Catppuccin Mocha gradient wallpaper (4K)"
    else
        warn "Could not generate wallpaper. Place images in ~/Pictures/Wallpapers/ manually."
    fi
fi

# --- Extra visual apps ---
install_pkg fastfetch cmatrix

ok "Desktop aesthetic configured"

# --- GRUB Catppuccin Theme (boot screen) ---
log "Installing GRUB Catppuccin theme..."
GRUB_THEME_DIR="/usr/share/grub/themes/catppuccin-mocha"
if [ ! -d "$GRUB_THEME_DIR" ]; then
    (
        cd /tmp || exit 1
        git clone --depth=1 https://github.com/catppuccin/grub.git catppuccin-grub 2>/dev/null || true
        if [ -d "catppuccin-grub/src/catppuccin-mocha-grub-theme" ]; then
            log "  Applying GRUB theme..."
            sudo mkdir -p "$GRUB_THEME_DIR"
            sudo cp -r catppuccin-grub/src/catppuccin-mocha-grub-theme/* "$GRUB_THEME_DIR/"
            sudo sed -i 's|^#\?GRUB_THEME=.*|GRUB_THEME="/usr/share/grub/themes/catppuccin-mocha/theme.txt"|' /etc/default/grub
            log "  Updating GRUB config (this may take a minute)..."
            sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            ok "GRUB Catppuccin Mocha theme installed"
        fi
        rm -rf /tmp/catppuccin-grub
    )
fi

# --- GTK/Qt Font Configuration ---
log "Configuring system fonts..."
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
safe_config "$HOME/.config/gtk-3.0/settings.ini"

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
safe_config "$HOME/.config/gtk-4.0/settings.ini"
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
mark_module_done

