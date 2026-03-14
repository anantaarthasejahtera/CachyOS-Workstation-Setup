package modules

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/state"
	"github.com/pterm/pterm"
)

// InstallAppsAndGaming implements 10-apps.sh and 11-gaming.sh logic.
func InstallAppsAndGaming() error {
	pterm.Info.Println("🌟 [Module 10 & 11: Apps] Installing Applications & Gaming Suite...")

	setupApps()
	setupGaming()

	pterm.Info.Println("✅ [Module 10 & 11: Apps] Applications and Gaming suite installed.")
	return nil
}

func setupApps() {
	home := os.Getenv("HOME")
	pterm.Info.Println("-> Configuring Core Applications...")
	pacman.Remove("auto-cpufreq")

	type appInfo struct {
		id   string
		name string
		def  bool
	}

	apps := []appInfo{
		{"zen-browser-bin", "🌀 Zen Browser (Sleek Firefox fork)", true},
		{"brave-bin", "🛡️ Brave Browser (Ad-block Native)", false},
		{"tmux", "🖥️ Tmux (Terminal Multiplexer)", true},
		{"direnv", "📂 Direnv (Environment Switcher)", true},
		{"bluez", "🦷 Bluetooth Stack (bluez, blueman)", false},
		{"discord", "💬 Discord", true},
		{"vesktop", "💬 Vesktop (Lighter Discord Client)", false},
		{"spotify-launcher", "🎵 Spotify (Launcher)", true},
		{"libreoffice-fresh", "📄 LibreOffice (Office Suite)", true},
		{"kdeconnect", "📱 KDE Connect", true},
		{"keepassxc", "🔐 KeePassXC (Password Manager)", true},
		{"obs-studio", "🎥 OBS Studio", true},
		{"mpv", "📼 MPV (Video Player)", true},
		{"obsidian-bin", "💎 Obsidian (Knowledge Base)", true},
		{"telegram-desktop", "✈️ Telegram Desktop", false},
	}

	var options []string
	var defaultOptions []string
	appMap := make(map[string]string)

	for _, app := range apps {
		display := app.name + " (" + app.id + ")"
		options = append(options, display)
		appMap[display] = app.id
		if app.def && !pacman.IsInstalled(app.id) {
			defaultOptions = append(defaultOptions, display)
		}
	}

	selected, _ := pterm.DefaultInteractiveMultiselect.
		WithOptions(options).
		WithDefaultOptions(defaultOptions).
		WithFilter(false).
		Show("Select Core Applications to install/update")

	if len(selected) == 0 {
		pterm.Info.Println("   [!] No apps selected.")
	} else {
		pterm.Info.Printf("   -> Installing %d selected apps...\n", len(selected))
		for _, sel := range selected {
			app := appMap[sel]
			pterm.Info.Printf("      📦 Processing: %s\n", app)
			if app == "bluez" {
				pacman.Install("bluez", "blueman")
				pacman.Command("sudo", "systemctl", "enable", "--now", "bluetooth.service").Run()
			} else {
				pacman.Install(app)
			}
		}
	}

	// Discord - Ultra-Lightweight Tuning
	discordDir := filepath.Join(home, ".config/discord")
	os.MkdirAll(discordDir, 0755)
	discordSettings := `{
    "IS_MAXIMIZED": false,
    "IS_MINIMIZED": false,
    "WINDOW_BOUNDS": { "x": 0, "y": 0, "width": 1280, "height": 720 },
    "SKIP_HOST_UPDATE": true,
    "OPEN_ON_STARTUP": false,
    "MINIMIZE_TO_TRAY": true
}`
	state.SafeWriteConfig(filepath.Join(discordDir, "settings.json"), []byte(discordSettings), 0644)

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

	state.SafeWriteConfig(filepath.Join(home, ".config/mimeapps.list"), []byte(mimeList), 0644)
	pacman.Command("xdg-settings", "set", "default-web-browser", browserDesktop).Run()

	// Tmux
	tpmDir := filepath.Join(home, ".tmux/plugins/tpm")
	if _, err := os.Stat(tpmDir); os.IsNotExist(err) {
		pacman.Command("git", "clone", "https://github.com/tmux-plugins/tpm", tpmDir).Run()
	}
	os.MkdirAll(filepath.Join(home, ".config/tmux"), 0755)
	state.SafeWriteConfig(filepath.Join(home, ".config/tmux/tmux.conf"), []byte(strings.TrimSpace(tmuxConf)+"\n"), 0644)
}

func setupGaming() {
	home := os.Getenv("HOME")
	pterm.Info.Println("-> Configuring Gaming Suite & Emulators...")

	type gameInfo struct {
		id   string
		name string
		def  bool
	}

	games := []gameInfo{
		{"steam", "🎮 Steam", true},
		{"mangohud", "🥭 MangoHud (Performance Overlay)", true},
		{"wine-staging", "🍷 Wine Staging", true},
		{"winetricks", "🪄 Winetricks", true},
		{"prismlauncher", "🧊 Prism Launcher (Minecraft)", false},
		{"ryujinx-bin", "🕹️ Ryujinx (Switch Emulator)", false},
		{"pcsx2-latest-bin", "💿 PCSX2 (PS2 Emulator)", false},
		{"duckstation-git", "🦆 DuckStation (PS1 Emulator)", false},
		{"heroic-games-launcher-bin", "🦸 Heroic Games Launcher (Epic/GOG)", false},
		{"lutris", "👾 Lutris (Gaming Platform)", false},
	}

	var options []string
	var defaultOptions []string
	gameMap := make(map[string]string)

	for _, g := range games {
		display := g.name + " (" + g.id + ")"
		options = append(options, display)
		gameMap[display] = g.id
		if g.def && !pacman.IsInstalled(g.id) {
			defaultOptions = append(defaultOptions, display)
		}
	}

	selected, _ := pterm.DefaultInteractiveMultiselect.
		WithOptions(options).
		WithDefaultOptions(defaultOptions).
		WithFilter(false).
		Show("Select Gaming Applications to install/update")

	pcsx2Selected := false

	if len(selected) == 0 {
		pterm.Info.Println("   [!] No gaming tools selected.")
	} else {
		pterm.Info.Printf("   -> Installing %d gaming components...\n", len(selected))
		for _, sel := range selected {
			app := gameMap[sel]
			pterm.Info.Printf("      🎮 Processing: %s\n", app)
			if app == "mangohud" {
				pacman.Install("mangohud", "lib32-mangohud")
			} else {
				pacman.Install(app)
			}
			if app == "pcsx2-latest-bin" {
				pcsx2Selected = true
			}
		}
	}

	os.MkdirAll(filepath.Join(home, ".config/MangoHud"), 0755)
	state.SafeWriteConfig(filepath.Join(home, ".config/MangoHud/MangoHud.conf"), []byte(strings.TrimSpace(mangoConfig)+"\n"), 0644)

	// PCSX2 Auto-Tuning and BIOS Download
	if pcsx2Selected {
		pterm.Info.Println("-> Tuning PCSX2 & Downloading BIOS...")
		pcsx2Dir := filepath.Join(home, ".config/PCSX2")
		biosDir := filepath.Join(pcsx2Dir, "bios")
		inisDir := filepath.Join(pcsx2Dir, "inis")
		os.MkdirAll(biosDir, 0755)
		os.MkdirAll(inisDir, 0755)

		biosZipPath := filepath.Join(biosDir, "PS2_BIOS.zip")
		if _, err := os.Stat(filepath.Join(biosDir, "scph39001.bin")); os.IsNotExist(err) {
			// Download a standard PS2 BIOS bundle from archive.org
			pterm.Info.Println("   Downloading PS2 BIOS...")
			err := pacman.Command("curl", "-L", "-o", biosZipPath, "https://archive.org/download/ps-2-bios-2004/ps2%20bios%202004.zip").Run()
			if err == nil {
				pacman.Command("unzip", "-o", biosZipPath, "-d", biosDir).Run()
				os.Remove(biosZipPath)
			} else {
				pterm.Info.Println("   [Warning] Failed to download BIOS. You may need to provide it manually.")
			}
		}

		// Inject optimal PCSX2 config for 1080p Vulkan
		state.SafeWriteConfig(filepath.Join(inisDir, "PCSX2.ini"), []byte(strings.TrimSpace(pcsx2ini)+"\n"), 0644)
	}

	pterm.Info.Println("   Gaming Suite configuration complete.")
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

const pcsx2ini = `
[UI]
SettingsVersion = 1
Inited = true

[EmuCore]
CdvdVerboseReads = false
CdvdDumpBlocks = false
CdvdShareWrite = false
EnableStateDumping = false
EnableSaveStateOnShutdown = false
EnablePnach = true

[EmuCore/GS]
Renderer = 14
OsdShowFPS = false
OsdShowSpeed = false
OsdShowResolution = false
OsdShowCPU = false
OsdShowGPU = false
OsdShowIndicators = false

[EmuCore/Gamefixes]
VuAddSubHack = false
FpuCompareHack = false
FpuMulHack = false
FpuNegDivHack = false

[EmuCore/HWTimer]
FrameUpdateFastForward = true

[EmuCore/Speedhacks]
EECycleRate = 0
EECycleSkip = 0
fastCDVD = false
IntcStat = true
WaitLoop = true
vuFlagHack = true
vuThread = true
vu1Instant = true

[EmuCore/CPUSplit]
MTVU = true

[Graphics]
Renderer = Vulkan
AutoFlush = false
Interlacing = Auto
TexturePreloading = 2
ResolutionScale = 2
`
