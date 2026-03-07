<div align="center">
  <h1>📝 Changelog</h1>
  <p>All notable changes to the <b>CachyOS Workstation Setup</b> will be documented in this file.<br>
  The format is based on <a href="https://keepachangelog.com/en/1.0.0/">Keep a Changelog</a>, and this project adheres to <a href="https://semver.org/spec/v2.0.0.html">Semantic Versioning</a>.</p>
</div>

<hr>

## [v1.0.0] - The Ecosystem Update (2026-03-07)

This is a massive architectural and feature release that transforms the setup script into a continuous ecosystem, introducing post-install health checks, custom app stores, and robust disaster recovery mechanisms.

### ✨ New Features

- **Living Ecosystem (/usr/local/bin/)**
  - `health-check`: 🩺 8-category system integrity validator assessing GPU drivers, Hyprland syntax, Waybar state, critical packages, and disk health.
  - `ai-tuner`: 🧠 Local telemetry gathering (top, vmstat) piped to `qwen2.5-coder:7b` for real-time sysctl optimization hints.
  - `app-store`: 🏪 Curated GUI App Store via Rofi supporting Pacman, AUR, and Flatpak. Now supports user customization via `~/.config/app-store-custom.conf`.
  - `theme-switch`: 🎨 Dynamic hot-swapping between 7 Catppuccin flavors + Dracula/Tokyo Night.
  - `config-rollback`: 🛡️ "Time Machine" style config restoration from `~/.config-backup`.
  - `dotfiles-sync`: ☁️ 1-click push of `~/.config` to private GitHub repos with smart ignoring of caches/tokens.

- **Setup & Installation**
  - 🧙‍♂️ **Post-Install Wizard**: Runs on first boot to setup Git identity, default AI model, wallpaper, and cloud sync.
  - 🔍 **Dry-Run Mode**: Run `./setup.sh --dry-run` to preview module sizes, time estimates, and package counts without making changes.
  - 🔄 **Module Dependency Checker**: The TUI installer now proactively warns if you select a module without its recommended dependencies.
  - 🏷️ **Module Versioning**: The installer now tracks checksums in `~/.config/cachy-setup/versions` to skip unchanged modules on subsequent runs.
  
- **System Integration**
  - 🪝 **Pacman Pacman Hooks**: Automatically runs `health-check` after `pacman -Syu` updates to kernel, Hyprland, Waybar, or NVIDIA drivers.
  - 📊 **Nexus System Dashboard**: Press `Super+X` → System Dashboard to view `fastfetch`, active processes, disk usage (`duf`), and memory footprint instantly.

### 📚 Documentation

- **Robust Community Guidelines**
  - 🏗️ **Architecture Diagram**: Mermaid flowchart added to `README.md` visualizing the `setup.sh → modules → ecosystem` pipeline.
  - 📖 **INSTALL_GUIDE.md**: Step-by-step partition and installer configuration guide for vanilla CachyOS.
  - 🤝 **CONTRIBUTING.md**: Standardized contribution rules, test procedures, and `install_pkg`/`safe_config` API docs.
  - 🛡️ **SECURITY.md**: Clear reporting guidelines and security scope boundary mapping.
  - ⚖️ **CODE_OF_CONDUCT.md**: Contributor Covenant v2.1 enforcement.

### 🐛 Fixes & Refactors

- **Architectural Fixes**
  - 🛠️ **Consolidation**: `06-dotfiles.sh` trimmed by 450+ lines (removed redundant Kernel/Desktop snippets).
  - 🛠️ **Editor Standardization**: Moved VS Code config, Neovim (`lazy.nvim`), and Antigravity tarball installation centrally into `07-editors.sh`.
  - 🛠️ **Global Execution**: Ecosystem scripts moved from `~/.local/bin` to `/usr/local/bin` so they are accessible by root (solving Pacman hook execution errors).
  - 🐛 **Alias Conflict**: Removed destructive duplicated block in `.zshrc` overriding `update` and `cleanup` commands.
  - 🐛 **Direct Dispatch**: `nexus.sh` now utilizes global PATH binary resolution rather than hardcoded `~/.local/bin` paths.
  - 🎮 **PCSX2**: Auto-creates `~/.config/PCSX2/bios/` during install and docs updated to clarify GPU-aware automation.

---

<div align="center">
  <sub>Built with ❤️ by PT Ananta Artha Sejahtera</sub>
</div>
