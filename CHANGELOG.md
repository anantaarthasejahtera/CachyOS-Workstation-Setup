<div align="center">
  <h1>📝 Changelog</h1>
  <p>All notable changes to the <b>CachyOS Workstation Setup</b> will be documented in this file.<br>
  The format is based on <a href="https://keepachangelog.com/en/1.0.0/">Keep a Changelog</a>, and this project adheres to <a href="https://semver.org/spec/v2.0.0.html">Semantic Versioning</a>.</p>
</div>

<hr>

## [v2.0.0] - The Go-Native Architecture (2026-03-11)

The most monumental update to the ecosystem. Completely rewrites the legacy 16 bash scripts into a single, high-performance Go binary (`nexus`). Introduces premium, aesthetic, and automated TUI/GUI workflows powered by Charmbracelet and Rofi.

### ✨ Major Features
- **Go-Native Binary**: Replaced all `ecosystem/` and `modules/` bash scripts with a single `/usr/local/bin/nexus` CLI tool.
- **Rofi 2-Column Dashboard**: Transformed the Rofi interface into a wide, premium control center with customized typography and borders.
- **Live Theme Switcher**: `nexus theme` now utilizes a Bubbletea TUI engine, allowing real-time preview of Hyprland border colors before applying.
- **Network Cockpit**: Converted `nmcli` and bash stubs to natively trigger `nexus network` inside Rofi for beautiful Wi-Fi scanning.
- **Waypaper Automation**: Automatically pulls Catppuccin wallpapers from the `orangci` repo and sets up the Waypaper configuration during desktop installation.
- **Interactive Post-Install Wizard**: Enhanced the first-boot experience with Charmbracelet's `huh` and `lipgloss` to render beautiful, Catppuccin-themed forms for GitHub repo synchronization.

---

## [v1.6.0] - The Deep Codebase Audit (2026-03-10)

Comprehensive codebase remediation ensuring zero shell violations, zero duplicate packages, and zero reliance on intermediary dependency managers when native variants exist.

### 🔴 Critical Fixes
- **Shell Policy (Fish Enforcement)**: Eradicated Zsh, Oh My Zsh, and `.zshrc` writing across all modules. Exclusively using Fish shell with `config.fish`, fast aliases (`eza`, `bat`), and maintaining the unified Starship prompt.
- **Strict Anti-Flatpak Policy**: Eliminated all Flatpak usage from Mod 10 (Apps) and Mod 11 (Gaming). Using `telegram-desktop`, `discord` from official repos, and `spotify-launcher`, `obsidian-bin`, `pcsx2-latest-bin` from AUR.
- **Dependency Duplication**: Removed redundant `pavucontrol`, `blueman`, `alacritty`, and `btop` installs across `09-hyprland.sh` and `13-waybar.sh`.

### 🟡 Bug Fixes & Refactors
- **Rofi Theme Ownership**: Centralized all Rofi configurations (`config.rasi`, `media.rasi`, etc.) exclusively into `13-waybar.sh` to prevent overlapping edits.
- **Mobile Environment**: `05-mobile.sh` correctly exports Android PATH to `config.fish` instead of the legacy Zsh configuration.
- **Documentation**: README, Setup Scripts, and Guide Interactive fully translated to recognize the new default Fish environment and Native Package standard.

---

## [v1.7.0] - The Final Stable Bash Version (2026-03-11)

> **Milestone**: This is the final stable Bash version of the ecosystem. Subsequent releases will involve a major architecture migration to **Go** for enhanced performance, type safety, and maintainability.

Refinements to the Wayland ecosystem, introducing a native wallpaper manager and fixing Rofi media widgets integration.

### ✨ New Features
- **Waypaper Integration**: Replaced the custom `wallpaper-picker.sh` script with `waypaper` for a more robust, GUI-based wallpaper management experience. Fully integrated into Waybar and Nexus.

### 🟡 Bug Fixes & Improvements
- **Rofi Media Hub**: Fixed previous/next functionality and ensured thumbnail images update correctly upon song changes.
- **Rofi Visuals**: Polished the graphical interface for Rofi widgets to match the transparent Catppuccin Hyprland aesthetics without background artifacts.
- **Git & History**: Cleaned up the repository history using strict `--no-ff` merge policies and removed duplicated codebase audit changelogs.

---

## [v1.5.1] - The Final Polish (2026-03-08)

Minor bugfixes and code quality enforcement following the v1.5.0 milestone.

### 🟡 Bug Fixes
- **VM Compatibility (`health-check`)**: The GPU driver section no longer produces zero output on Headless/VMs lacking PCI GPUs; it now explicitly warns "No GPU detected".
- **Dotfile Deployment**: `deploy_dotfile()` now tracks failures via `DOTFILE_FAILURES` counter and returns `1` if a source file is missing, enabling callers to detect partial deployments.
- **Dynamic CI Validation**: Replaced the hardcoded '150+' stale check in CI with a dynamic pipeline that counts actual entries in `guide.sh` and validates all repository documentation limits against it.
- **Global LF Enforcement**: Fixed an irony where `.editorconfig`, `README.md`, and 30 other files had CRLF line endings. Converted all 32 files to LF and added a strict `* text=auto eol=lf` rule to `.gitattributes` to permanently prevent CRLF cross-platform issues.

---

## [v1.5.0] - The Perfect Score (2026-03-08)

Final 11 audit items resolved. **All 53+ findings from both internal and external audits are now fixed.** Audit score: **10/10**.

### 🔴 Critical Fixes
- **Antigravity Install**: Rewrote with verified approach — AUR → .deb extract → cursor-bin fallback. Removed all invalid npm/AUR packages
- **Installer `--all`**: Now routes through `run_modules()` with progress display, logging, and summary screen

### 🟡 Bug Fixes
- **SSH Key Security**: Interactive passphrase prompt (no more empty `-N ""` by default)
- **Android PATH**: Persisted directly in Module 05's `.zshrc` (no longer requires Module 06 first)
- **Theme Switcher**: Post-sed verification — only shows success notification if config files actually changed
- **Secure Boot MOK**: Explicit user confirmation before generating cryptographic signing keys

### 📝 Documentation Fixes
- `installation.md`: Clone path corrected (`~/Desktop/` → `~/.cache/`)
- `troubleshooting.md`: Removed non-existent `--cli` flag; added real TTY restore instructions
- `ai-tools.md`: Antigravity description updated to be accurate and verifiable

### 🔧 Code Quality
- `app-store.sh`: Documented `declare -n` bash 4.3+ requirement
- `health-check.sh`: Documented intentional `set -uo` (no `-e`) design decision

---

## [v1.4.0] - The External Audit Sweep (2026-03-07)

All 23 findings from the comprehensive external DOCX audit have been resolved. 16 files modified.

### 🔴 Critical Fixes
- **Time Machine**: Fixed tilde expansion bug — config restore always failed silently because `~` was not expanded to `$HOME` in the file path
- **VM Module**: `$VM_POOL` variable moved before first use (was empty in hugepages messages)
- **Cleanup Service**: Removed redundant `sudo` from root-owned systemd service; added explicit `User=root`

### 🟡 Bug Fixes
- **Roblox Duplicate**: Removed duplicate Sober/Roblox install from Module 10 (kept in Module 11 Gaming)
- **chsh Safety**: Now verifies `/etc/shells` contains zsh before calling `chsh`
- **fnm PATH Race**: Added `hash -r` + `command -v` guard after fnm install
- **Credential Leak Prevention**: Expanded dotfiles-sync `.gitignore` with `gnupg/`, `**/token*`, `**/secret*`, `**/*.key` patterns
- **Error Propagation**: Added `set -euo pipefail` to all 9 modules (01-09) that were missing it

### 📝 Documentation & Cleanup
- Fixed THP description (`Disables` → `Sets to madvise`) in modules.md
- Fixed Nexus path reference (`~/.local/bin` → `/usr/local/bin`) in modules.md
- Fixed ecosystem tool count (5 → 7) in modules.md
- Removed dead `status_icon()` function from nexus.sh

---

## [v1.3.0] - The Bulletproof Audit (2026-03-07)

Deep line-by-line audit of every file in the repository. 30 findings fixed across 17 files.

### 🔴 Critical Fixes
- **CI Pipeline**: Downgraded `actions/checkout@v6` → `@v4` (v6 doesn't exist yet)
- **CI Pipeline**: Fixed stale `nexus.sh` path → `ecosystem/nexus.sh`
- **VitePress**: Fixed `package.json` paths (`docs` → `.` since it lives inside `docs/`)
- **Pacman Hook**: Unified hook filename between install (`99-cachy-health.hook`) and uninstall scripts

### 🟡 Bug Fixes
- **NVIDIA**: `mkinitcpio` MODULES injection now guarded against duplication on re-run
- **AI Tuner**: 3-layer fallback — checks binary → service → model before querying Ollama
- **Hyprland**: Fixed `Super+X` Nexus keybind path (`~/.local/bin` → `/usr/local/bin`)
- **Zshrc**: Cross-module dependencies (`fnm`, `zoxide`, `direnv`) now wrapped in `command -v` guards
- **Dotfiles**: `safe_config()` now called before overwriting `.zshrc`, `kitty.conf`, `starship.toml`

### 🟠 Improvements
- **KDE/Hyprland**: Portal conflict resolution — `xdg-desktop-portal-kde` auto-removed when Hyprland is installed
- **Zram**: Compression algorithm change skipped when device is actively in use
- **VM Hugepages**: No longer permanently reserved globally (use per-VM in libvirt XML instead)
- **Theme Switcher**: Dunst urgency-level color distinction preserved during theme changes
- **Waybar**: Removed Google Fonts `@import` (uses locally installed Inter instead — works offline)

### 📝 Documentation & Consistency
- Fixed stale MODULE comments in `04-dev.sh` and `06-dotfiles.sh`
- README tool count corrected (6 → 7), tree updated with `Makefile`, `uninstall.sh`, `.githooks/`
- `release.yml` now auto-generates release notes as fallback for empty changelog body
- Antigravity fallback branding made consistent
- Makefile lint target now excludes `node_modules/`
- `.gitignore` updated with VitePress `dist/` and `cache/`

---

## [v1.2.0] - The Legendary Polish Update (2026-03-07)

This massive update focuses on bringing absolute enterprise repository cleanliness, native Linux development standards, and world-class documentation to the ecosystem.

### ✨ New Features

- **Official VitePress Documentation Site**: Built a highly comprehensive, Catppuccin-themed static website hosted automatically via GitHub Actions (Pages). Explains the deep architecture of the `safe_config` paradigm, troubleshooting flows, and AI local model usage.
- **Native Development `Makefile`**: Implemented a `Makefile` making routine interactions universally standard (e.g. `make install`, `make uninstall`, `make lint`, `make init`).
- **Git Pre-Commit Hooks**: Added `.githooks/pre-commit` to automatically block commits utilizing ShellCheck if Bash syntax errors are detected locally, guaranteeing 100% CI pipeline purity.

### ♻️ Architecture Reforms

- **Root Directory Cleanup**: Moved all standard GitHub health files (`SECURITY.md`, `CONTRIBUTING.md`, etc.) to the `.github/` folder.
- **Ecosystem UI Isolation**: Migrated `nexus.sh` and `guide.sh` out of the root project into their native `ecosystem/` folder to achieve maximum repository cleanliness.
- **Node Isolation**: Encapsulated `package.json` and `pnpm-lock.yaml` entirely within the `/docs` routing tree to separate web components from core Linux scripting.

---

## [v1.1.0] - The Enterprise God-Tier Update (2026-03-07)

This release implements three highly requested enterprise-tier features, completing the transition of this project into a top-tier open-source repository format.

### ✨ New Features

- **Automated GitHub Releases (CI/CD)**: Added `.github/workflows/release.yml`. Pushing a semantic version tag (e.g., `v1.1.0`) now automatically triggers a GitHub Actions workflow that zips the repository, auto-generates a changelog from commits, and publishes an official GitHub Release.
- **The Ultimate Uninstaller (`uninstall.sh`)**: Added a graceful uninstall script. Running `./uninstall.sh` safely removes the Nexus command center, Guide CLI, ecosystem tools from `/usr/local/bin`, deletes GUI themes, removes Pacman hooks, and restores default Hyprland configurations without touching your personal files or un-installing essential system packages.
- **Bilingual TUI Installer (EN/ID)**: The TUI installer (`setup.sh` / `installer.sh`) now features a language selection dialog on launch. Choosing English or Bahasa Indonesia dynamically translates all ensuing setup menus, warnings, progress bars, and completion summaries natively.

---

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
