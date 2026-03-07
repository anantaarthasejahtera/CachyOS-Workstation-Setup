# 🎮 Nexus Command Center

Nexus is the beating heart of your CachyOS Workstation Ecosystem. 

Activated instantly with **`Super+X`**, it replaces traditional application menus with a highly context-aware, resource-efficient dashboard.

## Overview

Unlike standard launchers (like `rofi -show drun` which we map to `Super+D`), the Nexus Command Center is broken down into specific operational categories:

* **Header Stats**: Live readouts of Battery %, RAM consumption, and Free Disk Space.
* **System Actions**: 1-click updates (`pacman` + `flatpak`), cache cleanups.
* **Smart Recording**: Auto-detects if `wf-recorder` is running to replace the "Record" option with a red "Stop Recording" button.
* **AI & DevOps**: Direct shortcuts to local Ollama inference models (`qwen3` and `deepseek`), Docker manager, and VM manager.
* **Living Ecosystem**: Launch points for the App Store, Theme Switcher, Health Check, Dotfiles Sync, and Time Machine config rollback.

## Customization

The script driving the UI can be found at `modules/14-nexus-guide.sh` (which generates `~/.local/bin/nexus` or `/usr/local/bin/nexus`). 

To add your own custom scripts, modify the `nexus.sh` generator in your cloned repository and run `make install-all` (or run `./setup.sh` and select only Module 14).
