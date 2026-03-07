#!/usr/bin/env bash
# Module 11: Gaming (Steam, PCSX2, Minecraft, Roblox)
source "$(dirname "$0")/00-common.sh"
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
log "Installing PCSX2 (PS2 emulator)..."
install_pkg pcsx2

# Auto-detect GPU class for optimal PCSX2 settings
GPU_INFO=$(lspci | grep -i 'vga\|3d' | head -1)
if echo "$GPU_INFO" | grep -qi 'nvidia\|radeon\|rx '; then
    # Discrete GPU: can handle higher settings
    PCSX2_UPSCALE=3        # 3x native (1080p)
    PCSX2_ANISO=4          # 4x anisotropic filtering
    PCSX2_RENDERER=12      # Hardware renderer
    GPU_CLASS="discrete"
    log "  Discrete GPU detected → PCSX2 set to 3x upscale + 4x AF"
else
    # Integrated GPU (Intel/AMD APU): conservative settings
    PCSX2_UPSCALE=1        # Native resolution
    PCSX2_ANISO=0          # No anisotropic filtering
    PCSX2_RENDERER=12      # Hardware renderer
    GPU_CLASS="integrated"
    log "  Integrated GPU detected → PCSX2 set to native resolution"
fi

mkdir -p "$HOME/.config/PCSX2/inis"
cat > "$HOME/.config/PCSX2/inis/GS.ini" << PCSX2GS
# --- PCSX2 Graphics --- Auto-configured for $GPU_CLASS GPU ---
Renderer = $PCSX2_RENDERER
upscale_multiplier = $PCSX2_UPSCALE
texture_filtering = 2
anisotropic_filtering = $PCSX2_ANISO
ManualHardwareRendererFixes = false
UserHacks_align_sprite = 0
UserHacks_merge_sprite = 0
LinearPresent = 1
Vsync = 1
PCSX2GS

cat > "$HOME/.config/PCSX2/inis/PCSX2.ini" << 'PCSX2INI'
# --- PCSX2 Core --- Performance optimizations ---
Framerate_Turbo = 200
Framerate_Slowmo = 50
Framerate_Nominal = 100
Enable_MTVU = true
Enable_Instant_VU1 = true
Enable_Fast_CDVD = true
PCSX2INI

ok "PCSX2 configured for $GPU_CLASS GPU (upscale: ${PCSX2_UPSCALE}x, AF: ${PCSX2_ANISO}x)"

log "Gaming setup summary:"
log "  - CS2: Open Steam > install free"
log "  - Far Cry 3: Buy on Steam > enable Proton > play"
log "  - Minecraft: Open PrismLauncher > login > play"
log "  - PS2 (Black): Open PCSX2 > load your ISO > play"
log "  - FPS overlay: Press F12 in any game"
log "  - GameMode: Run games with 'gamemoderun ./game'"

ok "Gaming module ready"

