# ⌨️ Master Cheat Sheet

Efficiency in a window manager ecosystem requires muscle memory. This page documents the definitive keybinds and aliases configured by the Workstation Setup.

## 🚀 Hyprland Core Keybinds

The `SUPER` key (Windows/Cmd key) acts as your primary modifier.

| Action | Shortcut | Description |
|--------|----------|-------------|
| **Launch Terminal** | `SUPER + Enter` | Opens Kitty (GPU Accelerated) |
| **App Launcher** | `SUPER + D` | Opens Rofi application menu |
| **Nexus Command Center**| `SUPER + X` | The heart of the living ecosystem |
| **Close Window** | `SUPER + Q` | Kills the active window (`hyprctl dispatch killactive`) |
| **Toggle Floating** | `SUPER + V` | Switches a tiled window to floating / dragging mode |
| **Toggle Fullscreen**| `SUPER + F` | Makes active window fullscreen without borders |

## 🪟 Workspace Management

| Action | Shortcut |
|--------|----------|
| **Switch Workspace** | `SUPER + [1-9]` |
| **Move Window to Workspace** | `SUPER + SHIFT + [1-9]` |
| **Move Focus** | `SUPER + [Left/Right/Up/Down]` |
| **Scroll Workspaces** | `SUPER + Mouse Scroll` |

## 🛠️ Utility Keybinds

| Action | Shortcut | Description |
|--------|----------|-------------|
| **Screen Locker** | `SUPER + L` | Locks session with Hyprlock |
| **File Manager** | `SUPER + E` | Opens Thunar |
| **Screenshot (Region)**| `SUPER + SHIFT + S` | Captures a rectangular region via `grimblast` to clipboard |
| **Screenshot (Full)** | `PrintScreen` | Captures all monitors to `~/Pictures/Screenshots` |
| **Clipboard History** | `SUPER + C` | Opens Rofi clipboard manager (`cliphist`) |

## 💻 Terminal Aliases (`.zshrc`)

| Command | Alias Equivalent | Purpose |
|---------|------------------|---------|
| `ls -la` | `ll` | Detailed list output |
| `git status` | `gs` | Fast git checking |
| `git add .` | `ga.` | Stage all files |
| `sudo pacman -Syu`| `update` | Standard system update |
| `clear` | `cls` | Clears terminal screen |

## 🧠 AI Commands (Ollama)

| Model Target | Terminal Command | Use Case |
|--------------|------------------|----------|
| Qwen 30B (MoE) | `ollama run qwen3:30b-a3b` | General massive logic/chatting |
| DeepSeek-R1 | `ollama run deepseek-r1:7b`| Mathematics / Chain of Thought |
| Qwen Coder | `ollama run qwen2.5-coder:7b`| Bash scripting / programming generation |
