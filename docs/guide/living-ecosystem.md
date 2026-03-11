# 🌍 The Living Ecosystem

The true differentiator of the CachyOS Workstation Setup is its transition from a static "run once and forget" script into a perpetually aware **Living Ecosystem**. 

Located primarily in `/usr/local/bin/nexus`, the ecosystem consists of interconnected tools accessible directly from the Nexus (`Super+X`) or via the command line interface (e.g., `nexus doctor`, `nexus sync`).

---

## 🎨 Dynamic Theming Engine (`nexus theme`)

Unlike static dotfiles that lock you into one visual style, the Dynamic Theming Engine (now powered by a Bubbletea Live Preview UI) allows for instantaneous holistic color adjustments without restarting your graphical session.

* **Supported Themes**: Catppuccin (Mocha, Macchiato, Frappe, Latte), Dracula, Tokyo Night, Rosé Pine.
* **Mechanism**: Using `sed`, it sweeps through your `waybar/style.css`, `kitty/kitty.conf`, `rofi/colors.rasi`, and `hypr/hyprland.conf` simultaneously, replacing generic color variables native to the ecosystem.
* **Reloading**: It surgically triggers `killall -SIGUSR2 waybar` and `hyprctl reload` to apply visual changes smoothly in under a second.

---

## 🛡️ Time Machine (`nexus rollback`)

Based on our strict snapshotting logic in `internal/state`, **Time Machine** is a UI implemented natively in Go to list and recover configurations.

* Every time any of the 15 modules runs and edits a configuration file in `~/.config`, it first copies the existing file to `~/.config-backup/YYYYMMDD-HHMMSS/relative__path__file.ext`.
* The **Time Machine** lists these timestamped snapshots visually.
* When selected, the user can choose to revert a single file (like a botched `hyprland.conf`) or rollback the entire snapshot natively.

---

## ☁️ Dotfiles Cloud Sync (`nexus sync`)

Provides effortless disaster recovery off-disk.

Instead of writing complex symlinking scripts (like `stow`), `dotfiles-sync` takes the raw approach:
* Automatically creates an external local git repository.
* Connects it to an origin URL provided by the user.
* Implements an intelligent, tailor-made `.gitignore` to skip large, unneeded cache directories native to Linux (e.g., `~/.config/op`, `~/.config/discord/Cache`).
* Can be run manually from Nexus, or set to a cron job.

---

## 🧠 AI Auto-Tuner (`nexus tuner`)

The most advanced local observability tool.

The `ai-tuner` is a utility spawned by `nexus doctor` that runs non-disruptive telemetry commands like `vmstat`, `free -h`, `df -h`, and `top -b -n 1`. It then constructs a strict system engineering prompt.
This prompt is fired via standard `curl` locally to `http://127.0.0.1:11434/api/generate` pointing directly to `qwen2.5-coder:7b`.
The resulting output is parsed and presented via Rofi, giving the user intelligent, contextual recommendations for `sysctl` value changes, OOM threshold warnings, or caching inefficiencies.

---

## 🏪 Terminal App Store (`nexus apps`)

Terminals are fast, but hunting down the correct package suffix for an obscure icon theme isn't.

The App Store provides a heavily curated, 3-tier Rofi menu.
1. The user selects a category (e.g., "Design Tools").
2. The user sees a list (e.g., "Figma-Linux", "GIMP", "Krita").
3. Once selected, a floating terminal executes the requisite `pacman` or `paru` command depending on where the ideal package actually lives.

*(Note: Users can add their own software into the app store safely by editing `~/.config/app-store-custom.conf`).*

---

## 🩺 System Health Check (`nexus doctor`)

Bridges the gap between Arch Linux's rolling nature and stability.

The Health Check is hardwired into Pacman Hooks. If an update involves the linux kernel, NVIDIA packages, Hyprland, or Waybar, `pacman` triggers this executable.
The script validates:
* GRUB boot parameters.
* Proper syntax parsing of new window manager configs.
* Mount checks (read/write statuses).

If the check fails during array modifications, it warns the user immediately *before* they reboot, allowing them to use Time Machine to circumvent blackscreens.
