#!/usr/bin/env bash
# Module 02: Kernel & Performance Tuning
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
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
# — Memory Management —
# Reduce swap aggressiveness (16GB RAM = less swap needed)
vm.swappiness = 10
# Keep filesystem metadata cached longer
vm.vfs_cache_pressure = 50
# Dirty page writeback tuning (better for NVMe)
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# — Network Performance —
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1

# — Kernel Hardening + Performance —
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

