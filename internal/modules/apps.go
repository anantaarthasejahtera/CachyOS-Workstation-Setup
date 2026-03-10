package modules

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
)

// InstallAppsAndGaming implements 10-apps.sh and 11-gaming.sh logic.
func InstallAppsAndGaming() error {
	fmt.Println("🌟 [Module 10 & 11: Apps] Installing Applications & Gaming Suite...")

	setupApps()
	setupGaming()

	fmt.Println("✅ [Module 10 & 11: Apps] Applications and Gaming suite installed.")
	return nil
}

func setupApps() {
	fmt.Println("-> Installing Core Apps (Browser, Tools)...")
	pacman.Remove("auto-cpufreq") // Deprecated
	
	pacman.Install("zen-browser-bin")
	pacman.Install("tmux", "direnv")
	
	// Bluetooth
	pacman.Install("bluez", "bluez-utils", "blueman")
	exec.Command("sudo", "systemctl", "enable", "--now", "bluetooth.service").Run()

	// Comm & Productivity
	pacman.Install("telegram-desktop", "discord", "spotify-launcher")
	pacman.Install("libreoffice-fresh", "kdeconnect", "keepassxc", "obs-studio", "wf-recorder")
	
	if !pacman.IsInstalled("obsidian") && !pacman.IsInstalled("obsidian-bin") {
		pacman.Install("obsidian-bin")
	}

	fmt.Println("-> Configuring Tmux and XDG Defaults...")
	home := os.Getenv("HOME")
	
	// XDG Defaults
	os.MkdirAll(filepath.Join(home, ".config"), 0755)
	
	browserDesktop := "zen-browser.desktop"
	if !pacman.IsInstalled("zen-browser-bin") && !pacman.IsInstalled("zen-browser") {
		browserDesktop = "firefox.desktop"
	}
	
	mimeList := fmt.Sprintf(`[Default Applications]
x-scheme-handler/http=%s
x-scheme-handler/https=%s
x-scheme-handler/about=%s
x-scheme-handler/unknown=%s
text/html=%s
application/xhtml+xml=%s
inode/directory=thunar.desktop
x-scheme-handler/terminal=kitty.desktop
text/plain=nvim.desktop
application/x-shellscript=nvim.desktop
`, browserDesktop, browserDesktop, browserDesktop, browserDesktop, browserDesktop, browserDesktop)
	
	os.WriteFile(filepath.Join(home, ".config/mimeapps.list"), []byte(mimeList), 0644)
	exec.Command("xdg-settings", "set", "default-web-browser", browserDesktop).Run()

	// Tmux
	tpmDir := filepath.Join(home, ".tmux/plugins/tpm")
	if _, err := os.Stat(tpmDir); os.IsNotExist(err) {
		exec.Command("git", "clone", "https://github.com/tmux-plugins/tpm", tpmDir).Run()
	}
	os.MkdirAll(filepath.Join(home, ".config/tmux"), 0755)
	os.WriteFile(filepath.Join(home, ".config/tmux/tmux.conf"), []byte(strings.TrimSpace(tmuxConf)+"\n"), 0644)
}

func setupGaming() {
	fmt.Println("-> Installing Gaming Suite...")
	pacman.Install("steam", "mangohud", "lib32-mangohud", "wine-staging", "winetricks", "prismlauncher")
	
	if !pacman.IsInstalled("pcsx2") && !pacman.IsInstalled("pcsx2-latest-bin") {
		pacman.Install("pcsx2-latest-bin")
	}

	home := os.Getenv("HOME")
	os.MkdirAll(filepath.Join(home, ".config/MangoHud"), 0755)
	os.WriteFile(filepath.Join(home, ".config/MangoHud/MangoHud.conf"), []byte(strings.TrimSpace(mangoConfig)+"\n"), 0644)
	
	fmt.Println("   Steam, Wine, Minecraft, and PS2 emulator installed.")
}

// -------------------------------------------------------------------------
// HARDCODED CONFIGURATIONS
// -------------------------------------------------------------------------

const tmuxConf = `
# — Tmux — Catppuccin Mocha —
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

unbind C-b
set -g prefix C-a
bind C-a send-prefix

set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

set -g history-limit 50000
setw -g mode-keys vi

# Theme
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'catppuccin/tmux#v2.1.0'

set -g @catppuccin_flavor 'mocha'
set -g @catppuccin_window_status_style 'rounded'

set -g status-right-length 100
set -g status-left-length 100
set -g status-left ""
set -g status-right "#{E:@catppuccin_status_session}"
set -agF status-right "#{E:@catppuccin_status_date_time}"

run '~/.tmux/plugins/tpm/tpm'
`

const mangoConfig = `
# — MangoHud — Catppuccin Style FPS Overlay —
legacy_layout=false
fps
frametime=0
gpu_stats
gpu_temp
gpu_power
cpu_stats
cpu_temp
cpu_power
cpu_mhz
ram
vram
fps_limit=60
position=top-left
round_corners=10
font_size=20
toggle_fps_limit=F1
toggle_hud=F12
background_color=1e1e2e
text_color=cdd6f4
gpu_color=89b4fa
cpu_color=cba6f7
frametime_color=a6e3a1
engine_color=f5c2e7
background_alpha=0.7
`
