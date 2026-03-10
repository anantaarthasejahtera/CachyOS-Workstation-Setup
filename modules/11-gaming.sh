#!/usr/bin/env bash
# Module 11: Gaming (Steam, PCSX2, Minecraft, Roblox)
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
skip_if_current
header "Gaming — Steam, Minecraft, PS2 Emulator"

# --- Steam ---
log "Installing Steam..."
install_pkg steam
# Enable Proton for all Steam games (for Far Cry 3, etc)
mkdir -p "$HOME/.steam/steam/config"
ok "Steam installed (CS2 = free, Far Cry 3 = buy on Steam)"

# --- MangoHud (FPS overlay) ---
log "Installing MangoHud (FPS overlay)..."
install_pkg mangohud lib32-mangohud
mkdir -p "$HOME/.config/MangoHud"
safe_config "$HOME/.config/MangoHud/MangoHud.conf"
cat > "$HOME/.config/MangoHud/MangoHud.conf" << 'MANGOEOF'
# — MangoHud — Catppuccin Style FPS Overlay —
legacy_layout=false
fps
frametime=0
gpu_stats
gpu_temp
gpu_power
cpu_stats
cpu_temp
cpu_power
cpu_mhz
ram
vram
fps_limit=60
position=top-left
round_corners=10
font_size=20
toggle_fps_limit=F1
toggle_hud=F12
# Catppuccin Mocha colors
background_color=1e1e2e
text_color=cdd6f4
gpu_color=89b4fa
cpu_color=cba6f7
frametime_color=a6e3a1
engine_color=f5c2e7
background_alpha=0.7
MANGOEOF
ok "MangoHud configured (F12 to toggle in any game)"

# --- Wine (for non-Steam games / Proton fallback) ---
log "Installing Wine..."
install_pkg wine-staging winetricks
ok "Wine installed"

# --- PrismLauncher (Minecraft) ---
log "Installing PrismLauncher (Minecraft)..."
install_pkg prismlauncher
ok "PrismLauncher installed (open & login with Mojang/Microsoft account)"

# --- PCSX2 (PS2 Emulator) ---
log "Installing PCSX2 (PS2 emulator) via Flatpak..."
# Arch removed PCSX2 from repos, flatpak is the official recommended way now
flatpak install -y flathub net.pcsx2.PCSX2 || warn "Failed to install PCSX2 flatpak"
# NOTE: Flatpak PCSX2 uses ~/.var/app/net.pcsx2.PCSX2/config/PCSX2/ — configure via the app GUI
ok "PCSX2 installed (configure graphics settings via the app)"

log "Gaming setup summary:"
log "  - CS2: Open Steam > install free"
log "  - Far Cry 3: Buy on Steam > enable Proton > play"
log "  - Minecraft: Open PrismLauncher > login > play"
log "  - PS2 (Black): Open PCSX2 > load your ISO > play"
log "  - FPS overlay: Press F12 in any game"
log "  - GameMode: Run games with 'gamemoderun ./game'"

ok "Gaming module ready"
mark_module_done

