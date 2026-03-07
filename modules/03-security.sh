#!/usr/bin/env bash
# Module 03: Security & Maintenance
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
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
    # Let ssh-keygen prompt for passphrase interactively (more secure)
    # If running non-interactively (piped stdin), use empty passphrase as fallback
    if [ -t 0 ]; then
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519"
    else
        warn "Non-interactive mode: generating SSH key without passphrase"
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" -N "" -q
    fi
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
    # CachyOS already has zram, just optimize compression if not in use
    if ! swapon --show | grep -q zram0 2>/dev/null; then
        echo 'zstd' | sudo tee /sys/block/zram0/comp_algorithm > /dev/null 2>&1 || true
        ok "Zram compression set to zstd (best ratio)"
    else
        ok "Zram already active (compression change requires reboot)"
    fi
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
User=root
ExecStart=/usr/bin/paccache -rk 2
ExecStart=/bin/bash -c 'pacman -Qdtq | xargs -r pacman -Rns --noconfirm 2>/dev/null || true'
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

