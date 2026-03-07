# 🏗️ Architecture & Philosophy

The CachyOS Workstation Setup isn't just a string of unorganized bash commands. It is engineered with software design patterns normally reserved for immutable operating systems and Configuration Management tools (like Ansible or Chef).

## The Core Philosophy

1. **Idempotency**: A script should be able to run 100 times without duplicating entries, breaking configurations, or crashing the system.
2. **Modularity**: Users must have the right to veto any tool. Monolithic installation scripts assume too much about the developer.
3. **Observability**: A rolling-release Linux distribution naturally introduces entropy. Mechanisms must exist to constantly audit the health of the system.

## The `00-common.sh` Library

If you inspect `/modules/00-common.sh`, you will find the architectural DNA of the project.

### The `safe_config` Macro
Rather than blindly `cp`ing files into `~/.config`, our scripts use `safe_config`.
```bash
safe_config "waybar" "style.css"
```
Behind the scenes, this creates a rigorous, timestamped snapshot of the target directory (`~/.config-backup/YYYYMMDD-HHMM/waybar__style.css`) before the symlink or file copy occurs. 
This is what enables the **Config Rollback (Time Machine)** UI via Rofi to map file dependencies globally across your setup.

### The Application State File
Rather than querying `pacman -Qs` repeatedly, the system creates version signatures inside `~/.config/cachy-setup/`.
This prevents the UI from trying to run large modular downloads over and over.

## The Pacman Hook Architecture

One of our flagship enterprise features is bridging `/etc/pacman.d/hooks` with our user-space Bash scripts.

Arch Linux provides extreme bleeding-edge kernel updates. Sometimes, an NVIDIA DKMS module or a Hyprland `wlroots` update can cause black screens on reboot.
By injecting `99-cachy-health.hook`, we intercept the completion of `pacman -Syu`. 

The hook forcefully executes `health-check`, scanning for:
1. Hyprland syntax errors (new updates sometimes deprecate old syntax).
2. Missing kernel modules (failed DKMS builds).
3. Free storage issues that might corrupt the bootloader.

This design proactively shifts the developer from dealing with a "broken boot state" to resolving a "clearly highlighted config error right inside the terminal."

## The "Living Ecosystem" Concept

Most dotfile repositories are "Dead Artefacts" — they capture a user's configuration exactly as it existed on one Tuesday afternoon in 2023.
We reject this model entirely. 

By injecting binaries directly into `/usr/local/bin/` (e.g. `theme-switch`, `config-rollback`, `ai-tuner`) and hooking them up to an overlay dashboard (Nexus), we provide dynamic manipulation *primitives*. You don't just consume the dotfiles; you use tools that change your system safely over time.
