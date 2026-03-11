# CachyOS Installation Guide

Step-by-step guide to install CachyOS and then run the workstation setup.

<details>
<summary><b>📑 Table of Contents</b></summary>

- [Prerequisites](#prerequisites)
- [Step 1: Create CachyOS USB](#step-1-create-cachyos-usb)
- [Step 2: Boot and Install CachyOS](#step-2-boot-and-install-cachyos)
  - [BIOS/UEFI Settings](#biosuefi-settings)
  - [Calamares Installer Settings](#calamares-installer-settings)
  - [Partition Layout (NVMe SSD)](#partition-layout-nvme-ssd)
  - [User Setup](#user-setup)
- [Step 3: First Boot — Run Setup Script](#step-3-first-boot--run-setup-script)
- [Step 4: After Setup](#step-4-after-setup)
- [Troubleshooting](#troubleshooting)

</details>

---

## Prerequisites

- USB drive (8 GB+)
- Internet connection (WiFi or Ethernet)
- Target PC with UEFI boot

## Step 1: Create CachyOS USB

Download ISO from [cachyos.org](https://cachyos.org) and flash:

```bash
# On Linux/macOS
sudo dd if=cachyos-desktop.iso of=/dev/sdX bs=4M status=progress

# On Windows — use Rufus or Ventoy
```

## Step 2: Boot and Install CachyOS

### BIOS/UEFI Settings
- **Disable** Secure Boot (or enable later — script handles MOK enrollment for NVIDIA)
- **Enable** VT-x/AMD-V (for VM module)
- Set boot order: USB first

### Calamares Installer Settings

| Setting | Recommended |
|---------|-------------|
| **Desktop Environment** | **KDE Plasma** (required for theme modules) |
| **Boot Loader** | **GRUB** (not systemd-boot — we install GRUB Catppuccin theme) |
| **Locale** | `en_US.UTF-8` (Guide auto-detects Indonesian if you set `id_ID` later) |
| **Timezone** | `Asia/Jakarta` (or your timezone) |
| **Keyboard** | US layout (standard for programming) |

### Partition Layout (NVMe SSD)

| Mount | Size | Type | Why |
|-------|------|------|-----|
| `/boot/efi` | **512 MB** | FAT32 | EFI System Partition (UEFI boot) |
| `/` (root) | **100-150 GB** | **BTRFS** | OS + packages. BTRFS enables Timeshift snapshots |
| `/home` | **Rest of disk** | **BTRFS** | User data. Separate from root = safe OS reinstall |
| `swap` | **Skip** | — | Script configures Zram (compressed RAM swap) instead |

> **Why BTRFS?** The setup script installs Timeshift which creates instant snapshots on BTRFS (near-zero disk usage). On ext4, snapshots are much slower and larger.

> **Why no swap partition?** Module `02-kernel.sh` configures Zram (compressed swap in RAM). Physical swap partitions are unnecessary for systems with 8+ GB RAM. Only create one if you need hibernate-to-disk.

### User Setup
- **Username**: lowercase, short (e.g., `anartha`) — appears in terminal prompt
- **Password**: memorable — you'll use it often for `sudo`
- **Auto-login**: OK to enable — Hyprlock (`Super+L`) locks screen on demand
- **Hostname**: descriptive (e.g., `workstation`, `advan-pc`)

## Step 3: First Boot — Run Setup Script

After CachyOS installs and you reboot into the desktop:

```bash
# Option A: One-liner (auto-downloads and runs)
curl -fsSL https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/install.sh | bash

# Option B: Clone and customize (recommended)
git clone https://github.com/anantaarthasejahtera/CachyOS-Workstation-Setup.git
cd CachyOS-Workstation-Setup
# Compile the nexus binary and interactively run it
bash build.sh
sudo cp ./nexus /usr/local/bin/nexus
nexus install   # Launch GUI module selector (Bubbletea)
```

### Important
- **Do NOT run as root** — the script uses `sudo` when needed
- **Do NOT run `pacman -Syu` first** — the script handles system update in `01-base.sh`
- **Internet required** — the script downloads packages, fonts, themes, and AI models

## Step 4: After Setup

Reboot when the script finishes:

```bash
sudo reboot
```

After reboot, you'll be in Hyprland. Key shortcuts:

| Shortcut | Action |
|----------|--------|
| `Super+X` | Nexus Command Center |
| `Super+D` | App Launcher (Rofi) |
| `Super+Return` | Open Kitty terminal |
| `Super+L` | Lock screen |
| `Super+N` | Show notification history (dunst) |
| `guide` | Searchable help (160+ entries) |
| `ff` | System info (fastfetch) |

## Troubleshooting

### Can't boot into Hyprland after reboot?
Select "Hyprland" at the SDDM login screen (bottom-left dropdown).

### Screen resolution looks wrong?
Hyprland auto-detects monitors. If needed, edit `~/.config/hypr/hyprland.conf`.

### Wi-Fi not working after install?
```bash
nexus network   # TUI/Rofi for Wi-Fi management
```

### Something broke after `pacman -Syu`?
```bash
health-check   # Auto-diagnose common issues
```
