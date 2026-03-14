# 🔧 Configuration & Customization

The CachyOS Workstation Setup is designed to be fully modular and customizable. While our default scripts enforce a strict Catppuccin Mocha aesthetic and optimized functional layout, you have complete freedom to override settings locally.

## The `safe_config` Paradigm

Every module utilizes the `safe_config()` macro to copy existing configurations from `~/.config/` into `~/.config-backup/` with a timestamp before overwriting them. 
This means you can freely test customizations. If you break something, you can restore it instantly using the **Time Machine Rollback** in Nexus.

## Customizing The App Store

Our GUI App Store (`nexus apps`) reads from a custom configuration file if it exists. 
By default, we provide a massive list of curated apps, but you can inject your own proprietary or obscure software seamlessly.

1. Open `~/.config/app-store-custom.conf`.
2. Add your custom apps using the pipe `|` delimiter syntax:
   `Category | App Name | package_name | package_manager`

**Example:**
```text
Dev Tools|Postman|postman-bin|paru
Design|Blender|blender|pacman
Utilities|BTop|btop|pacman
```

Once saved, relaunch the App Store via `Super+X`, and your custom category and apps will dynamically appear in the Rofi menu, complete with automated installation handling.

## Modifying Hyprland

Your primary tiling logic is housed in `~/.config/hypr/hyprland.conf`, installed via the Desktop module.

### Changing Monitor Scaling
By default, Hyprland scales high-DPI monitors automatically. To override this and force a specific resolution (e.g., 4K at 144Hz):
```text
monitor=DP-1,3840x2160@144,0x0,1.25
```

### Adding Startup Apps
If you want Discord or Spotify to launch implicitly in specific workspaces:
```text
exec-once = [workspace 4 silent] webcord
exec-once = [workspace 5 silent] spotify-launcher
```

## Styling Waybar

The Waybar configuration is built using advanced CSS Variables injected by the `nexus theme` ecosystem tool.

* **Layout**: Edit `~/.config/waybar/config`
* **Styling**: Edit `~/.config/waybar/style.css`

> **Note**: Do not hardcode colors (e.g., `#f38ba8`) in `style.css`. Instead, use the CSS variables like `@define-color red;` which are dynamically hot-swapped by the Theme Engine depending on if you are using Frappe, Macchiato, or Dracula.

## Shell Aliases (Fish)

Your `config.fish` (installed via the Desktop module) is heavily optimized for speed. Custom aliases can be appended to the bottom using `abbr` or `alias`:

```bash
abbr update "sudo pacman -Syu"
abbr gc "git commit -m"
abbr docker-kill "docker kill (docker ps -q)"
```

After modifying the file, run `source ~/.config/fish/config.fish` to reload it.
