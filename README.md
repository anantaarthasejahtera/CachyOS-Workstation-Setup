<p align="center">
  <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/logos/exports/1544x1544_circle.png" width="100" alt="Catppuccin Logo"/>
</p>

<h1 align="center">🚀 CachyOS Workstation Setup</h1>

<p align="center">
  <strong>Modular, aesthetic, fully-configurable CachyOS development workstation installer.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/CachyOS-Arch%20Based-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white" alt="CachyOS"/>
  <img src="https://img.shields.io/badge/Theme-Catppuccin%20Mocha-cba6f7?style=for-the-badge" alt="Catppuccin"/>
  <img src="https://img.shields.io/badge/Modules-14-a6e3a1?style=for-the-badge" alt="Modules"/>
  <img src="https://img.shields.io/badge/Tools-50+-89b4fa?style=for-the-badge" alt="Tools"/>
  <img src="https://img.shields.io/badge/License-MIT-f9e2af?style=for-the-badge" alt="License"/>
</p>

---

## ✨ Overview

A **modular installer** that transforms a fresh CachyOS installation into a fully configured, aesthetically stunning developer workstation. Features a **TUI (Terminal UI) module selector** — choose exactly what you need, skip what you don't.

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
dekstop/
├── setup.sh                  # Main entry point (edit config here)
├── installer.sh              # TUI installer (dialog-based)
├── nexus.sh                  # Nexus Command Center (Super+X popup)
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
│   └── 14-nexus-guide.sh     # Nexus install + Guide system
├── cachy-setup.sh            # Legacy monolith (kept for reference)
├── README.md
├── LICENSE
└── .gitignore
```

### Module Details

| # | Module | Size | Key Tools |
|---|--------|------|-----------|
| 01 | Base & GPU | ~2 GB | GPU auto-detect, paru, base-devel |
| 02 | Kernel | ~0 MB | sysctl tuning, NVMe, THP, GuC/HuC |
| 03 | Security | ~50 MB | UFW, SSH key, Cloudflare DNS, Zram |
| 04 | Dev Tools | ~4 GB | Docker, Node/fnm, Python/uv, Rust, Go |
| 05 | Mobile | ~5 GB | Flutter, Android SDK, Kotlin, JDK 17 |
| 06 | Dotfiles | ~100 MB | Kitty, Zsh, Starship, fzf, bottom |
| 07 | Editors | ~700 MB | Antigravity, Neovim (lazy.nvim) |
| 08 | Desktop | ~300 MB | KDE Catppuccin, GRUB theme, fonts |
| 09 | Hyprland | ~200 MB | Tiling WM, keybinds, Rofi, lock screen |
| 10 | Apps | ~500 MB | Zen Browser, tmux, Flatpak apps |
| 11 | Gaming | ~3 GB | Steam, PCSX2, Minecraft, Roblox |
| 12 | VM | ~2 GB | QEMU/KVM, Bottles, LibreOffice |
| 13 | Waybar | ~5 MB | Status bar + glass CSS |
| 14 | Nexus | ~1 MB | Command Center + 130-entry Guide |

---

## 🎮 Nexus Command Center

Press **`Super+X`** for an instant popup with 35+ actions:

```
╭── 🔍 Nexus ──────────────────────────────╮
│  Search...                                │
│                                           │
│    System Update                         │
│    Screenshot (Region)                   │
│  󰧑  AI Chat (Reasoning)                  │
│    Antigravity                           │
│    VM Manager                            │
│  ...                                      │
╰───────────────────────────────────────────╯
```

## 📖 Guide System

```bash
guide              # Interactive fzf search
guide docker       # Docker commands
guide flutter      # Flutter commands  
guide hyprland     # Keyboard shortcuts
guide ai           # Ollama commands
```

---

## ⌨️ Key Shortcuts

| Shortcut | Action |
|----------|--------|
| `Super + X` | **Nexus Command Center** |
| `Super + Return` | Terminal (Kitty) |
| `Super + D` | App launcher (Rofi) |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + L` | Lock screen |
| `Super + /` | Keybind cheatsheet |
| `Super + Shift + S` | Screenshot (region) |

---

## 🔧 Configuration

Each module sources `modules/00-common.sh` which provides:

- **Idempotent configs**: Existing configs backed up to `~/.config-backup/` before overwriting
- **Smart installs**: Packages checked before install (no reinstalling)
- **Logging**: Everything logged to `~/cachy-setup.log`
- **Run individual modules**: `bash modules/04-dev.sh` (test one module)

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
