# Changelog

All notable changes to this project are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- **Architecture diagram** (Mermaid) in README showing full system flow
- **INSTALL_GUIDE.md** — step-by-step CachyOS install and partition guide
- **CONTRIBUTING.md** — coding conventions, testing, commit standards
- **SECURITY.md** — vulnerability reporting process and security policy
- **CODE_OF_CONDUCT.md** — Contributor Covenant v2.1
- **CHANGELOG.md** — this file
- **System Health Check** (`ecosystem/health-check.sh`) — 8-category post-update validator
- **Pacman hook** — auto-runs health check after kernel/WM/NVIDIA updates
- **Nexus: Health Check entry** — accessible via Super+X
- **Guide: health-check entry** — bilingual ecosystem entry
- **Post-install wizard** (`ecosystem/post-install.sh`) — first-boot configuration via Rofi
- **Module dependency checker** — TUI warns about required module pairings
- **Module versioning** — skip re-runs of unchanged modules
- **Dry-run mode** (`setup.sh --dry-run`) — preview what will be installed
- **Custom app store** — user-defined apps via `~/.config/app-store-custom.conf`
- **Nexus: System Dashboard** — quick system info view
- **PCSX2 bios directory** — auto-created `~/.config/PCSX2/bios/`

### Changed
- **06-dotfiles.sh** — removed 460+ duplicate lines (MODULE 5/6/7 copy-paste + Neovim/VS Code)
- **07-editors.sh** — now consolidated: Antigravity + VS Code config + Neovim + Ollama
- **14-nexus-guide.sh** — install path moved from `~/.local/bin` to `/usr/local/bin`
- **15-ecosystem.sh** — install path moved from `~/.local/bin` to `/usr/local/bin`
- **nexus.sh** — dispatch uses direct commands instead of hardcoded paths
- **guide.sh** — PCSX2 entry updated to "GPU-aware config", ecosystem header updated
- **README** — rolling release section reframed as "Resilience", numbers synced

### Fixed
- **Duplicate aliases** in `.zshrc` (`update`, `cleanup`, `ff`, `keys`) — second block removed
- **Pacman hook root PATH** — health-check now in `/usr/local/bin/` (root-accessible)
- **Guide v2 typo** → corrected to Guide v3 in `14-nexus-guide.sh`
- **PCSX2 bios directory** — now auto-created by `11-gaming.sh`
