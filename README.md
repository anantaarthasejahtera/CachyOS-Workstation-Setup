<p align="center">
  <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/logos/exports/1544x1544_circle.png" width="100" alt="Catppuccin Logo"/>
</p>

<h1 align="center">🚀 CachyOS Workstation Setup</h1>

<p align="center">
  <strong>Modular, aesthetic, bilingual CachyOS development workstation installer.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/CachyOS-Arch%20Based-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white" alt="CachyOS"/>
  <img src="https://img.shields.io/badge/Theme-Catppuccin%20Mocha-cba6f7?style=for-the-badge" alt="Catppuccin"/>
  <img src="https://img.shields.io/badge/Modules-14-a6e3a1?style=for-the-badge" alt="Modules"/>
  <img src="https://img.shields.io/badge/Tools-50+-89b4fa?style=for-the-badge" alt="Tools"/>
  <img src="https://img.shields.io/badge/Guide-150+%20entries-f5c2e7?style=for-the-badge" alt="Guide"/>
  <img src="https://img.shields.io/badge/Language-EN%20%7C%20ID-f9e2af?style=for-the-badge" alt="Bilingual"/>
  <img src="https://img.shields.io/badge/License-MIT-f9e2af?style=for-the-badge" alt="License"/>
</p>

---

## ✨ Overview

A **modular installer** that transforms a fresh CachyOS installation into a fully configured, aesthetically stunning developer workstation. Features:

- **TUI installer** — Catppuccin-themed module selector with progress bars
- **Nexus v2** — Smart command center popup with live system stats
- **Guide v3** — 150+ searchable entries, executable, bilingual (EN/ID)
- **14 modules** — each independently runnable
- **50+ tools** — dev, AI, gaming, VM, productivity

### 🎯 Who Is This For?

| 🧑‍💻 Developers | 🎓 Students | 🎮 Gamers | 🧪 Tinkerers |
|:---:|:---:|:---:|:---:|
| Full-stack dev env | Free tools | Linux gaming | Learn Linux |
| 5 languages + Docker | No expensive software | Steam + emulators | Pre-configured |
| AI coding assistants | Mobile dev (Flutter) | MangoHud FPS overlay | Catppuccin everything |

---

## 📦 Quick Start

```bash
# Clone
git clone https://github.com/rixzkiye/CachyOS-Workstation-Setup.git
cd CachyOS-Workstation-Setup

# Edit your identity
nano setup.sh
# Change: GIT_NAME="Your Name"
# Change: GIT_EMAIL="your@email.com"

# Run (interactive module selector)
chmod +x setup.sh
./setup.sh

# Or install everything at once
./setup.sh --all
```

### TUI Module Selector

When you run `./setup.sh`, a Catppuccin-themed TUI appears:

```
╔══════════════════════════════════════════════════════╗
║  📦 Select Modules                                  ║
╠══════════════════════════════════════════════════════╣
║  [x] 01  Base & GPU Drivers         [~2 GB]         ║
║  [x] 02  Kernel & Performance       [~0 MB]         ║
║  [x] 03  Security & Maintenance     [~50 MB]        ║
║  [x] 04  Dev Tools (Node,Py,Rust)   [~4 GB]         ║
║  [x] 05  Mobile Dev (Flutter)       [~5 GB]         ║
║  [x] 06  Shell & Dotfiles           [~100 MB]       ║
║  [x] 07  Editors (Antigravity)      [~700 MB]       ║
║  [x] 08  Desktop Theme (KDE)        [~300 MB]       ║
║  [x] 09  Hyprland WM                [~200 MB]       ║
║  [x] 10  Extra Apps                 [~500 MB]       ║
║  [ ] 11  Gaming (Steam, PCSX2)      [~3 GB]         ║
║  [ ] 12  Windows VM & Bottles       [~2 GB]         ║
║  [x] 13  Waybar Status Bar          [~5 MB]         ║
║  [x] 14  Nexus & Guide              [~1 MB]         ║
║                                                      ║
║  Space = toggle  ·  Enter = confirm                  ║
╚══════════════════════════════════════════════════════╝
```

---

## 🏗️ Project Structure

```
CachyOS-Workstation-Setup/
├── setup.sh                  # Main entry point (edit config here)
├── installer.sh              # TUI installer (dialog-based)
├── nexus.sh                  # Nexus v2 Command Center (Super+X)
├── guide.sh                  # Guide v3 — bilingual reference (EN/ID)
├── modules/
│   ├── 00-common.sh          # Shared functions & helpers
│   ├── 01-base.sh            # GPU auto-detect, paru, makepkg
│   ├── 02-kernel.sh          # sysctl, NVMe, THP, Zram
│   ├── 03-security.sh        # UFW, SSH key, DNS, auto-cleanup
│   ├── 04-dev.sh             # Docker, Node, Python, Rust, Go
│   ├── 05-mobile.sh          # Flutter, Android SDK, Kotlin
│   ├── 06-dotfiles.sh        # Kitty, Zsh, Starship, fzf
│   ├── 07-editors.sh         # Antigravity, Neovim
│   ├── 08-desktop.sh         # KDE Catppuccin, GRUB theme
│   ├── 09-hyprland.sh        # WM config, keybinds, lock screen
│   ├── 10-apps.sh            # Browser, tmux, Flatpak, Bluetooth
│   ├── 11-gaming.sh          # Steam, PCSX2, Minecraft, MangoHud
│   ├── 12-vm.sh              # QEMU/KVM, Bottles, LibreOffice
│   ├── 13-waybar.sh          # Status bar config + CSS
│   └── 14-nexus-guide.sh     # Installs Nexus + Guide
├── README.md
├── LICENSE
└── .gitignore
```

### Module Details

| # | Module | Size | Key Tools |
|---|--------|------|-----------|
| 01 | Base & GPU | ~2 GB | GPU auto-detect (Intel/AMD/NVIDIA), paru, base-devel |
| 02 | Kernel | ~0 MB | sysctl tuning, NVMe optimization, THP, GuC/HuC |
| 03 | Security | ~50 MB | UFW, SSH key (ed25519), Cloudflare DNS, Zram, Timeshift |
| 04 | Dev Tools | ~4 GB | Docker, Node/fnm/pnpm, Python/uv, Rust, Go, CLI power tools |
| 05 | Mobile | ~5 GB | Flutter, Android SDK (API 34), Kotlin, JDK 17, scrcpy |
| 06 | Dotfiles | ~100 MB | Kitty, Zsh/Oh-My-Zsh, Starship prompt, fzf-tab |
| 07 | Editors | ~700 MB | Antigravity (AI VS Code), Neovim (lazy.nvim) |
| 08 | Desktop | ~300 MB | KDE Catppuccin theme, GRUB theme, Inter + Nerd Fonts |
| 09 | Hyprland | ~200 MB | Tiling WM, keybinds, Rofi, Hyprlock, Hypridle |
| 10 | Apps | ~500 MB | Zen Browser, tmux, Spotify/Telegram/Discord (Flatpak) |
| 11 | Gaming | ~3 GB | Steam (Proton), PCSX2, PrismLauncher, Roblox, MangoHud |
| 12 | VM | ~2 GB | QEMU/KVM (hugepages, CPU pinning), Bottles, LibreOffice |
| 13 | Waybar | ~5 MB | Glassmorphism status bar with gradient CSS |
| 14 | Nexus + Guide | ~1 MB | Smart command center + 150-entry bilingual guide |

---

## 🎮 Nexus v2 — Command Center

Press **`Super+X`** for a smart popup with **live system stats**:

```
╭── 🔍 Nexus ───────────────────────────────────╮
│  Super+X · 󰁹 87% · 󰍛 4.2/16GB               │
│────────────────────────────────────────────────│
│  ── 󰁹 87%  │  󰍛 4.2/16GB  │  󰋊 420G free ── │
│  ────────────────────────────────────────────  │
│    System Update (pacman + flatpak)           │
│    Cleanup Packages & Cache                   │
│  ────────────────────────────────────────────  │
│    Screenshot — Region                        │
│    Record Screen (or ⏹ Stop if recording)     │
│  ────────────────────────────────────────────  │
│  󰧑  AI Chat — Reasoning (qwen3) 🟢           │
│    Docker Manager 🟢                          │
│    VM Manager 🔴                              │
│  ────────────────────────────────────────────  │
│    Guide Popup (150+ entries)                 │
╰────────────────────────────────────────────────╯
```

### Nexus Features

| Feature | Description |
|---------|-------------|
| **Live system stats** | Battery %, RAM usage, disk free, CPU temp in header |
| **Smart recording** | Auto-detects if recording → shows Stop instead of Record |
| **Service status** | 🟢/🔴 indicators for Docker, Ollama, VMs |
| **Dynamic detection** | Only shows apps that are actually installed |
| **35+ actions** | Quick actions, AI, dev tools, apps, gaming, system |
| **Zero RAM idle** | Only runs when invoked |

---

## 📖 Guide v3 — Bilingual Reference

```bash
# Interactive mode (fzf + preview pane + executable)
guide

# Filter by keyword
guide docker       # Docker commands
guide flutter      # Flutter commands
guide hyprland     # Keyboard shortcuts
guide ai           # Ollama commands

# Popup mode (rofi, integrated with Nexus)
guide --popup

# Online reference (cheat.sh)
guide --web tar

# Switch language
guide --lang id    # 🇮🇩 Bahasa Indonesia
guide --lang en    # 🇬🇧 English
```

### Guide Features

| Feature | Description |
|---------|-------------|
| **150+ entries** | 15 categories (hyprland, shell, git, docker, node, python, rust, go, flutter, editor, ai, gaming, vm, apps, system) |
| **Executable** | Press Enter on any ▶ entry to run the command directly |
| **Preview pane** | fzf right panel shows detailed explanation + examples |
| **Bilingual** | Full English and Indonesian translations (auto-detected from locale) |
| **Popup mode** | Rofi popup via `guide --popup` or from Nexus |
| **cheat.sh** | Online fallback via `guide --web <topic>` |
| **Language persist** | Choice saved to `~/.config/guide-lang` |

### Example (Bahasa Indonesia)

```
━━━ Guide: docker ━━━  [bahasa: Indonesia]

  [docker] ▶ docker ps
         → Daftar container berjalan
         Tampilkan container berjalan dengan port, nama, status

  [docker] ▶ lazydocker
         → Manajer Docker TUI
         UI terminal cantik: container, image, volume, log
```

---

## ⌨️ Key Shortcuts

| Shortcut | Action |
|----------|--------|
| `Super + X` | **Nexus Command Center** (smart popup) |
| `Super + Return` | Terminal (Kitty) |
| `Super + D` | App launcher (Rofi) |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + L` | Lock screen (Hyprlock) |
| `Super + E` | File manager (Thunar) |
| `Super + V` | Clipboard history |
| `Super + /` | Keybind cheatsheet |
| `Super + Shift+S` | Screenshot (region) |
| `Super + 1-9` | Switch workspace |

---

## 🤖 AI Tools Included

| Model | Purpose | RAM | Command |
|-------|---------|-----|---------|
| `qwen3:30b-a3b` | Reasoning, debate, philosophy | ~16GB | `ollama run qwen3:30b-a3b` |
| `deepseek-r1:7b` | Math & logic | ~5GB | `ollama run deepseek-r1:7b` |
| `qwen2.5-coder:7b` | Code generation & refactoring | ~5GB | `ollama run qwen2.5-coder:7b` |

All accessible via **Nexus** → AI section, or terminal `ollama run <model>`.

---

## 🔧 Configuration

Each module sources `modules/00-common.sh` which provides:

- **Idempotent configs** — Existing configs backed up to `~/.config-backup/` before overwriting
- **Smart installs** — Packages checked before install (no reinstalling)
- **Logging** — Everything logged to `~/cachy-setup.log`
- **Run individual modules** — `bash modules/04-dev.sh` (test one module)

---

## 🤝 Contributing

```bash
git checkout -b feature/your-idea
# Edit any module in modules/
git commit -m "feat: add your awesome feature"
git push origin feature/your-idea
# Open a Pull Request
```

Each module is **independent** — you can edit one without touching others.

---

## 📄 License

MIT — see [LICENSE](LICENSE).

---

<p align="center">
  <sub>Built with ❤️ and obsessive attention to aesthetics</sub><br/>
  <sub><a href="https://github.com/catppuccin/catppuccin">Catppuccin</a> · <a href="https://cachyos.org">CachyOS</a> · <a href="https://hyprland.org">Hyprland</a></sub>
</p>
