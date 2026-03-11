# 🧩 The Core Installation Modules

Our setup has been deeply refactored from 15 bash scripts into **6 highly cohesive, independent Go modules**. Every module is fully idempotent (can be re-run endlessly without breaking things) and automatically backs up configurations via BTRFS/Snapper before making any changes.

Here is the comprehensive breakdown of what each Go package does under the hood.

## `base.go` (Base & GPU Drivers)
This module forms the bedrock of your CachyOS installation.
* Automatically detects your GPU manufacturer via `lspci`.
* Installs `nvidia-dkms` and `linux-cachyos-headers` for NVIDIA, or `mesa` layers for AMD/Intel.
* **Smart Secure Boot**: Detects if Secure Boot is enabled via `mokutil` and guides the user to enroll keys for proprietary NVidia drivers seamlessly.

## `system.go` (Kernel & Security)
Unleashes the full power of the Linux kernel tailored for raw, low-latency performance and security.
* Injects finely-tuned `sysctl` rules tailored for Zen/CachyOS kernels.
* Enables NVMe queue polling for Gen4/Gen5 SSDs.
* Sets Transparent Huge Pages (THP) to `madvise` for optimal database and JVM performance.
* Installs and configures `ufw` tightly blocking incoming traffic and allowing outgoing.
* Generates an `ed25519` SSH key unconditionally securely.
* Forces `systemd-resolved` to utilize privacy-focused Cloudflare DNS (1.1.1.1) and enables DNS over TLS.

## `dev.go` (Development Tools & Editors)
The heavy lifters for programmers across all major stacks.
* **Docker**: Configured to run rootless with auto-started daemon.
* **JavaScript/TypeScript**: Installs `fnm` and sets `Node 24` as default, coupled with `pnpm`.
* **Python**: Standardizes on `uv` (Astral's lightning-fast Rust-based package manager).
* **Rust**: Orchestrates `rustup`.
* **Go**: Native package installation.
* Centralizes the installation of `lazy.nvim` to provide an IDE-like VIM experience.
* Hooks in **Antigravity**, Google's cutting-edge local AI-powered VS Code fork.

## `desktop.go` (Hyprland, Waybar & Themes)
KDE/Hyprland aesthetics and core interaction mechanics.
* Replaces bash with the modern `fish` shell and `Starship.rs`.
* Applies full Catppuccin Mocha overrides for SDDM, GRUB, and Qt applications.
* Highly sophisticated `hyprland.conf` with dynamic multi-monitor handling.
* CSS configured for `waybar` utilizing standard CSS Variables hooked into the Theme Engine.

## `apps.go` (Extra Apps & Gaming)
Standard workstation applications and specialized Proton layers.
* Zen Browser (highly optimized Firefox fork).
* Native Arch and AUR packages for Spotify, Discord, and Telegram integrations.
* Steam (Proton) with MangoHud global variable injections.
* **PCSX2**: PlayStation 2 emulation mapped to auto-scale upscaling resolutions dynamically.

## `extra.go` (Virtual Machines & Mobile SDK)
Native hypervisors and Android integrations.
* `QEMU/KVM` and `libvirt` with user group permissions mapped.
* Advanced configurations to map Windows VMs to isolated hugepages and specific CPU pinning topology if the system has >8 cores.
* Automatically downloads and sets up the Android SDK and Flutter.

## `nexus` Commands (Ecosystem Tools)
* `nexus apps`: App Store
* `nexus theme`: Theme Switcher
* `nexus sync`: Cloud Sync & Time Machine
* `nexus doctor`: System Health Check and AI Tuner
* `nexus chat`: AI Chat Interface
