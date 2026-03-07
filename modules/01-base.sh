#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Module 01: System Foundation & Hardware
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
source "$(dirname "$0")/00-common.sh"

header "System Foundation & Hardware Optimization"

log "Updating system..."
sudo pacman -Syu --noconfirm 2>&1 | tee -a "$LOGFILE"

log "Installing base development tools..."
install_pkg base-devel git curl wget unzip zip cmake ninja meson pkgconf

# --- Auto-detect GPU and install appropriate drivers ---
log "Detecting GPU..."
GPU_VENDOR=$(lspci | grep -i 'vga\|3d' | head -1)
log "Detected: $GPU_VENDOR"

if echo "$GPU_VENDOR" | grep -qi 'nvidia'; then
    log "Installing NVIDIA GPU drivers..."
    install_pkg nvidia-dkms nvidia-utils lib32-nvidia-utils \
        nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader \
        mesa lib32-mesa libva-nvidia-driver
    sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf 2>/dev/null || true
    sudo mkinitcpio -P 2>/dev/null || true
    ok "NVIDIA drivers installed (DRM KMS enabled)"
elif echo "$GPU_VENDOR" | grep -qi 'intel'; then
    log "Installing Intel GPU drivers..."
    install_pkg mesa lib32-mesa intel-media-driver vulkan-intel \
        lib32-vulkan-intel intel-gpu-tools libva-utils
    ok "Intel GPU drivers installed"
elif echo "$GPU_VENDOR" | grep -qi 'amd\|radeon'; then
    log "Installing AMD GPU drivers..."
    install_pkg mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
        libva-mesa-driver mesa-vdpau xf86-video-amdgpu
    ok "AMD GPU drivers installed"
else
    warn "Unknown GPU vendor. Installing generic mesa drivers..."
    install_pkg mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader
fi

# Ensure paru is available
if ! command -v paru &>/dev/null; then
    log "Installing paru (AUR helper)..."
    cd /tmp
    git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin && makepkg -si --noconfirm
    cd ~ && rm -rf /tmp/paru-bin
fi

# Optimize makepkg for all available threads
NPROC=$(nproc)
log "Optimizing makepkg.conf for $NPROC threads..."
sudo sed -i "s/^#MAKEFLAGS=.*/MAKEFLAGS=\"-j$NPROC\"/" /etc/makepkg.conf
sudo sed -i 's/^COMPRESSXZ=.*/COMPRESSXZ=(xz -c -z - --threads=0)/' /etc/makepkg.conf 2>/dev/null || true
sudo sed -i 's/^COMPRESSZST=.*/COMPRESSZST=(zstd -c -z -q - --threads=0)/' /etc/makepkg.conf 2>/dev/null || true

ok "System foundation ready"
