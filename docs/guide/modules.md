# 🧩 The 15 Modules

Our setup is divided into **15 highly cohesive, independent modules**. Every module is fully idempotent (can be re-run endlessly without breaking things) and automatically backs up configurations before making any changes.

Here is the comprehensive breakdown of what each module does under the hood.

## 01: Base & GPU Drivers
This module forms the bedrock of your CachyOS installation.
* Automatically detects your GPU manufacturer via `lspci`.
* Installs `nvidia-dkms` and `linux-cachyos-headers` for NVIDIA, or `mesa` layers for AMD/Intel.
* Prepares `paru` for AUR package management if missing.
* **Smart Secure Boot**: Detects if Secure Boot is enabled via `mokutil` and guides the user to enroll keys for proprietary NVidia drivers seamlessly.

## 02: Kernel & Performance
Unleashes the full power of the Linux kernel tailored for raw, low-latency performance.
* Injects finely-tuned `sysctl` rules tailored for Zen/CachyOS kernels.
* Enables NVMe queue polling for Gen4/Gen5 SSDs.
* Sets Transparent Huge Pages (THP) to `madvise` for optimal database and JVM performance.
* Enables hardware video acceleration (GuC/HuC) on Intel systems.

## 03: Security & Maintenance
Sets up local firewalls and automated housekeeping tasks.
* Installs and configures `ufw` tightly blocking incoming traffic and allowing outgoing.
* Generates an `ed25519` SSH key unconditionally securely.
* Forces `systemd-resolved` to utilize privacy-focused Cloudflare DNS (1.1.1.1) and enables DNS over TLS.
* Implements `systemd` timers for weekly background `pacman` cache cleanup.

## 04: Development Tools
The heavy lifters for programmers across all major stacks.
* **Docker**: Configured to run rootless with auto-started daemon.
* **JavaScript/TypeScript**: Installs `fnm` and sets `Node 24` as default, coupled with `pnpm` specifically for hard-linking disk space savings.
* **Python**: Purges `pip` usage globally in favor of `uv` (Astral's lightning-fast Rust-based package manager).
* **Rust**: Orchestrates `rustup` complete with nightly toolchains.
* **Go**: Native package installation with GOPATH setup.

## 05: Mobile Development
Android and cross-platform native development setup.
* Automatically downloads and sets up the command-line tools for Android SDK without needing bloated Android Studio.
* Bootstraps Flutter with auto-path configuration.
* Configures `scrcpy` for wireless low-latency screen mirroring of Android test devices.

## 06: Shell & Dotfiles
The terminal aesthetics and core interaction mechanics.
* Replaces bash with `zsh` running `oh-my-zsh`.
* Injects a customized `Starship.rs` prompt.
* Binds `fzf` natively to `tab` completions.
* Installs `kitty` terminal with GPU-accelerated rendering and matching Catppuccin color overlays.

## 07: Editors
Configures the code editors.
* Centralizes the installation of `lazy.nvim` to provide an IDE-like VIM experience.
* Hooks in **Antigravity**, Google's cutting-edge local AI-powered VS Code fork.

## 08: Desktop Theme
KDE and raw aesthetics.
* Applies full Catppuccin Mocha overrides for SDDM, GRUB, and Qt applications.
* Automates font installations for Nerd Fonts (Inter, FiraCode).

## 09: Hyprland Window Manager
The defining UI element of the ecosystem.
* Highly sophisticated `hyprland.conf` with dynamic multi-monitor handling.
* Pre-configured window rules for specific floating behaviors (like the popup Terminal).
* Complete `rofi` theme integrations.
* Preconfigured `hypridle` and `hyprlock`.

## 10: Extra Apps
Standard workstation applications.
* Zen Browser (highly optimized Firefox fork).
* Terminal multiplexing via `tmux`.
* Flatpak initialization with Spotify, Discord, and Telegram integrations.

## 11: Gaming
Linux gaming optimized specifically for CachyOS.
* Steam (Proton) with MangoHud global variable injections.
* **PCSX2**: PlayStation 2 emulation mapped to auto-scale upscaling resolutions dynamically based on whether it detects an iGPU or distinct GPU.
* PrismLauncher for Minecraft power users.

## 12: Virtual Machines
Native hypervisors and Windows compatibility layer.
* `QEMU/KVM` and `libvirt` with user group permissions mapped.
* Advanced XML injections to map Windows VMs to isolated hugepages and specific CPU pinning topology if the system has >8 cores.
* `Bottles` for running raw Windows `.exe` formats seamlessly.

## 13: Waybar
The glassy top panel for Hyprland.
* CSS configured utilizing standard CSS Variables hooked into the Theme Engine.
* Custom scripts for live Bluetooth, Audio, and internet toggles.

## 14: Nexus & Guide
* Deploys the monolithic `/usr/local/bin/nexus` dashboard.
* Creates `guide`, the bilingual (EN/ID) interactive searchable database of all core terminal commands utilized in the setup.

## 15: Living Ecosystem
* Installs the 7 utilities: `theme-switch`, `config-rollback`, `dotfiles-sync`, `ai-tuner`, `app-store`, `health-check`, and `post-install`.
