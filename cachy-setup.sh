#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  🚀 CachyOS One-Shot Setup Script — Advan WorkPro Edition          ║
# ║  Intel i5-1035G7 | 16GB RAM | Development + Aesthetic Workstation  ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
# Usage: chmod +x cachy-setup.sh && ./cachy-setup.sh
# Reboot after completion for all changes to take effect.

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────
GIT_NAME="Your Name"          # ← CHANGE THIS
GIT_EMAIL="you@example.com"   # ← CHANGE THIS
COLORSCHEME="catppuccin-mocha"
FONT_MONO="JetBrainsMono Nerd Font"
NODE_VERSION="lts"

# ─── Colors & Helpers ────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

LOGFILE="$HOME/cachy-setup.log"
STEP=0; TOTAL=14

log()  { echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $1" | tee -a "$LOGFILE"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1" | tee -a "$LOGFILE"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $1" | tee -a "$LOGFILE"; }
err()  { echo -e "${RED}  ✗${NC} $1" | tee -a "$LOGFILE"; }
header() {
    STEP=$((STEP + 1))
    echo "" | tee -a "$LOGFILE"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOGFILE"
    echo -e "${BOLD}${BLUE}  [$STEP/$TOTAL] $1${NC}" | tee -a "$LOGFILE"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOGFILE"
}

install_pkg() {
    # Install packages via pacman, skip if already installed
    local pkgs=("$@")
    local to_install=()
    for pkg in "${pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done
    if [ ${#to_install[@]} -gt 0 ]; then
        sudo pacman -S --noconfirm --needed "${to_install[@]}" 2>&1 | tee -a "$LOGFILE"
    fi
}

install_aur() {
    # Install packages via paru (AUR helper)
    local pkgs=("$@")
    local to_install=()
    for pkg in "${pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null && ! paru -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done
    if [ ${#to_install[@]} -gt 0 ]; then
        paru -S --noconfirm --needed "${to_install[@]}" 2>&1 | tee -a "$LOGFILE"
    fi
}

# ─── Pre-flight Check ────────────────────────────────────────────────
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║   🚀 CachyOS Setup — Advan WorkPro Edition  ║"
echo "  ║   Intel i5-1035G7 • 16GB RAM                ║"
echo "  ║   Theme: Catppuccin Mocha                    ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo "Log file: $LOGFILE"
echo ""

if [ "$EUID" -eq 0 ]; then
    err "Do NOT run this script as root. Run as your normal user."
    exit 1
fi

sleep 2

# =====================================================================
# MODULE 1: System Foundation
# =====================================================================
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
    # Enable DRM kernel mode setting for NVIDIA
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

# Ensure paru is available (CachyOS ships it, but just in case)
if ! command -v paru &>/dev/null; then
    log "Installing paru (AUR helper)..."
    cd /tmp
    git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin && makepkg -si --noconfirm
    cd ~ && rm -rf /tmp/paru-bin
fi

# Optimize makepkg for all available threads (auto-detect)
NPROC=$(nproc)
log "Optimizing makepkg.conf for $NPROC threads..."
sudo sed -i "s/^#MAKEFLAGS=.*/MAKEFLAGS=\"-j$NPROC\"/" /etc/makepkg.conf
sudo sed -i 's/^COMPRESSXZ=.*/COMPRESSXZ=(xz -c -z - --threads=0)/' /etc/makepkg.conf 2>/dev/null || true
sudo sed -i 's/^COMPRESSZST=.*/COMPRESSZST=(zstd -c -z -q - --threads=0)/' /etc/makepkg.conf 2>/dev/null || true

ok "System foundation ready"

# =====================================================================
# MODULE 2: Docker & Containers
# =====================================================================
header "Docker & Container Environment"

install_pkg docker docker-compose docker-buildx

sudo systemctl enable --now docker.service
sudo usermod -aG docker "$USER"

# lazydocker — TUI for docker
install_aur lazydocker

ok "Docker installed (group change takes effect after reboot)"

# =====================================================================
# MODULE 3: Development Environment
# =====================================================================
header "Development Environment"

# --- Git & GitHub ---
log "Setting up Git & GitHub CLI..."
install_pkg git git-delta github-cli
install_aur gitui

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true
git config --global delta.syntax-theme "Catppuccin Mocha"
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved default
git config --global pull.rebase true
git config --global push.autoSetupRemote true
git config --global rerere.enabled true

# --- Node.js via fnm ---
log "Installing fnm (Fast Node Manager)..."
install_aur fnm
eval "$(fnm env --use-on-cd)"
fnm install --lts
fnm default lts-latest
ok "Node.js $(node --version) installed"

# Enable corepack for pnpm
corepack enable
corepack prepare pnpm@latest --activate 2>/dev/null || true
ok "pnpm activated via corepack"

# --- Python via uv ---
log "Installing uv (Python manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh
ok "uv installed"

# --- Rust ---
log "Installing Rust via rustup..."
if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi
ok "Rust $(rustc --version | cut -d' ' -f2) installed"

# --- Go ---
install_pkg go
ok "Go installed"

# --- Editors ---
log "Installing editors..."
install_pkg neovim
# NOTE: Antigravity (VS Code fork) is installed in Module 9.
# No need for separate VS Code — saves ~400MB RAM + disk.

# --- CLI Power Tools ---
log "Installing CLI power tools..."
install_pkg ripgrep fd bat eza fzf zoxide jq yq tree \
    tokei bottom dust duf procs hyperfine wget aria2 \
    man-db man-pages openssh

ok "Development environment ready"

# =====================================================================
# MODULE 3B: Flutter & Android Development (No Android Studio)
# =====================================================================
header "Flutter & Android Development"

# --- JDK 17 (required by Gradle/Android) ---
log "Installing JDK 17..."
install_pkg jdk17-openjdk jdk17-openjdk-doc
sudo archlinux-java set java-17-openjdk 2>/dev/null || true
ok "JDK 17 set as default"

# --- Kotlin compiler ---
log "Installing Kotlin..."
install_pkg kotlin
ok "Kotlin installed"

# --- Gradle ---
log "Installing Gradle..."
install_pkg gradle
ok "Gradle installed"

# --- Android SDK CLI tools (lightweight, no Android Studio) ---
log "Installing Android SDK CLI tools..."
ANDROID_HOME="$HOME/Android/Sdk"
mkdir -p "$ANDROID_HOME/cmdline-tools"

# Download latest cmdline-tools
CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
    cd /tmp
    curl -fsSL -o cmdline-tools.zip "$CMDLINE_URL"
    unzip -q cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools/"
    mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
    rm cmdline-tools.zip
    cd ~
fi

# Add to PATH
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

# Accept licenses & install SDK components
yes | sdkmanager --licenses 2>/dev/null || true
sdkmanager --install \
    "platform-tools" \
    "build-tools;34.0.0" \
    "platforms;android-34" \
    "sources;android-34" \
    "emulator" \
    "system-images;android-34;google_apis;x86_64" \
    2>/dev/null || true
ok "Android SDK installed (API 34)"

# --- Create AVD (Android Virtual Device) ---
log "Creating Android emulator..."
avdmanager create avd -n "Pixel_7" -k "system-images;android-34;google_apis;x86_64" -d "pixel_7" --force 2>/dev/null || true
ok "Android emulator 'Pixel_7' created"

# --- Flutter SDK ---
log "Installing Flutter..."
FLUTTER_DIR="$HOME/.flutter-sdk"
if [ ! -d "$FLUTTER_DIR" ]; then
    git clone --depth=1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

# Pre-cache Flutter tools
flutter precache 2>/dev/null || true
flutter config --android-sdk "$ANDROID_HOME" 2>/dev/null || true
flutter config --no-analytics 2>/dev/null || true
dart --disable-analytics 2>/dev/null || true
ok "Flutter SDK installed"

# --- scrcpy (mirror Android device to screen) ---
log "Installing scrcpy (device mirror)..."
install_pkg scrcpy
ok "scrcpy installed (run: scrcpy, to mirror your phone)"

# --- ADB udev rules (USB debugging without root) ---
log "Setting up ADB udev rules..."
install_pkg android-udev
sudo usermod -aG adbusers "$USER" 2>/dev/null || true
ok "ADB udev rules configured"

log "Running flutter doctor..."
flutter doctor 2>&1 | tee -a "$LOGFILE" || true

ok "Flutter & Android development ready"

# MODULE 4: Shell & Terminal Aesthetic
# =====================================================================
header "Shell & Terminal Aesthetic"

# --- Zsh + Oh My Zsh ---
install_pkg zsh

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ] && \
    git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ] && \
    git clone https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"

# --- Starship Prompt ---
log "Installing Starship prompt..."
install_pkg starship

# --- Kitty Terminal ---
log "Installing Kitty terminal..."
install_pkg kitty

# --- Nerd Fonts ---
log "Installing Nerd Fonts..."
install_pkg ttf-jetbrains-mono-nerd ttf-firacode-nerd ttf-nerd-fonts-symbols-common
install_aur ttf-inter 2>/dev/null || true

ok "Shell & terminal aesthetic ready"

# =====================================================================
# MODULE 5: Desktop Aesthetic (KDE Plasma + Catppuccin)
# =====================================================================
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

# =====================================================================
# MODULE 6: Performance & Deep System Tuning
# =====================================================================
header "Performance & Deep System Tuning"

# --- Power management ---
# thermald only for Intel CPUs
if lscpu | grep -qi 'intel'; then
    install_pkg thermald powertop
    sudo systemctl enable --now thermald.service
    ok "Intel thermald enabled"
fi

# --- Earlyoom (prevent OOM freeze) ---
install_pkg earlyoom
sudo systemctl enable --now earlyoom.service

# --- GameMode (auto-boost CPU/GPU during gaming) ---
log "Installing GameMode..."
install_pkg gamemode lib32-gamemode
ok "GameMode installed (use: gamemoderun ./game)"

# --- PipeWire low-latency audio ---
log "Configuring PipeWire low-latency..."
mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
cat > "$HOME/.config/pipewire/pipewire.conf.d/99-lowlatency.conf" << 'PWEOF'
context.properties = {
    default.clock.rate          = 48000
    default.clock.quantum       = 512
    default.clock.min-quantum   = 32
    default.clock.max-quantum   = 2048
}
PWEOF
ok "PipeWire low-latency configured"

# --- Kernel tuning (sysctl) ---
log "Applying kernel performance tuning..."
sudo tee /etc/sysctl.d/99-performance.conf > /dev/null << 'SYSEOF'
# ─── Memory Management ─────────────────────────────────
# Reduce swap aggressiveness (16GB RAM = less swap needed)
vm.swappiness = 10
# Keep filesystem metadata cached longer
vm.vfs_cache_pressure = 50
# Dirty page writeback tuning (better for NVMe)
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# ─── Network Performance ───────────────────────────────
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1

# ─── Kernel Hardening + Performance ────────────────────
kernel.nmi_watchdog = 0
# Increase inotify watchers (for VS Code, Node.js file watching)
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
SYSEOF
sudo sysctl --system 2>/dev/null || true
ok "Kernel sysctl tuning applied"

# --- NVMe I/O scheduler optimization ---
log "Setting NVMe I/O scheduler..."
# 'none' is optimal for NVMe SSDs (no scheduling overhead needed)
for dev in /sys/block/nvme*/queue/scheduler; do
    [ -f "$dev" ] && echo 'none' | sudo tee "$dev" > /dev/null 2>&1 || true
done
# Make it persistent via udev rule
sudo tee /etc/udev/rules.d/60-ioscheduler.rules > /dev/null << 'IOEOF'
# NVMe: no scheduler (fastest)
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
# SATA SSD: mq-deadline
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# HDD: bfq
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
IOEOF
ok "I/O scheduler optimized (NVMe=none, SSD=mq-deadline, HDD=bfq)"

# --- Transparent Huge Pages ---
log "Setting transparent hugepages to madvise..."
echo 'madvise' | sudo tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null 2>&1 || true
# Persist via kernel parameter
sudo mkdir -p /etc/tmpfiles.d
echo 'w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise' | \
    sudo tee /etc/tmpfiles.d/thp.conf > /dev/null
ok "THP set to madvise (apps opt-in for huge pages)"

# --- Filesystem ---
sudo systemctl enable --now fstrim.timer

# --- Journal size limit ---
sudo journalctl --vacuum-size=256M 2>/dev/null || true
sudo mkdir -p /etc/systemd/journald.conf.d
echo -e "[Journal]\nSystemMaxUse=256M" | sudo tee /etc/systemd/journald.conf.d/size.conf >/dev/null

# --- Intel GuC/HuC firmware (Intel GPU only) ---
if lspci | grep -qi 'intel.*graphics\|intel.*iris'; then
    log "Enabling Intel GuC/HuC firmware..."
    sudo mkdir -p /etc/modprobe.d
    echo 'options i915 enable_guc=3' | sudo tee /etc/modprobe.d/i915.conf > /dev/null
    ok "Intel i915 GuC/HuC enabled (GPU hardware scheduling)"
fi

ok "Deep system tuning complete"

# =====================================================================
# MODULE 7: Security & Maintenance
# =====================================================================
header "Security & Maintenance"

install_pkg ufw timeshift

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw --force enable
sudo systemctl enable --now ufw.service

ok "Firewall & backup tools configured"

# --- SSH key auto-generate ---
log "Generating SSH key..."
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" -N "" -q
    eval "$(ssh-agent -s)" 2>/dev/null
    ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
    ok "SSH key generated (add to GitHub: cat ~/.ssh/id_ed25519.pub)"
else
    ok "SSH key already exists"
fi

# --- Cloudflare DNS (1.1.1.1 — faster + privacy) ---
log "Setting Cloudflare DNS..."
sudo mkdir -p /etc/systemd/resolved.conf.d
cat << 'DNSEOF' | sudo tee /etc/systemd/resolved.conf.d/dns.conf > /dev/null
[Resolve]
DNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
DNSOverTLS=yes
Domains=~.
DNSEOF
sudo systemctl restart systemd-resolved 2>/dev/null || true
ok "DNS set to Cloudflare 1.1.1.1 (encrypted)"

# --- Zram tuning ---
log "Optimizing Zram..."
if [ -f /sys/block/zram0/comp_algorithm ]; then
    # CachyOS already has zram, just optimize compression
    echo 'zstd' | sudo tee /sys/block/zram0/comp_algorithm > /dev/null 2>&1 || true
    ok "Zram compression set to zstd (best ratio)"
else
    install_pkg zram-generator
    sudo mkdir -p /etc/systemd
    cat << 'ZRAMEOF' | sudo tee /etc/systemd/zram-generator.conf > /dev/null
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
ZRAMEOF
    ok "Zram configured (50% of RAM, zstd compression)"
fi

# --- Weekly auto-cleanup (pacman cache + orphan packages) ---
log "Setting up weekly auto-cleanup..."
sudo mkdir -p /etc/systemd/system
cat << 'CLEANEOF' | sudo tee /etc/systemd/system/pacman-cleanup.service > /dev/null
[Unit]
Description=Clean pacman cache and orphan packages
[Service]
Type=oneshot
ExecStart=/usr/bin/paccache -rk 2
ExecStart=/bin/bash -c 'pacman -Qdtq | xargs -r sudo pacman -Rns --noconfirm 2>/dev/null || true'
CLEANEOF
cat << 'TIMEREOF' | sudo tee /etc/systemd/system/pacman-cleanup.timer > /dev/null
[Unit]
Description=Weekly pacman cache cleanup
[Timer]
OnCalendar=weekly
Persistent=true
[Install]
WantedBy=timers.target
TIMEREOF
sudo systemctl enable --now pacman-cleanup.timer 2>/dev/null || true
ok "Weekly auto-cleanup enabled (pacman cache + orphan removal)"

# --- Global .gitignore ---
log "Creating global .gitignore..."
cat > "$HOME/.gitignore_global" << 'GIEOF'
# OS files
.DS_Store
Thumbs.db
Desktop.ini
*~

# Editor files
.vscode/settings.json
.idea/
*.swp
*.swo
*~

# Dependencies
node_modules/
__pycache__/
*.pyc
.venv/
venv/
target/
build/
dist/

# Environment
.env
.env.local
.env.*.local

# Logs
*.log
npm-debug.log*

# Build artifacts
*.o
*.so
*.class
*.jar
GIEOF
git config --global core.excludesFile "$HOME/.gitignore_global"
ok "Global .gitignore configured"

# =====================================================================
# MODULE 8: Dotfiles & Configuration
# =====================================================================
header "Dotfiles & Configuration"

# --- Directory structure ---
log "Creating project directories..."
mkdir -p "$HOME/projects" "$HOME/scripts" "$HOME/docker" "$HOME/.config"

# --- Kitty config (Catppuccin Mocha) ---
log "Writing Kitty config..."
mkdir -p "$HOME/.config/kitty"
cat > "$HOME/.config/kitty/kitty.conf" << 'KITTYEOF'
# ─── Kitty — Catppuccin Mocha ────────────────────────────
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        12.0

# Window
window_padding_width     12
background_opacity       0.92
dynamic_background_opacity yes
confirm_os_window_close  0
hide_window_decorations  no
remember_window_size     yes

# Cursor
cursor_shape             beam
cursor_beam_thickness    1.5
cursor_blink_interval    0.5

# Scrollback
scrollback_lines         10000

# Bell
enable_audio_bell        no

# Tab bar
tab_bar_style            powerline
tab_powerline_style      slanted
active_tab_font_style    bold

# ─── Catppuccin Mocha Colors ─────────────────────────────
# The basic 16 colors
foreground              #CDD6F4
background              #1E1E2E
selection_foreground     #1E1E2E
selection_background     #F5E0DC
cursor                  #F5E0DC
cursor_text_color       #1E1E2E
url_color               #F5E0DC
active_border_color     #B4BEFE
inactive_border_color   #6C7086
bell_border_color       #F9E2AF
active_tab_foreground   #11111B
active_tab_background   #CBA6F7
inactive_tab_foreground #CDD6F4
inactive_tab_background #181825
tab_bar_background      #11111B

# Normal
color0  #45475A
color1  #F38BA8
color2  #A6E3A1
color3  #F9E2AF
color4  #89B4FA
color5  #F5C2E7
color6  #94E2D5
color7  #BAC2DE

# Bright
color8  #585B70
color9  #F38BA8
color10 #A6E3A1
color11 #F9E2AF
color12 #89B4FA
color13 #F5C2E7
color14 #94E2D5
color15 #A6ADC8

mark1_foreground #1E1E2E
mark1_background #B4BEFE
mark2_foreground #1E1E2E
mark2_background #CBA6F7
mark3_foreground #1E1E2E
mark3_background #74C7EC
KITTYEOF
ok "Kitty config written"

# --- Starship config ---
log "Writing Starship config..."
mkdir -p "$HOME/.config"
cat > "$HOME/.config/starship.toml" << 'STAREOF'
# ─── Starship — Catppuccin Mocha ─────────────────────────
palette = "catppuccin_mocha"

format = """
[░▒▓](#89B4FA)\
$os\
$username\
[](bg:#CBA6F7 fg:#89B4FA)\
$directory\
[](fg:#CBA6F7 bg:#F5C2E7)\
$git_branch\
$git_status\
[](fg:#F5C2E7 bg:#F38BA8)\
$nodejs\
$python\
$rust\
$golang\
$java\
$kotlin\
$dart\
$docker_context\
[](fg:#F38BA8 bg:#F9E2AF)\
$time\
[ ](fg:#F9E2AF)\
$line_break\
$character"""

[os]
disabled = false
style = "bg:#89B4FA fg:#1E1E2E"
[os.symbols]
Arch = "󰣇 "
Linux = " "

[username]
show_always = true
style_user = "bg:#89B4FA fg:#1E1E2E"
style_root = "bg:#89B4FA fg:#1E1E2E"
format = '[$user ]($style)'
disabled = false

[directory]
style = "bg:#CBA6F7 fg:#1E1E2E"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = ""
style = "bg:#F5C2E7 fg:#1E1E2E"
format = '[ $symbol $branch ]($style)'

[git_status]
style = "bg:#F5C2E7 fg:#1E1E2E"
format = '[$all_status$ahead_behind ]($style)'

[nodejs]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[python]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[rust]
symbol = "🦀"
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[golang]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[docker_context]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol $context ]($style)'

[java]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[kotlin]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[dart]
symbol = ""
style = "bg:#F38BA8 fg:#1E1E2E"
format = '[ $symbol ($version) ]($style)'

[time]
disabled = false
time_format = "%R"
style = "bg:#F9E2AF fg:#1E1E2E"
format = '[ 󰥔 $time ]($style)'

[character]
success_symbol = '[❯](bold #A6E3A1)'
error_symbol = '[❯](bold #F38BA8)'

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
subtext1 = "#bac2de"
subtext0 = "#a6adc8"
overlay2 = "#9399b2"
overlay1 = "#7f849c"
overlay0 = "#6c7086"
surface2 = "#585b70"
surface1 = "#45475a"
surface0 = "#313244"
base = "#1e1e2e"
mantle = "#181825"
crust = "#11111b"
STAREOF
ok "Starship config written"

# --- Zshrc ---
log "Writing .zshrc..."
cat > "$HOME/.zshrc" << 'ZSHEOF'
# ─── CachyOS Zsh Config — Aesthetic + Productive ─────────
export ZSH="$HOME/.oh-my-zsh"

# Plugins
plugins=(
    git
    docker
    docker-compose
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    fzf-tab
    sudo
    command-not-found
    colored-man-pages
)

source $ZSH/oh-my-zsh.sh

# ─── Starship Prompt ─────────────────────────────────────
eval "$(starship init zsh)"

# ─── Tool Initialization ─────────────────────────────────
eval "$(fnm env --use-on-cd)"
eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"      # auto-load .envrc per project

# Cargo/Rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# uv (Python)
export PATH="$HOME/.local/bin:$PATH"

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Antigravity
export PATH="$HOME/.local/share/antigravity/bin:$PATH"

# Flutter & Android SDK
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
export PATH="$HOME/.flutter-sdk/bin:$PATH"
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
export CHROME_EXECUTABLE="$(which zen-browser 2>/dev/null || which firefox 2>/dev/null || echo '')"

# ─── Modern Aliases ──────────────────────────────────────
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --icons --level=2'
alias la='eza -a --icons --group-directories-first'
alias cat='bat --style=auto'
alias grep='rg'
alias find='fd'
alias top='btm'
alias du='dust'
alias df='duf'
alias ps='procs'
alias cd='z'
alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -pv'

# Git aliases
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias ga='git add'
alias gco='git checkout'
alias gb='git branch'
alias gpl='git pull'

# System aliases
alias update='sudo pacman -Syu && flatpak update -y && rustup update 2>/dev/null; echo "✅ System updated"'
alias cleanup='sudo pacman -Sc --noconfirm && pacman -Qdtq | xargs -r sudo pacman -Rns --noconfirm 2>/dev/null; echo "✅ Cleanup done"'
alias ff='fastfetch'
alias keys='cat ~/.config/hypr/cheatsheet.txt 2>/dev/null || echo "Hyprland cheatsheet not found"'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me && echo ""'
alias weather='curl -s wttr.in/?format=3'
alias record='wf-recorder -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4'
alias clip='wf-recorder -g "$(slurp)" -f ~/Videos/clip-$(date +%Y%m%d-%H%M%S).mp4'
alias screenshot='grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png'

# Docker aliases
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlog='docker logs -f'
alias dex='docker exec -it'
alias lzd='lazydocker'

# Tmux
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux list-sessions'
alias tk='tmux kill-session -t'

# System
alias update='sudo pacman -Syu && paru -Sua'
alias cleanup='sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null; paru -Sc --noconfirm'
alias ff='fastfetch'
alias keys='cat ~/.config/hypr/cheatsheet.txt 2>/dev/null || echo "Hyprland not configured"'

# ─── FZF Config ──────────────────────────────────────────
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --border rounded --margin 1 --padding 1"

# ─── Greeting ────────────────────────────────────────────
fastfetch 2>/dev/null || true
ZSHEOF
ok ".zshrc written"

# --- Set zsh as default shell ---
log "Setting zsh as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
fi

# --- bat theme ---
log "Configuring bat theme..."
mkdir -p "$HOME/.config/bat"
echo '--theme="Catppuccin Mocha"' > "$HOME/.config/bat/config"

# --- btm (bottom) config ---
mkdir -p "$HOME/.config/bottom"
cat > "$HOME/.config/bottom/bottom.toml" << 'BTMEOF'
[flags]
color = "gruvbox"
dot_marker = true
group_processes = true
hide_table_gap = true
rate = "500ms"
BTMEOF

# --- fastfetch config ---
mkdir -p "$HOME/.config/fastfetch"
cat > "$HOME/.config/fastfetch/config.jsonc" << 'FFEOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "display": { "separator": " → " },
    "modules": [
        "title", "separator",
        "os", "host", "kernel",
        "uptime", "packages",
        "shell", "de", "wm",
        "terminal", "terminalfont",
        "cpu", "gpu", "memory",
        "swap", "disk",
        "localip", "battery",
        "separator", "colors"
    ]
}
FFEOF

# --- Antigravity / VS Code Catppuccin Settings ---
# Antigravity is a VS Code fork, uses same config path
log "Configuring Antigravity editor aesthetic..."
VSCODE_DIR="$HOME/.config/Code/User"
mkdir -p "$VSCODE_DIR"
cat > "$VSCODE_DIR/settings.json" << 'VSCEOF'
{
    "workbench.colorTheme": "Catppuccin Mocha",
    "workbench.iconTheme": "catppuccin-mocha",
    "workbench.productIconTheme": "catppuccin-mocha",
    "editor.fontFamily": "'JetBrainsMono Nerd Font', 'JetBrains Mono', monospace",
    "editor.fontSize": 14,
    "editor.fontLigatures": true,
    "editor.lineHeight": 1.6,
    "editor.cursorBlinking": "smooth",
    "editor.cursorSmoothCaretAnimation": "on",
    "editor.smoothScrolling": true,
    "editor.minimap.enabled": false,
    "editor.renderWhitespace": "boundary",
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": true,
    "editor.stickyScroll.enabled": true,
    "terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font'",
    "terminal.integrated.fontSize": 13,
    "terminal.integrated.cursorStyle": "line",
    "terminal.integrated.defaultProfile.linux": "zsh",
    "window.titleBarStyle": "custom",
    "window.menuBarVisibility": "toggle",
    "workbench.list.smoothScrolling": true,
    "workbench.tree.indent": 16,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000
}
VSCEOF

# Install Catppuccin extensions (will run on first VS Code launch)
cat > "$VSCODE_DIR/extensions.json" << 'VSCEXTEOF'
{
    "recommendations": [
        "catppuccin.catppuccin-vsc",
        "catppuccin.catppuccin-vsc-icons",
        "catppuccin.catppuccin-vsc-pack"
    ]
}
VSCEXTEOF
ok "VS Code Catppuccin configured"

# --- Neovim + Catppuccin (lazy.nvim) ---
log "Configuring Neovim with Catppuccin..."
NVIM_DIR="$HOME/.config/nvim"
mkdir -p "$NVIM_DIR/lua/plugins"

# Init lazy.nvim
cat > "$NVIM_DIR/init.lua" << 'NVIMINIT'
-- ─── Neovim — Catppuccin Mocha ──────────────────────────
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({ "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- Catppuccin colorscheme
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
                transparent_background = true,
                integrations = {
                    treesitter = true,
                    telescope = { enabled = true },
                    which_key = true,
                    indent_blankline = { enabled = true },
                    mini = { enabled = true },
                },
            })
            vim.cmd.colorscheme("catppuccin")
        end,
    },
    -- File explorer
    { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" },
      config = function() require("nvim-tree").setup() end },
    -- Fuzzy finder
    { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    -- Statusline
    { "nvim-lualine/lualine.nvim", config = function()
        require("lualine").setup({ options = { theme = "catppuccin" } })
    end },
    -- Treesitter
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    -- Which-key (keybinding helper)
    { "folke/which-key.nvim", config = function() require("which-key").setup() end },
    -- Indent guides
    { "lukas-reineke/indent-blankline.nvim", main = "ibl",
      config = function() require("ibl").setup() end },
    -- Auto pairs
    { "windwp/nvim-autopairs", config = function() require("nvim-autopairs").setup() end },
    -- Git signs
    { "lewis6991/gitsigns.nvim", config = function() require("gitsigns").setup() end },
})
NVIMINIT
ok "Neovim + lazy.nvim + Catppuccin configured"

ok "All dotfiles written"

# =====================================================================
# MODULE 9: Antigravity (Google AI Coding Agent)
# =====================================================================
header "Antigravity — AI Coding Agent"

# CachyOS is Arch-based, no deb/rpm. Install from source tarball.
log "Installing Antigravity from source tarball..."
AG_TMP="/tmp/antigravity-install"
mkdir -p "$AG_TMP"

# Download latest source tarball
AG_TARBALL_URL="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-debian/pool/antigravity_latest.tar.gz"
if curl -fsSL -o "$AG_TMP/antigravity.tar.gz" "$AG_TARBALL_URL" 2>/dev/null; then
    cd "$AG_TMP"
    tar xzf antigravity.tar.gz 2>/dev/null || true
    # Try to find and install the binary
    if [ -f "$AG_TMP/usr/bin/antigravity" ]; then
        sudo cp "$AG_TMP/usr/bin/antigravity" /usr/local/bin/
        sudo chmod +x /usr/local/bin/antigravity
        ok "Antigravity installed from tarball"
    elif [ -f "$AG_TMP/antigravity" ]; then
        sudo cp "$AG_TMP/antigravity" /usr/local/bin/
        sudo chmod +x /usr/local/bin/antigravity
        ok "Antigravity installed from tarball"
    else
        warn "Antigravity tarball structure unknown. Trying npm..."
        npm install -g @anthropic-ai/claude-code 2>/dev/null || \
        npm install -g @anthropic/antigravity 2>/dev/null || \
        warn "Antigravity needs manual install. Download from: https://developers.google.com/gemini"
    fi
else
    warn "Could not download Antigravity tarball. Trying alternative..."
    # Attempt AUR (community might have it)
    install_aur antigravity-bin 2>/dev/null || \
    warn "Antigravity needs manual install after reboot. Check official site."
fi
rm -rf "$AG_TMP"
cd ~

ok "Antigravity module done"

# --- Ollama (Local AI / LLM) ---
log "Installing Ollama (run AI models locally)..."
curl -fsSL https://ollama.com/install.sh | sh 2>/dev/null || install_aur ollama-bin 2>/dev/null || true
# Pull a lightweight model suitable for 16GB RAM
if command -v ollama &>/dev/null; then
    sudo systemctl enable --now ollama.service 2>/dev/null || true
    # Pull 3 optimal models for 16GB RAM in background
    log "Pulling AI models in background (this may take a while)..."
    log "  1. qwen3:30b-a3b   → MoE reasoning beast (debat, strategi, filosofi)"
    log "  2. deepseek-r1:7b  → Reasoning & math specialist"
    log "  3. qwen2.5-coder:7b → Coding specialist (setara GPT-4o)"
    (
        ollama pull qwen2.5-coder:7b 2>/dev/null
        ollama pull deepseek-r1:7b 2>/dev/null
        ollama pull qwen3:30b-a3b 2>/dev/null
    ) &
    ok "Ollama installed (3 models downloading in background)"
    log "  Quick start: ollama run qwen3:30b-a3b"
else
    warn "Ollama install failed. Try manually: curl -fsSL https://ollama.com/install.sh | sh"
fi

# =====================================================================
# MODULE 10: Hyprland (Optional Tiling WM)
# =====================================================================
header "Hyprland — Tiling Window Manager + Cheatsheet"

log "Installing Hyprland ecosystem..."
# Hyprland core + CachyOS-optimized components
install_pkg hyprland hyprpaper hyprlock hypridle xdg-desktop-portal-hyprland

# Supporting apps for Hyprland
install_pkg waybar rofi-wayland dunst swww grim slurp wl-clipboard \
    cliphist brightnessctl playerctl polkit-kde-agent

# File manager & app launcher
install_pkg thunar nwg-look

ok "Hyprland packages installed"

# --- Hyprland keybinding cheatsheet ---
log "Creating Hyprland cheatsheet helper..."
mkdir -p "$HOME/.config/hypr"
cat > "$HOME/.config/hypr/cheatsheet.txt" << 'CHEATEOF'
╔═══════════════════════════════════════════════════════════════╗
║  🎮 HYPRLAND KEYBINDING CHEATSHEET — CachyOS Edition        ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  ── ESSENTIALS ──────────────────────────────────────────────  ║
║  Super + Enter          → Open Kitty Terminal                 ║
║  Super + Q              → Close focused window                ║
║  Super + D              → App Launcher (rofi)                 ║
║  Super + X              → Nexus Command Center                ║
║  Super + M              → Exit Hyprland                       ║
║  Super + V              → Clipboard history                   ║
║  Super + L              → Lock screen                         ║
║                                                               ║
║  ── WINDOW MANAGEMENT ───────────────────────────────────────  ║
║  Super + Arrow Keys     → Move focus between windows          ║
║  Super + Shift + Arrows → Move window position                ║
║  Super + F              → Toggle fullscreen                   ║
║  Super + Space          → Toggle floating mode                ║
║  Super + P              → Toggle pseudo-tiling                ║
║  Super + J              → Toggle split direction              ║
║  Super + Mouse Drag     → Move/resize floating window         ║
║                                                               ║
║  ── WORKSPACES ──────────────────────────────────────────────  ║
║  Super + 1-9            → Switch to workspace 1-9             ║
║  Super + Shift + 1-9    → Move window to workspace 1-9        ║
║  Super + Scroll          → Cycle through workspaces           ║
║  Super + Tab            → Overview (if plugin enabled)        ║
║                                                               ║
║  ── SCREENSHOTS ─────────────────────────────────────────────  ║
║  Print                  → Screenshot full screen              ║
║  Super + Shift + S      → Screenshot region (select area)     ║
║                                                               ║
║  ── MEDIA ───────────────────────────────────────────────────  ║
║  Volume Up/Down/Mute    → Audio control                       ║
║  Brightness Up/Down     → Screen brightness                   ║
║                                                               ║
║  ── HELPER ──────────────────────────────────────────────────  ║
║  Super + /              → Show this cheatsheet                ║
║  Type 'keys' in term    → Also shows this cheatsheet          ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
CHEATEOF

# --- Helper script to display cheatsheet via rofi ---
cat > "$HOME/.config/hypr/show-keys.sh" << 'KEYSEOF'
#!/usr/bin/env bash
# Display Hyprland keybinding cheatsheet in a floating kitty window
kitty --class floating-helper \
      --override background_opacity=0.95 \
      --override initial_window_width=68c \
      --override initial_window_height=40c \
      -e sh -c "cat ~/.config/hypr/cheatsheet.txt; read -n1 -s -r -p ''"
KEYSEOF
chmod +x "$HOME/.config/hypr/show-keys.sh"

# --- Hyprland config ---
cat > "$HOME/.config/hypr/hyprland.conf" << 'HYPREOF'
# ─── Hyprland Config — CachyOS Advan WorkPro ─────────────
# Monitor (auto-detect)
monitor=,preferred,auto,1

# Autostart
exec-once = waybar
exec-once = dunst
exec-once = hyprpaper
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = hypridle

# ─── Environment ─────────────────────────────────────────
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,catppuccin-mocha-dark-cursors
env = QT_QPA_PLATFORMTHEME,qt6ct

# ─── Input ───────────────────────────────────────────────
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
        tap-to-click = true
        drag_lock = true
    }
    sensitivity = 0
}

# ─── Appearance — Catppuccin Mocha ───────────────────────
general {
    gaps_in = 4
    gaps_out = 8
    border_size = 2
    col.active_border = rgba(cba6f7ee) rgba(89b4faee) 45deg
    col.inactive_border = rgba(585b70aa)
    layout = dwindle
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 6
        passes = 3
        new_optimizations = true
        vibrancy = 0.17
    }
    shadow {
        enabled = true
        range = 15
        render_power = 3
        color = rgba(1a1a2eee)
    }
}

animations {
    enabled = true
    bezier = smooth, 0.05, 0.9, 0.1, 1.05
    bezier = wind, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 5, smooth
    animation = windowsOut, 1, 5, smooth, popin 80%
    animation = border, 1, 8, default
    animation = borderangle, 1, 6, default
    animation = fade, 1, 5, smooth
    animation = workspaces, 1, 4, wind, slide
}

dwindle {
    pseudotile = true
    preserve_split = true
}

gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
}

# ─── Window Rules ────────────────────────────────────────
windowrulev2 = float, class:^(floating-helper)$
windowrulev2 = center, class:^(floating-helper)$
windowrulev2 = size 640 480, class:^(floating-helper)$
windowrulev2 = float, class:^(pavucontrol)$
windowrulev2 = float, class:^(blueman-manager)$
windowrulev2 = float, title:^(File Operation Progress)$
windowrulev2 = opacity 0.92 0.85, class:^(kitty)$
windowrulev2 = opacity 0.92 0.85, class:^(Code)$

# ─── Keybindings ─────────────────────────────────────────
$mainMod = SUPER

bind = $mainMod, Return, exec, kitty
bind = $mainMod, Q, killactive
bind = $mainMod, M, exit
bind = $mainMod, E, exec, thunar
bind = $mainMod, D, exec, rofi -show drun -show-icons
bind = $mainMod, X, exec, ~/.local/bin/nexus
bind = $mainMod, F, fullscreen
bind = $mainMod, Space, togglefloating
bind = $mainMod, P, pseudo
bind = $mainMod, J, togglesplit
bind = $mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
bind = $mainMod, L, exec, hyprlock
bind = $mainMod, slash, exec, ~/.config/hypr/show-keys.sh

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Move windows
bind = $mainMod SHIFT, left, movewindow, l
bind = $mainMod SHIFT, right, movewindow, r
bind = $mainMod SHIFT, up, movewindow, u
bind = $mainMod SHIFT, down, movewindow, d

# Workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9

# Move to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9

# Scroll workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Mouse binds
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Screenshots
bind = , Print, exec, grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png

# Media keys
bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindl = , XF86AudioPlay, exec, playerctl play-pause
bindl = , XF86AudioNext, exec, playerctl next
bindl = , XF86AudioPrev, exec, playerctl previous
bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
HYPREOF

# --- Screenshot directory ---
mkdir -p "$HOME/Pictures/Screenshots"

ok "Hyprland configured with cheatsheet helper (Super + / to view)"

# --- Rofi Catppuccin Theme ---
log "Writing Rofi Catppuccin theme..."
mkdir -p "$HOME/.config/rofi"
cat > "$HOME/.config/rofi/config.rasi" << 'ROFIEOF'
/* ─── Rofi — Catppuccin Mocha Glass ─────────────────────── */
configuration {
    modi: "drun,run,window,filebrowser";
    show-icons: true;
    icon-theme: "Papirus-Dark";
    font: "Inter 11";
    display-drun: "  Apps";
    display-run: "  Run";
    display-window: "  Windows";
    display-filebrowser: "  Files";
    drun-display-format: "{name}";
}

* {
    bg:       #1e1e2edd;
    bg-alt:   #313244cc;
    fg:       #cdd6f4;
    sel:      #cba6f744;
    accent:   #cba6f7;
    urgent:   #f38ba8;
    border-r: 14px;
}

window {
    width: 600px;
    transparency: "real";
    background-color: @bg;
    border: 2px solid;
    border-color: @accent;
    border-radius: @border-r;
    padding: 20px;
}

inputbar {
    children: [prompt, entry];
    background-color: @bg-alt;
    border-radius: 10px;
    padding: 10px 16px;
    spacing: 10px;
    margin: 0 0 16px 0;
}

prompt {
    background-color: transparent;
    text-color: @accent;
    font: "JetBrainsMono Nerd Font 12";
}

entry {
    background-color: transparent;
    text-color: @fg;
    placeholder: "Search...";
    placeholder-color: #6c7086;
}

listview {
    lines: 7;
    columns: 1;
    background-color: transparent;
    spacing: 4px;
    fixed-height: true;
}

element {
    background-color: transparent;
    text-color: @fg;
    padding: 8px 12px;
    border-radius: 8px;
}

element selected {
    background-color: @sel;
    text-color: @accent;
}

element-icon {
    size: 24px;
    background-color: transparent;
    margin: 0 10px 0 0;
}

element-text {
    background-color: transparent;
    text-color: inherit;
    vertical-align: 0.5;
}
ROFIEOF
ok "Rofi Catppuccin glass theme written"

# --- Dunst Catppuccin Notifications ---
log "Writing Dunst notification config..."
mkdir -p "$HOME/.config/dunst"
cat > "$HOME/.config/dunst/dunstrc" << 'DUNSTEOF'
# ─── Dunst — Catppuccin Mocha ────────────────────────────
[global]
    monitor = 0
    follow = mouse
    width = 350
    height = 150
    origin = top-right
    offset = 12x12
    progress_bar = true
    progress_bar_height = 10
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    indicate_hidden = yes
    shrink = no
    separator_height = 2
    padding = 16
    horizontal_padding = 16
    text_icon_padding = 16
    frame_width = 2
    sort = yes
    idle_threshold = 120
    font = Inter 10
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    word_wrap = yes
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    min_icon_size = 32
    max_icon_size = 64
    icon_theme = Papirus-Dark
    enable_recursive_icon_lookup = true
    corner_radius = 12
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[urgency_low]
    background = "#1e1e2eee"
    foreground = "#cdd6f4"
    frame_color = "#89b4fa"
    highlight = "#89b4fa"
    timeout = 5

[urgency_normal]
    background = "#1e1e2eee"
    foreground = "#cdd6f4"
    frame_color = "#cba6f7"
    highlight = "#cba6f7"
    timeout = 10

[urgency_critical]
    background = "#1e1e2eee"
    foreground = "#cdd6f4"
    frame_color = "#f38ba8"
    highlight = "#f38ba8"
    timeout = 0
DUNSTEOF
ok "Dunst Catppuccin notifications configured"

# --- Hyprlock (Aesthetic Lock Screen) ---
log "Writing Hyprlock config..."
cat > "$HOME/.config/hypr/hyprlock.conf" << 'LOCKEOF'
# ─── Hyprlock — Catppuccin Mocha Lock Screen ────────────
background {
    monitor =
    path = screenshot
    blur_passes = 4
    blur_size = 6
    noise = 0.015
    contrast = 0.9
    brightness = 0.6
    vibrancy = 0.17
}

input-field {
    monitor =
    size = 280, 50
    outline_thickness = 2
    dots_size = 0.25
    dots_spacing = 0.3
    dots_center = true
    dots_rounding = -1
    outer_color = rgba(203, 166, 247, 0.6)
    inner_color = rgba(30, 30, 46, 0.85)
    font_color = rgb(205, 214, 244)
    fade_on_empty = true
    fade_timeout = 2000
    placeholder_text = <span foreground="##6c7086">  Enter Password...</span>
    hide_input = false
    rounding = 14
    check_color = rgba(166, 227, 161, 0.6)
    fail_color = rgba(243, 139, 168, 0.6)
    fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
    capslock_color = rgba(249, 226, 175, 0.6)
    position = 0, -130
    halign = center
    valign = center
}

# Clock
label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%H:%M")"
    color = rgba(205, 214, 244, 0.9)
    font_size = 90
    font_family = JetBrainsMono Nerd Font
    position = 0, 60
    halign = center
    valign = center
}

# Date
label {
    monitor =
    text = cmd[update:60000] echo "$(date +"%A, %d %B")"
    color = rgba(186, 194, 222, 0.7)
    font_size = 18
    font_family = Inter
    position = 0, -20
    halign = center
    valign = center
}

# Greeting
label {
    monitor =
    text = Hi, $USER
    color = rgba(203, 166, 247, 0.8)
    font_size = 14
    font_family = Inter
    position = 0, -70
    halign = center
    valign = center
}
LOCKEOF
ok "Hyprlock aesthetic lock screen configured"

# --- Hyprpaper (wallpaper daemon) ---
log "Writing Hyprpaper config..."
WALL_DEFAULT=$(find "$HOME/Pictures/Wallpapers" -type f \( -name '*.png' -o -name '*.jpg' \) 2>/dev/null | head -1)
if [ -n "$WALL_DEFAULT" ]; then
    cat > "$HOME/.config/hypr/hyprpaper.conf" << PAPEREOF
preload = $WALL_DEFAULT
wallpaper = ,$WALL_DEFAULT
splash = false
ipc = off
PAPEREOF
    ok "Hyprpaper configured with wallpaper: $(basename "$WALL_DEFAULT")"
else
    cat > "$HOME/.config/hypr/hyprpaper.conf" << 'PAPEREOF'
# Add your wallpaper path here:
# preload = ~/Pictures/Wallpapers/your-wallpaper.png
# wallpaper = ,~/Pictures/Wallpapers/your-wallpaper.png
splash = false
ipc = off
PAPEREOF
    warn "No wallpaper found. Edit ~/.config/hypr/hyprpaper.conf manually"
fi

# --- Hypridle (auto-lock + screen off) ---
log "Writing Hypridle config..."
cat > "$HOME/.config/hypr/hypridle.conf" << 'IDLEEOF'
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

# Dim screen after 3 min
listener {
    timeout = 180
    on-timeout = brightnessctl -s set 30%
    on-resume = brightnessctl -r
}

# Lock screen after 5 min
listener {
    timeout = 300
    on-timeout = loginctl lock-session
}

# Screen off after 8 min
listener {
    timeout = 480
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
IDLEEOF
ok "Hypridle auto-lock configured"

# =====================================================================
# MODULE 11: Extra Apps (Zen Browser, tmux, direnv, etc)
# =====================================================================
header "Extra Apps — Browser, Multiplexer, Tools"

# --- Zen Browser ---
log "Installing Zen Browser..."
install_aur zen-browser-bin 2>/dev/null || warn "Zen Browser AUR install failed, try manually"

# --- Tmux + Catppuccin ---
log "Installing tmux..."
install_pkg tmux

# Tmux Plugin Manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

mkdir -p "$HOME/.config/tmux"
cat > "$HOME/.config/tmux/tmux.conf" << 'TMUXEOF'
# ─── Tmux — Catppuccin Mocha ─────────────────────────────
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

# Prefix: Ctrl+A (easier than Ctrl+B)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Mouse support
set -g mouse on

# Start windows/panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# Split panes with | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Reload config
bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

# History
set -g history-limit 50000

# Vi mode
setw -g mode-keys vi

# ─── Catppuccin Theme ────────────────────────────────────
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'catppuccin/tmux#v2.1.0'

set -g @catppuccin_flavor 'mocha'
set -g @catppuccin_window_status_style 'rounded'

set -g status-right-length 100
set -g status-left-length 100
set -g status-left ""
set -g status-right "#{E:@catppuccin_status_session}"
set -agF status-right "#{E:@catppuccin_status_date_time}"

# Initialize TPM (keep at very bottom)
run '~/.tmux/plugins/tpm/tpm'
TMUXEOF
ok "tmux + Catppuccin configured"

# --- direnv ---
log "Installing direnv..."
install_pkg direnv
ok "direnv installed"

# --- auto-cpufreq (battery optimization) ---
log "Installing auto-cpufreq (battery optimizer)..."
install_aur auto-cpufreq 2>/dev/null || true
sudo systemctl enable --now auto-cpufreq.service 2>/dev/null || true
ok "auto-cpufreq enabled"

# --- Bluetooth ---
log "Setting up Bluetooth..."
install_pkg bluez bluez-utils blueman
sudo systemctl enable --now bluetooth.service
ok "Bluetooth ready"

# --- Flatpak apps ---
log "Installing Flatpak apps..."
install_pkg flatpak
flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
flatpak install --user -y flathub com.spotify.Client 2>/dev/null || true
flatpak install --user -y flathub org.telegram.desktop 2>/dev/null || true
flatpak install --user -y flathub com.discordapp.Discord 2>/dev/null || true
ok "Flatpak apps installed (Spotify, Telegram, Discord)"

# --- Roblox (via Sober) ---
log "Installing Roblox (via Sober)..."
flatpak install --user -y flathub org.vinegarhq.Sober 2>/dev/null || \
    warn "Roblox (Sober) install failed. Try: flatpak install flathub org.vinegarhq.Sober"
ok "Roblox (Sober) installed"

# =====================================================================
# MODULE 11C: Windows Compatibility & Virtualization
# =====================================================================
header "Windows Compatibility — VM, Bottles, Office"

# --- Check hardware virtualization support ---
log "Checking virtualization support..."
if grep -qE 'vmx|svm' /proc/cpuinfo 2>/dev/null; then
    ok "Hardware virtualization supported (Intel VT-x / AMD-V)"
else
    warn "Hardware virtualization NOT detected. Enable VT-x in BIOS!"
fi

# --- QEMU/KVM + Virt-Manager (Windows VM) ---
log "Installing QEMU/KVM virtualization stack..."
install_pkg qemu-full virt-manager libvirt edk2-ovmf dnsmasq iptables-nft \
    swtpm spice-vdagent vde2 bridge-utils

# Enable libvirt services
sudo systemctl enable --now libvirtd.service
sudo systemctl enable --now virtlogd.service

# Add user to libvirt + kvm groups (no sudo needed for VM management)
sudo usermod -aG libvirt "$USER"
sudo usermod -aG kvm "$USER"

# --- QEMU user permissions (run VMs without root) ---
log "Configuring QEMU permissions..."
sudo sed -i 's/^#\?user = .*/user = "'"$USER"'"/' /etc/libvirt/qemu.conf 2>/dev/null || true
sudo sed -i 's/^#\?group = .*/group = "libvirt"/' /etc/libvirt/qemu.conf 2>/dev/null || true
sudo systemctl restart libvirtd.service

# --- Enable nested virtualization (Docker in Windows VM, etc) ---
log "Enabling nested virtualization..."
if grep -qi 'intel' /proc/cpuinfo; then
    echo 'options kvm_intel nested=1' | sudo tee /etc/modprobe.d/kvm-intel.conf > /dev/null
    sudo modprobe -r kvm_intel 2>/dev/null || true
    sudo modprobe kvm_intel nested=1 2>/dev/null || true
    ok "Intel nested virtualization enabled"
elif grep -qi 'amd' /proc/cpuinfo; then
    echo 'options kvm_amd nested=1' | sudo tee /etc/modprobe.d/kvm-amd.conf > /dev/null
    sudo modprobe -r kvm_amd 2>/dev/null || true
    sudo modprobe kvm_amd nested=1 2>/dev/null || true
    ok "AMD nested virtualization enabled"
fi

# --- Hugepages for VM (15-20% memory speed boost) ---
log "Configuring hugepages for VM performance..."
# Reserve 2GB of hugepages (1024 x 2MB pages) for VM use
echo 'vm.nr_hugepages = 1024' | sudo tee /etc/sysctl.d/99-hugepages.conf > /dev/null
sudo sysctl -p /etc/sysctl.d/99-hugepages.conf 2>/dev/null || true
# Add user to hugetlbfs group
sudo mkdir -p /dev/hugepages
sudo chown root:kvm /dev/hugepages 2>/dev/null || true
ok "Hugepages configured (2GB reserved for VMs)"

# --- Enable default NAT network ---
sudo virsh net-autostart default 2>/dev/null || true
sudo virsh net-start default 2>/dev/null || true

# --- Default storage pool ---
log "Creating default VM storage pool..."
VM_POOL="$HOME/VMs"
mkdir -p "$VM_POOL"
sudo virsh pool-define-as default dir --target "$VM_POOL" 2>/dev/null || true
sudo virsh pool-autostart default 2>/dev/null || true
sudo virsh pool-start default 2>/dev/null || true
ok "VM storage pool: $VM_POOL"

# --- Download VirtIO drivers ISO (makes Windows VM 2x faster) ---
log "Downloading VirtIO Windows drivers..."
VIRTIO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
VIRTIO_ISO="$VM_POOL/virtio-win.iso"
if [ ! -f "$VIRTIO_ISO" ]; then
    curl -fsSL -o "$VIRTIO_ISO" "$VIRTIO_URL" 2>/dev/null &
    log "  VirtIO ISO downloading in background to: $VIRTIO_ISO"
fi

# --- IOMMU (GPU Passthrough preparation \u2014 auto-enable if hardware supports) ---
log "Checking IOMMU for GPU passthrough..."
GPU_COUNT=$(lspci | grep -ciE 'vga|3d|display')
if [ "$GPU_COUNT" -ge 2 ]; then
    log "Multiple GPUs detected! Enabling IOMMU for GPU passthrough..."
    if grep -qi 'intel' /proc/cpuinfo; then
        IOMMU_PARAM="intel_iommu=on iommu=pt"
    else
        IOMMU_PARAM="amd_iommu=on iommu=pt"
    fi
    # Add IOMMU to kernel parameters
    if ! grep -q 'iommu=pt' /etc/default/grub 2>/dev/null; then
        sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$IOMMU_PARAM /" /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
        ok "IOMMU enabled (reboot required for GPU passthrough)"
    fi
else
    log "  Single GPU detected \u2014 GPU passthrough not available"
    log "  (Will auto-enable when 2+ GPUs detected, e.g. on desktop with dGPU)"
fi

# --- CPU Pinning Hook (auto-isolate CPU cores for VM) ---
log "Installing CPU pinning hook for libvirt..."
sudo mkdir -p /etc/libvirt/hooks
cat << 'CPUPIN' | sudo tee /etc/libvirt/hooks/qemu > /dev/null
#!/bin/bash
# Libvirt hook: auto CPU pinning for better VM performance
# Isolates cores 2-3 for VM, leaves 0-1 for host
GUEST_NAME="$1"
ACTION="$2"

if [ "$ACTION" = "started" ]; then
    # When VM starts: pin VM to cores 2-3 (adjust for your CPU)
    TOTAL_CORES=$(nproc)
    if [ "$TOTAL_CORES" -ge 4 ]; then
        systemctl set-property --runtime "machine-qemu\\x2d*" AllowedCPUs=2-$((TOTAL_CORES-1)) 2>/dev/null || true
    fi
elif [ "$ACTION" = "stopped" ]; then
    # When VM stops: release all cores
    systemctl set-property --runtime "machine-qemu\\x2d*" AllowedCPUs=0-$(($(nproc)-1)) 2>/dev/null || true
fi
CPUPIN
sudo chmod +x /etc/libvirt/hooks/qemu
ok "CPU pinning hook installed (auto-isolate cores for VM)"

# --- Optimized VM template config ---
log "Creating optimized VM config template..."
cat > "$VM_POOL/README-vm-tips.txt" << 'VMTIPS'
======================================================================
  QEMU/KVM Performance Cheatsheet
======================================================================

--- CREATE WINDOWS VM (virt-manager) ---
1. New VM > Local install > select Windows ISO
2. RAM: 4096 MB (check "Enable hugepages" in XML)
3. CPU: 2 cores, topology 1 socket / 1 core / 2 threads
4. Disk: 60GB, bus=VirtIO, cache=writeback, io=threads
5. NIC: virtio
6. Add Hardware > Storage > select virtio-win.iso as CDROM
7. Boot: install Windows, load VirtIO drivers from CDROM

--- ENABLE HUGEPAGES IN VM XML ---
<memoryBacking>
  <hugepages/>
</memoryBacking>

--- ENABLE IO THREADS IN VM XML ---
<iothreads>2</iothreads>
<disk type="file" device="disk">
  <driver name="qemu" type="qcow2" cache="writeback" io="threads"/>
</disk>

--- ENABLE CPU PASSTHROUGH IN VM XML ---
<cpu mode="host-passthrough" check="none" migratable="on"/>

--- GPU PASSTHROUGH (desktop with 2 GPUs only) ---
1. Enable IOMMU in BIOS + kernel (auto-done by this script if 2 GPUs)
2. Identify GPU IOMMU group: find /sys/kernel/iommu_groups -type l
3. Bind GPU to vfio-pci driver
4. Add GPU as PCI device in virt-manager
5. Install NVIDIA/AMD drivers inside Windows VM

--- USEFUL COMMANDS ---
virsh list --all          # List all VMs
virsh start win11         # Start VM
virsh shutdown win11      # Graceful shutdown
virsh destroy win11       # Force stop
virt-manager              # GUI manager
======================================================================
VMTIPS
ok "VM cheatsheet saved to $VM_POOL/README-vm-tips.txt"

# --- Windows ISO download helper script ---
cat > "$VM_POOL/download-windows-iso.sh" << 'WINISO'
#!/bin/bash
# Helper to download Windows evaluation ISO
echo "===================================="
echo "  Windows ISO Download Options"
echo "===================================="
echo ""
echo "1. Windows 11 (official):"
echo "   https://www.microsoft.com/software-download/windows11"
echo ""
echo "2. Windows 11 Evaluation (free 90 days, for testing):"
echo "   https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise"
echo ""
echo "3. Tiny11 (community-stripped Windows 11, lightweight ~4GB):"
echo "   https://github.com/ntdevlabs/tiny11builder"
echo ""
echo "Recommended: Download ISO manually, save to ~/VMs/"
echo "Then: virt-manager > New VM > select the .iso"
WINISO
chmod +x "$VM_POOL/download-windows-iso.sh"
ok "Windows ISO helper saved: $VM_POOL/download-windows-iso.sh"

ok "QEMU/KVM fully optimized (near-native performance)"
log "  VM storage: $VM_POOL"
log "  Tips: cat $VM_POOL/README-vm-tips.txt"
log "  Windows ISO: bash $VM_POOL/download-windows-iso.sh"

# --- Bottles (run Windows apps WITHOUT a VM) ---
log "Installing Bottles (Windows app runner)..."
flatpak install --user -y flathub com.usebottles.bottles 2>/dev/null || \
    install_aur bottles 2>/dev/null || true
ok "Bottles installed (run MS Office 2016, small Windows apps)"

# --- LibreOffice (native Office alternative) ---
log "Installing LibreOffice..."
install_pkg libreoffice-fresh
ok "LibreOffice installed (opens .docx, .xlsx, .pptx natively)"

# --- KDE Connect (phone <-> laptop sync) ---
log "Installing KDE Connect..."
install_pkg kdeconnect
ok "KDE Connect installed (pair phone for file transfer, notifications, remote)"

# --- Obsidian (markdown knowledge base) ---
log "Installing Obsidian..."
install_aur obsidian-bin 2>/dev/null || \
    flatpak install --user -y flathub md.obsidian.Obsidian 2>/dev/null || true
ok "Obsidian installed (markdown note-taking)"

# --- KeePassXC (password manager, offline, encrypted) ---
log "Installing KeePassXC..."
install_pkg keepassxc
ok "KeePassXC installed (encrypted password manager, works offline)"

# --- Screen recording ---
log "Installing screen recording tools..."
install_pkg obs-studio wf-recorder
ok "OBS Studio + wf-recorder installed"
log "  OBS: full studio (streaming + recording)"
log "  wf-recorder: lightweight Wayland recorder"
log "  Quick record: wf-recorder -f ~/Videos/recording.mp4"
log "  Region record: wf-recorder -g \"\$(slurp)\" -f ~/Videos/clip.mp4"

ok "Windows compatibility & productivity ready"

# =====================================================================
# MODULE 11B: Gaming (Steam, Minecraft, PCSX2)
# =====================================================================
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
# ─── MangoHud — Catppuccin Style FPS Overlay ────────────
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

# Optimized PCSX2 config for Intel Iris Plus G7
mkdir -p "$HOME/.config/PCSX2/inis"
cat > "$HOME/.config/PCSX2/inis/GS.ini" << 'PCSX2GS'
# ─── PCSX2 Graphics — Optimized for Intel Iris Plus ───
Renderer = 12
upscale_multiplier = 1
texture_filtering = 2
anisotropic_filtering = 0
ManualHardwareRendererFixes = false
UserHacks_align_sprite = 0
UserHacks_merge_sprite = 0
LinearPresent = 1
Vsync = 1
PCSX2GS

cat > "$HOME/.config/PCSX2/inis/PCSX2.ini" << 'PCSX2INI'
# ─── PCSX2 Core — Optimized for i5-1035G7 ──────────
Framerate_Turbo = 200
Framerate_Slowmo = 50
Framerate_Nominal = 100
Enable_MTVU = true
Enable_Instant_VU1 = true
Enable_Fast_CDVD = true
PCSX2INI

ok "PCSX2 configured (add your PS2 ISO files to play, e.g. Black)"

log "Gaming setup summary:"
log "  - CS2: Open Steam > install free"
log "  - Far Cry 3: Buy on Steam > enable Proton > play"
log "  - Minecraft: Open PrismLauncher > login > play"
log "  - PS2 (Black): Open PCSX2 > load your ISO > play"
log "  - FPS overlay: Press F12 in any game"
log "  - GameMode: Run games with 'gamemoderun ./game'"

ok "Gaming module ready"

# =====================================================================
# MODULE 12: Waybar Config (Hyprland Status Bar)
# =====================================================================
header "Waybar — Aesthetic Status Bar for Hyprland"

mkdir -p "$HOME/.config/waybar"

# Waybar config
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
cat > "$HOME/.config/waybar/style.css" << 'WBSTYLE'
/* ─── Waybar — Catppuccin Mocha Glass ─────────────────── */
@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap");

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

# =====================================================================
# MODULE 13: Searchable Guide System
# =====================================================================
header "Nexus Command Center & Guide System"

# --- Nexus Command Center (popup command palette) ---
log "Installing Nexus Command Center..."
mkdir -p "$HOME/.local/bin"
# Copy nexus from repo or create inline
if [ -f "$(dirname "$0")/nexus.sh" ]; then
    cp "$(dirname "$0")/nexus.sh" "$HOME/.local/bin/nexus"
else
    # If running standalone, download from repo
    curl -fsSL -o "$HOME/.local/bin/nexus" \
        "https://raw.githubusercontent.com/rixzkiye/CachyOS-Workstation-Setup/main/nexus.sh" 2>/dev/null || true
fi
chmod +x "$HOME/.local/bin/nexus"
ok "Nexus installed (Super+X to open)"
log "  35+ quick actions: AI, screenshots, system, apps, dev tools"

log "Creating searchable guide..."
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/guide" << 'GUIDEEOF'
#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  CachyOS Workstation Guide — type 'guide' or 'guide <keyword>'
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GUIDE_DATA="
[hyprland] Super+Return          → Open Kitty terminal
[hyprland] Super+D                → App launcher (Rofi)
[hyprland] Super+Q                → Close window
[hyprland] Super+F                → Fullscreen
[hyprland] Super+Space            → Toggle floating
[hyprland] Super+1-9              → Switch workspace
[hyprland] Super+Shift+1-9        → Move window to workspace
[hyprland] Super+Arrow            → Move focus
[hyprland] Super+Shift+Arrow      → Move window
[hyprland] Super+L                → Lock screen
[hyprland] Super+E                → File manager (Thunar)
[hyprland] Super+V                → Clipboard history
[hyprland] Super+/                → Keybind cheatsheet
[hyprland] Super+Shift+S          → Screenshot (region)
[hyprland] Print                  → Screenshot (full)
[hyprland] Super+Mouse drag       → Move/resize window

[terminal] kitty                  → GPU-accelerated terminal
[terminal] tmux                   → Terminal multiplexer
[terminal] tmux: Ctrl+A c         → New window
[terminal] tmux: Ctrl+A n/p       → Next/prev window
[terminal] tmux: Ctrl+A |         → Split vertical
[terminal] tmux: Ctrl+A -         → Split horizontal
[terminal] tmux: Ctrl+A Shift+I   → Install plugins (first time)

[shell] z <dir>                   → Smart cd (zoxide, learns your dirs)
[shell] Ctrl+R                    → Search command history (fzf)
[shell] Tab                       → Smart autocomplete (fzf-tab)
[shell] ls / ll / la              → eza with icons + git status
[shell] cat <file>                → bat (syntax-highlighted cat)
[shell] find <name>               → fd (fast find replacement)
[shell] grep <pattern>            → rg (ripgrep, 10x faster grep)
[shell] top                       → btm (beautiful system monitor)
[shell] ff                        → fastfetch (system info)
[shell] keys                      → Hyprland keybinding cheatsheet

[git] git status                  → Check changes
[git] git add . && git commit     → Stage & commit
[git] git push                    → Push to remote
[git] gh auth login               → Authenticate GitHub CLI
[git] gh repo create              → Create new repo
[git] gh pr create                → Create pull request
[git] lazydocker                  → Docker TUI manager

[docker] docker ps                → List running containers
[docker] docker compose up -d     → Start compose services
[docker] docker compose down      → Stop compose services
[docker] lazydocker               → Interactive Docker manager

[node] fnm use --lts              → Switch to LTS Node
[node] pnpm install               → Install dependencies
[node] pnpm run dev               → Start dev server
[node] pnpm add <pkg>             → Add package
[node] pnpm dlx <cmd>             → Run npx-like command

[python] uv init                  → Create new project
[python] uv add <pkg>             → Add dependency
[python] uv run script.py         → Run script
[python] uv venv                  → Create virtual env

[rust] cargo new <name>           → Create project
[rust] cargo build                → Build
[rust] cargo run                  → Run
[rust] cargo test                 → Test

[go] go mod init <module>         → Create module
[go] go run .                     → Run
[go] go build                     → Build

[flutter] flutter create <app>    → New Flutter project
[flutter] flutter run             → Run on device/emulator
[flutter] flutter build apk       → Build APK
[flutter] flutter doctor          → Check setup
[flutter] emulator -avd Pixel_7   → Launch Android emulator
[flutter] scrcpy                  → Mirror phone to screen
[flutter] adb devices             → List connected devices

[kotlin] kotlinc file.kt -include-runtime -d app.jar → Compile
[kotlin] java -jar app.jar        → Run compiled
[kotlin] gradle build             → Gradle build
[kotlin] ./gradlew assembleDebug  → Build Android APK

[editor] antigravity              → AI-powered editor (VS Code fork)
[editor] nvim <file>              → Neovim with Catppuccin
[editor] nvim: Space              → Leader key (which-key shows options)
[editor] nvim: Space+ff           → Find files (Telescope)
[editor] nvim: Space+fg           → Live grep (Telescope)
[editor] nvim: Space+e            → File explorer (nvim-tree)

[ai] ollama run qwen3:30b-a3b    → Best reasoning (debat, filosofi)
[ai] ollama run deepseek-r1:7b   → Math & logic specialist
[ai] ollama run qwen2.5-coder:7b → Coding assistant
[ai] ollama list                  → Show downloaded models
[ai] ollama pull <model>          → Download new model
[ai] ollama rm <model>            → Remove model
[ai] antigravity                  → Cloud AI coding agent

[gaming] steam                    → Steam launcher
[gaming] gamemoderun <game>       → Auto-boost CPU/GPU
[gaming] mangohud <game>          → FPS overlay
[gaming] F12 (in game)            → Toggle MangoHud overlay
[gaming] prismlauncher            → Minecraft launcher
[gaming] pcsx2                    → PS2 emulator

[vm] virt-manager                 → VM manager GUI
[vm] virsh list --all              → List all VMs
[vm] virsh start <vm>             → Start VM
[vm] virsh shutdown <vm>          → Stop VM
[vm] cat ~/VMs/README-vm-tips.txt → VM performance tips
[vm] bash ~/VMs/download-windows-iso.sh → Windows ISO links

[apps] bottles                    → Run Windows apps without VM
[apps] libreoffice                → Office suite
[apps] obsidian                   → Markdown notes
[apps] keepassxc                  → Password manager
[apps] obs-studio                 → Screen recording + streaming
[apps] wf-recorder -f out.mp4    → Quick screen record
[apps] scrcpy                     → Mirror phone screen

[system] update                   → Full system update (alias)
[system] cleanup                  → Remove orphan packages (alias)
[system] timeshift                → System backup/restore
[system] btm                      → System monitor
[system] duf                      → Disk usage
[system] dust <dir>               → Directory size analyzer
[system] procs                    → Better ps

[record] wf-recorder -f vid.mp4                → Record full screen
[record] wf-recorder -g \"\$(slurp)\" -f clip.mp4 → Record selected area
[record] obs-studio                             → Full recording studio
[record] grim ~/Pictures/Screenshots/shot.png   → Screenshot full
[record] grim -g \"\$(slurp)\" out.png            → Screenshot region

[network] nmcli device wifi list  → List WiFi networks
[network] nmcli device wifi connect <SSID> password <pw> → Connect
[network] curl ifconfig.me        → Show public IP
[network] ss -tulnp               → Show open ports
"

C1='\033[38;2;203;166;247m'  # mauve
C2='\033[38;2;137;180;250m'  # blue
C3='\033[38;2;166;227;161m'  # green
NC='\033[0m'
BOLD='\033[1m'

if [ -z "$1" ]; then
    # No argument: interactive fzf search
    if command -v fzf &>/dev/null; then
        echo "$GUIDE_DATA" | grep -v '^$' | sed 's/^ *//' | \
            fzf --ansi --prompt="🔍 Search guide: " \
                --header="Type to search. Enter to copy. Esc to quit." \
                --color="bg:#1e1e2e,fg:#cdd6f4,hl:#f38ba8,bg+:#313244,fg+:#cdd6f4,hl+:#f38ba8,info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc,marker:#f5e0dc,spinner:#f5e0dc" \
                --border=rounded | wl-copy 2>/dev/null
    else
        echo "$GUIDE_DATA" | less
    fi
else
    # With argument: filter by keyword
    KEYWORD="$*"
    RESULTS=$(echo "$GUIDE_DATA" | grep -i "$KEYWORD" | sed 's/^ *//')
    if [ -z "$RESULTS" ]; then
        echo -e "${C1}No results for '${BOLD}$KEYWORD${NC}${C1}'. Try: guide docker, guide git, guide flutter${NC}"
    else
        echo -e "${C1}━━━ Guide: ${BOLD}$KEYWORD${NC} ${C1}━━━${NC}"
        echo "$RESULTS" | while IFS= read -r line; do
            TAG=$(echo "$line" | grep -oP '^\[.*?\]')
            CMD=$(echo "$line" | sed 's/^\[.*\] //' | sed 's/ →.*//')
            DESC=$(echo "$line" | grep -oP '→.*' || true)
            echo -e "  ${C2}$TAG${NC} ${BOLD}$CMD${NC} ${C3}$DESC${NC}"
        done
    fi
fi
GUIDEEOF
chmod +x "$HOME/.local/bin/guide"
ok "Guide system installed"
log "  Usage: guide              → interactive search (fzf)"
log "  Usage: guide docker       → search 'docker' entries"
log "  Usage: guide flutter      → search 'flutter' entries"
log "  Usage: guide hyprland     → search shortcuts"

# =====================================================================
# FINAL: Self-Check & Summary
# =====================================================================
echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}  🎉 SETUP COMPLETE — Verification Summary${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

check() {
    if command -v "$1" &>/dev/null; then
        local ver
        ver=$($1 --version 2>/dev/null | head -1 || echo "installed")
        echo -e "  ${GREEN}✓${NC} $2: ${CYAN}$ver${NC}"
    else
        echo -e "  ${RED}✗${NC} $2: NOT FOUND"
    fi
}

echo -e "${BOLD}  ── Core Tools ──${NC}"
check git       "Git"
check gh        "GitHub CLI"
check docker    "Docker"
check node      "Node.js"
check pnpm      "pnpm"
check uv        "uv (Python)"
check rustc     "Rust"
check go        "Go"
check flutter   "Flutter"
check dart      "Dart"
check kotlin    "Kotlin"
check java      "Java (JDK)"
check gradle    "Gradle"
check adb       "ADB"

echo -e "\n${BOLD}  ── Editors & Terminal ──${NC}"
check antigravity "Antigravity (Editor)"
check nvim      "Neovim"
check kitty     "Kitty Terminal"
check tmux      "tmux"
check starship  "Starship Prompt"
check zsh       "Zsh"

echo -e "\n${BOLD}  ── CLI Power Tools ──${NC}"
check rg        "ripgrep"
check fd        "fd"
check bat       "bat"
check eza       "eza"
check fzf       "fzf"
check zoxide    "zoxide"
check btm       "bottom"
check direnv    "direnv"
check lazydocker "lazydocker"
check fastfetch "fastfetch"

echo -e "\n${BOLD}  ── Desktop & Apps ──${NC}"
check Hyprland  "Hyprland"
check waybar    "Waybar"
check rofi      "rofi"
check scrcpy    "scrcpy (device mirror)"
check antigravity "Antigravity"
check ollama    "Ollama (Local AI)"
check steam     "Steam"
check pcsx2     "PCSX2 (PS2 Emulator)"

echo ""
echo -e "${YELLOW}  ⚠ POST-REBOOT CHECKLIST:${NC}"
echo -e "    1. ${BOLD}Reboot${NC} to apply docker group & zsh shell"
echo -e "    2. ${CYAN}cat ~/.ssh/id_ed25519.pub${NC} → copy & add to GitHub SSH keys"
echo -e "    3. ${CYAN}gh auth login${NC} → setup GitHub CLI"
echo -e "    4. ${CYAN}tmux${NC} → press ${BOLD}Ctrl+A, Shift+I${NC} to install tmux plugins"
echo -e "    5. Choose session at login screen:"
echo -e "       ${BOLD}KDE Plasma${NC} → familiar desktop (like Windows)"
echo -e "       ${BOLD}Hyprland${NC}   → tiling WM (press ${CYAN}Super+/${NC} for keybind help)"
echo -e "    6. If using KDE: System Settings → Appearance → Catppuccin Mocha"
echo -e "    7. Set ${CYAN}Kitty${NC} as default terminal"
echo -e "    8. Set ${CYAN}Zen Browser${NC} as default browser"
echo -e "    9. ${CYAN}ollama list${NC} → verify AI models downloaded"
echo -e "   10. ${CYAN}flutter doctor${NC} → verify Flutter setup"
echo -e "   11. ${CYAN}ff${NC} → see your system info in style"
echo ""
echo -e "  ${BOLD}${CYAN}  AI CHEATSHEET:${NC}"
echo -e "    ${CYAN}ollama run qwen3:30b-a3b${NC}    → Debat, filosofi, reasoning"
echo -e "    ${CYAN}ollama run deepseek-r1:7b${NC}   → Math & logic"
echo -e "    ${CYAN}ollama run qwen2.5-coder:7b${NC} → Coding assistant"
echo ""
echo -e "  ${GREEN}✨ Enjoy your new workstation!${NC}"
echo -e "  ${GREEN}Log saved to:${NC} $LOGFILE"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
