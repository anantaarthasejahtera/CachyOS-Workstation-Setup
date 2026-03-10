# 🎮 Nexus Command Center

Nexus is the beating heart of your CachyOS Workstation Ecosystem. 

Activated instantly with **`Super+X`**, it replaces traditional application menus with a highly context-aware, resource-efficient dashboard.

## Overview

Unlike standard launchers (like `rofi -show drun` which we map to `Super+D`), the Nexus Command Center is broken down into specific operational categories:

* **Header Stats**: Live readouts of Battery %, RAM consumption, and Free Disk Space.
* **System Actions**: 1-click updates (`pacman`), cache cleanups.
* **Smart Recording**: Auto-detects if `wf-recorder` is running to replace the "Record" option with a red "Stop Recording" button.
* **AI & DevOps**: Direct shortcuts to local Ollama inference models (`qwen3` and `deepseek`), Docker manager, and VM manager.
* **Living Ecosystem**: Launch points for the App Store, Theme Switcher, Health Check, Dotfiles Sync, and Time Machine config rollback.

## Customization

The Nexus script is deployed to `/usr/local/bin/nexus` by Module 14 (`modules/14-nexus-guide.sh`). The source lives in `ecosystem/nexus.sh`.

To add your own custom actions, edit `ecosystem/nexus.sh` in the cloned repository and re-run Module 14, or run:

```bash
# Re-deploy just the Nexus and Guide
bash modules/14-nexus-guide.sh
```
