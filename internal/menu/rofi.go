package menu

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"
)

// Catppuccin Mocha Colors
const (
	BG         = "#1e1e2e"
	BG_ALT     = "#313244"
	BG_SURFACE = "#45475a"
	FG         = "#cdd6f4"
	ACCENT     = "#cba6f7"
	RED        = "#f38ba8"
	GREEN      = "#a6e3a1"
	BLUE       = "#89b4fa"
	YELLOW     = "#f9e2af"
	TEAL       = "#94e2d5"
	PINK       = "#f5c2e7"
)

func getBattery() string {
	if _, err := os.Stat("/sys/class/power_supply/BAT0/capacity"); err == nil {
		capBytes, _ := os.ReadFile("/sys/class/power_supply/BAT0/capacity")
		capStr := strings.TrimSpace(string(capBytes))
		cap, _ := strconv.Atoi(capStr)

		statusBytes, _ := os.ReadFile("/sys/class/power_supply/BAT0/status")
		statusStr := strings.TrimSpace(string(statusBytes))

		if statusStr == "Charging" {
			return fmt.Sprintf("󰂄 %d%%", cap)
		} else if cap <= 20 {
			return fmt.Sprintf("󰂃 %d%%", cap)
		} else if cap <= 50 {
			return fmt.Sprintf("󰁾 %d%%", cap)
		} else {
			return fmt.Sprintf("󰁹 %d%%", cap)
		}
	}
	return "󰚥 AC"
}

func getRAM() string {
	out, err := exec.Command("free", "-m").Output()
	if err != nil {
		return "󰍛 ?GB"
	}
	lines := strings.Split(string(out), "\n")
	if len(lines) > 1 {
		fields := strings.Fields(lines[1])
		if len(fields) >= 3 {
			total, _ := strconv.Atoi(fields[1])
			used, _ := strconv.Atoi(fields[2])
			gbUsed := float64(used) / 1024.0
			gbTotal := float64(total) / 1024.0
			return fmt.Sprintf("󰍛 %.1f/%.0fGB", gbUsed, gbTotal)
		}
	}
	return "󰍛 ?GB"
}

func getDisk() string {
	var stat syscall.Statfs_t
	syscall.Statfs("/", &stat)
	freeBytes := stat.Bavail * uint64(stat.Bsize)
	freeGB := float64(freeBytes) / 1024 / 1024 / 1024
	return fmt.Sprintf("󰋊 %.0fG free", freeGB)
}

func getCpuTemp() string {
	if _, err := os.Stat("/sys/class/thermal/thermal_zone0/temp"); err == nil {
		tempBytes, _ := os.ReadFile("/sys/class/thermal/thermal_zone0/temp")
		tempStr := strings.TrimSpace(string(tempBytes))
		temp, _ := strconv.Atoi(tempStr)
		return fmt.Sprintf("󰔏 %d°C", temp/1000)
	}
	return ""
}

func isCommandAvailable(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

func isProcessRunning(name string) bool {
	cmd := exec.Command("pgrep", "-x", name)
	err := cmd.Run()
	return err == nil
}

func buildMenu() string {
	var entries []string

	// Header
	bat := getBattery()
	ram := getRAM()
	disk := getDisk()
	temp := getCpuTemp()

	entries = append(entries, fmt.Sprintf("── %s  │  %s  │  %s  │  %s ──", bat, ram, disk, temp))
	entries = append(entries, "\000nonselectable\x1f─────────────────────────────────────────")

	// Quick Actions
	entries = append(entries, "  System Update (pacman)")
	entries = append(entries, "  Cleanup Packages & Cache")
	entries = append(entries, "󰒲  Lock Screen")
	entries = append(entries, "  Power Off")
	entries = append(entries, "  Reboot")
	entries = append(entries, "  Logout (Hyprland)")
	entries = append(entries, "\000nonselectable\x1f─────────────────────────────────────────")

	// Screenshot & Recording
	entries = append(entries, "  Screenshot — Region (slurp)")
	entries = append(entries, "  Screenshot — Full Screen")
	if isProcessRunning("wf-recorder") {
		entries = append(entries, "  Stop Recording (currently recording...)")
	} else {
		entries = append(entries, "  Record Screen (full)")
		entries = append(entries, "  Record Region (select area)")
	}
	entries = append(entries, "\000nonselectable\x1f─────────────────────────────────────────")

	// AI Tools
	if isCommandAvailable("ollama") {
		ollamaStatus := "🔴"
		if isProcessRunning("ollama") {
			ollamaStatus = "🟢"
		}
		entries = append(entries, fmt.Sprintf("  󰧑  Nexus AI Chat (Select Model) %s", ollamaStatus))
		entries = append(entries, fmt.Sprintf("  🧠 AI Auto-Tuner (Suggest Optimizations) %s", ollamaStatus))
	}
	entries = append(entries, "\000nonselectable\x1f─────────────────────────────────────────")

	if isCommandAvailable("health-check") {
		entries = append(entries, "  🩺 System Health Check")
	}
	entries = append(entries, "  📊 System Dashboard")

	// Development
	if isCommandAvailable("antigravity") {
		entries = append(entries, "  Antigravity (AI Editor)")
	}
	if isCommandAvailable("nvim") {
		entries = append(entries, "  Neovim")
	}
	if isCommandAvailable("docker") {
		dockerStatus := "🔴"
		if err := exec.Command("systemctl", "is-active", "docker").Run(); err == nil {
			dockerStatus = "🟢"
		}
		entries = append(entries, fmt.Sprintf("  Docker Manager (lazydocker) %s", dockerStatus))
	}
	if isCommandAvailable("flutter") {
		entries = append(entries, "  Flutter Doctor")
	}
	if isCommandAvailable("scrcpy") {
		entries = append(entries, "  Phone Mirror (scrcpy)")
	}
	entries = append(entries, "  🏪 GUI App Store (Browse & Install)")
	entries = append(entries, "\000nonselectable\x1f─────────────────────────────────────────")

	// Apps
	if isCommandAvailable("zen-browser") {
		entries = append(entries, "  Zen Browser")
	} else if isCommandAvailable("firefox") {
		entries = append(entries, "  Firefox")
	}
	if isCommandAvailable("thunar") {
		entries = append(entries, "  File Manager")
	}
	if isCommandAvailable("obsidian") {
		entries = append(entries, "  Obsidian Notes")
	}
	if isCommandAvailable("keepassxc") {
		entries = append(entries, "  Password Manager")
	}
	entries = append(entries, "\000nonselectable\x1f─────────────────────────────────────────")

	// Gaming
	hasGaming := false
	if isCommandAvailable("steam") {
		entries = append(entries, "  Steam")
		hasGaming = true
	}
	if isCommandAvailable("prismlauncher") {
		entries = append(entries, "  Minecraft")
		hasGaming = true
	}
	if isCommandAvailable("pcsx2") {
		entries = append(entries, "  PS2 Emulator")
		hasGaming = true
	}
	if isCommandAvailable("sober") {
		entries = append(entries, "  Roblox")
		hasGaming = true
	}
	if hasGaming {
		entries = append(entries, "\000nonselectable\x1f─────────────────────────────────────────")
	}

	// System & Productivity
	if isCommandAvailable("virt-manager") {
		vmStatus := "🔴"
		if out, err := exec.Command("virsh", "list").Output(); err == nil && strings.Contains(string(out), "running") {
			vmStatus = "🟢 VM running"
		}
		entries = append(entries, fmt.Sprintf("  Virtual Machine Manager %s", vmStatus))
	}
	if isCommandAvailable("bottles") {
		entries = append(entries, "  Bottles (Windows Apps)")
	}
	if isCommandAvailable("libreoffice") {
		entries = append(entries, "  LibreOffice")
	}
	if isCommandAvailable("obs") {
		entries = append(entries, "  OBS Studio")
	}
	if isCommandAvailable("kdeconnect-cli") {
		entries = append(entries, "  KDE Connect")
	}
	entries = append(entries, "\000nonselectable\x1f─────────────────────────────────────────")

	// System Tools
	entries = append(entries, "  🛡️ Time Machine (Config Rollback)")
	entries = append(entries, "  ☁️ Dotfiles Cloud Sync")
	entries = append(entries, "  System Monitor (btm)")
	entries = append(entries, "  Disk Usage")
	entries = append(entries, "  System Info (fastfetch)")
	entries = append(entries, "  Public IP")
	entries = append(entries, "  Audio Settings")
	entries = append(entries, "  WiFi Settings")
	if isCommandAvailable("blueman-manager") {
		entries = append(entries, "  Bluetooth")
	}
	entries = append(entries, "  󰸉  Change Wallpaper")
	entries = append(entries, "  🎨 Dynamic Theme Switcher")
	entries = append(entries, "\000nonselectable\x1f─────────────────────────────────────────")

	// Search
	entries = append(entries, "  Guide Popup (130+ entries)")
	entries = append(entries, "  Guide in Terminal (fzf + preview)")
	entries = append(entries, "  cheat.sh Web Lookup")

	return strings.Join(entries, "\n")
}

func executeAction(chosen string) {
	homeDir, _ := os.UserHomeDir()
	timestamp := time.Now().Format("20060102-150405")

	if strings.Contains(chosen, "GUI App Store") {
		exec.Command("app-store").Start()
	} else if strings.Contains(chosen, "AI Auto-Tuner") {
		exec.Command("ai-tuner").Start()
	} else if strings.Contains(chosen, "Health Check") {
		exec.Command("kitty", "-e", "bash", "-c", "health-check; echo \"\"; echo \"Press Enter to close...\"; read").Start()
	} else if strings.Contains(chosen, "System Dashboard") {
		dashboardCmd := `echo -e "\033[1;35m━━━ 📊 System Dashboard ━━━\033[0m"; echo ""; fastfetch 2>/dev/null || echo "(fastfetch not installed)"; echo ""; echo -e "\033[1;36m━━━ Disk Usage ━━━\033[0m"; duf 2>/dev/null || df -h; echo ""; echo -e "\033[1;36m━━━ Top 10 Processes (by CPU) ━━━\033[0m"; ps aux --sort=-%cpu | head -11; echo ""; echo -e "\033[1;36m━━━ Memory ━━━\033[0m"; free -h`
		exec.Command("kitty", "--hold", "-e", "bash", "-c", dashboardCmd).Start()
	} else if strings.Contains(chosen, "Dotfiles Cloud Sync") {
		exec.Command("dotfiles-sync").Start()
	} else if strings.Contains(chosen, "Time Machine") {
		exec.Command("config-rollback").Start()
	} else if strings.Contains(chosen, "Dynamic Theme Switcher") {
		exec.Command("theme-switch").Start()
	} else if strings.Contains(chosen, "Change Wallpaper") {
		exec.Command("waypaper").Start()
	} else if strings.Contains(chosen, "System Update") {
		previewText := "Pending updates"
		out, err := exec.Command("pacman", "-Qu").Output()
		if err == nil {
			lines := strings.Split(string(out), "\n")
			pkgCount := len(lines) - 1
			if pkgCount > 0 {
				preview := strings.Join(lines[:min(20, pkgCount)], "\n")
				previewText = fmt.Sprintf("%d package(s) pending update:\n\n%s", pkgCount, preview)
				if pkgCount > 20 {
					previewText += fmt.Sprintf("\n... and %d more", pkgCount-20)
				}
			} else {
				previewText = "No pending updates found (already up to date?)"
			}
		}

		zenityArgs := []string{
			"--question",
			"--title=⚠️ System Update",
			fmt.Sprintf("--text=%s\n\n━━━━━━━━━━━━━━━━━━━━━━━\nThis will run:\n  sudo pacman -Syu\n  rustup update\n\nOn a rolling release, this can break things.\nAre you sure?", previewText),
			"--ok-label=Yes, Update",
			"--cancel-label=Cancel",
			"--width=500", "--height=400",
		}
		if err := exec.Command("zenity", zenityArgs...).Run(); err == nil {
			exec.Command("kitty", "--hold", "-e", "bash", "-c", "echo \"🔄 Updating system...\"; sudo pacman -Syu && rustup update 2>/dev/null; echo \"\"; echo \"✅ Update complete!\"").Start()
		}
	} else if strings.Contains(chosen, "Cleanup") {
		exec.Command("kitty", "--hold", "-e", "bash", "-c", "echo \"🧹 Cleaning up...\"; sudo pacman -Sc --noconfirm; pacman -Qdtq | xargs -r sudo pacman -Rns --noconfirm 2>/dev/null; echo \"✅ Cleanup done\"").Start()
	} else if strings.Contains(chosen, "Lock Screen") {
		exec.Command("hyprlock").Start()
	} else if strings.Contains(chosen, "Power Off") {
		exec.Command("systemctl", "poweroff").Start()
	} else if strings.Contains(chosen, "Reboot") {
		exec.Command("systemctl", "reboot").Start()
	} else if strings.Contains(chosen, "Logout") {
		exec.Command("hyprctl", "dispatch", "exit").Start()
	} else if strings.Contains(chosen, "Screenshot") && strings.Contains(chosen, "Region") {
		path := filepath.Join(homeDir, "Pictures", "Screenshots", timestamp+".png")
		cmdStr := fmt.Sprintf("grim -g \"$(slurp)\" %s", path)
		if err := exec.Command("bash", "-c", cmdStr).Run(); err == nil {
			exec.Command("notify-send", "📸 Screenshot saved", filepath.Join(homeDir, "Pictures", "Screenshots")).Start()
		}
	} else if strings.Contains(chosen, "Screenshot") && strings.Contains(chosen, "Full") {
		path := filepath.Join(homeDir, "Pictures", "Screenshots", timestamp+".png")
		if err := exec.Command("grim", path).Run(); err == nil {
			exec.Command("notify-send", "📸 Screenshot saved", filepath.Join(homeDir, "Pictures", "Screenshots")).Start()
		}
	} else if strings.Contains(chosen, "Stop Recording") {
		if err := exec.Command("pkill", "-SIGINT", "wf-recorder").Run(); err == nil {
			exec.Command("notify-send", "🎥 Recording saved", filepath.Join(homeDir, "Videos")).Start()
		}
	} else if strings.Contains(chosen, "Record Screen") {
		path := filepath.Join(homeDir, "Videos", "recording-"+timestamp+".mp4")
		exec.Command("bash", "-c", fmt.Sprintf("wf-recorder -f %s &", path)).Start()
		exec.Command("notify-send", "🎥 Recording started", "Super+X → Stop to end").Start()
	} else if strings.Contains(chosen, "Record Region") {
		path := filepath.Join(homeDir, "Videos", "clip-"+timestamp+".mp4")
		exec.Command("bash", "-c", fmt.Sprintf("wf-recorder -g \"$(slurp)\" -f %s &", path)).Start()
		exec.Command("notify-send", "🎥 Recording region", "Super+X → Stop to end").Start()
	} else if strings.Contains(chosen, "Nexus AI Chat") {
		exec.Command("nexus-chat").Start()
	} else if strings.Contains(chosen, "Antigravity") {
		exec.Command("antigravity").Start()
	} else if strings.Contains(chosen, "Neovim") {
		exec.Command("kitty", "-e", "nvim").Start()
	} else if strings.Contains(chosen, "Docker Manager") {
		exec.Command("kitty", "-e", "lazydocker").Start()
	} else if strings.Contains(chosen, "Flutter Doctor") {
		exec.Command("kitty", "--hold", "-e", "flutter", "doctor").Start()
	} else if strings.Contains(chosen, "Phone Mirror") {
		exec.Command("scrcpy").Start()
	} else if strings.Contains(chosen, "Zen Browser") {
		exec.Command("zen-browser").Start()
	} else if strings.Contains(chosen, "Firefox") {
		exec.Command("firefox").Start()
	} else if strings.Contains(chosen, "File Manager") {
		exec.Command("thunar").Start()
	} else if strings.Contains(chosen, "Obsidian") {
		exec.Command("obsidian").Start()
	} else if strings.Contains(chosen, "Password") {
		exec.Command("keepassxc").Start()
	} else if strings.Contains(chosen, "Steam") {
		exec.Command("steam").Start()
	} else if strings.Contains(chosen, "Minecraft") {
		exec.Command("prismlauncher").Start()
	} else if strings.Contains(chosen, "PS2") {
		exec.Command("pcsx2").Start()
	} else if strings.Contains(chosen, "Roblox") {
		exec.Command("sober").Start()
	} else if strings.Contains(chosen, "Virtual Machine") {
		exec.Command("virt-manager").Start()
	} else if strings.Contains(chosen, "Bottles") {
		exec.Command("bottles").Start()
	} else if strings.Contains(chosen, "LibreOffice") {
		exec.Command("libreoffice", "--writer").Start()
	} else if strings.Contains(chosen, "OBS") {
		exec.Command("obs").Start()
	} else if strings.Contains(chosen, "KDE Connect") {
		exec.Command("kdeconnect-app").Start()
	} else if strings.Contains(chosen, "System Monitor") {
		exec.Command("kitty", "-e", "btm").Start()
	} else if strings.Contains(chosen, "Disk Usage") {
		exec.Command("kitty", "--hold", "-e", "duf").Start()
	} else if strings.Contains(chosen, "System Info") {
		exec.Command("kitty", "--hold", "-e", "fastfetch").Start()
	} else if strings.Contains(chosen, "Public IP") {
		if out, err := exec.Command("curl", "-s", "ifconfig.me").Output(); err == nil {
			exec.Command("notify-send", "🌐 Public IP", string(out)).Start()
		}
	} else if strings.Contains(chosen, "Audio") {
		exec.Command("pavucontrol").Start()
	} else if strings.Contains(chosen, "WiFi") {
		exec.Command("kitty", "--hold", "-e", "nmtui").Start()
	} else if strings.Contains(chosen, "Bluetooth") {
		exec.Command("blueman-manager").Start()
	} else if strings.Contains(chosen, "Guide Popup") {
		exec.Command("guide", "--popup").Start()
	} else if strings.Contains(chosen, "Guide in Terminal") {
		exec.Command("kitty", "-e", "guide").Start()
	} else if strings.Contains(chosen, "cheat.sh") {
		exec.Command("kitty", "-e", "bash", "-c", "echo -n \"🔍 Enter topic: \"; read q; guide --web \"$q\"").Start()
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func getRofiTheme() string {
	return fmt.Sprintf(`
* {
	font: "JetBrainsMono Nerd Font 11";
	bg: %s;
	bg-alt: %s;
	bg-surface: %s;
	fg: %s;
	accent: %s;
	red: %s;
	green: %s;
	blue: %s;
}
window {
	width: 460px;
	border: 2px;
	border-color: %s;
	border-radius: 16px;
	background-color: %s;
	transparency: "real";
	location: center;
}
mainbox {
	background-color: transparent;
	spacing: 0;
}
inputbar {
	background-color: %s;
	border-radius: 12px;
	padding: 10px 16px;
	margin: 12px 12px 4px 12px;
	children: [prompt, textbox-prompt-colon, entry];
}
prompt {
	background-color: transparent;
	text-color: %s;
	font: "JetBrainsMono Nerd Font Bold 13";
}
textbox-prompt-colon {
	str: "";
	background-color: transparent;
}
entry {
	background-color: transparent;
	text-color: %s;
	placeholder: "Search actions...";
	placeholder-color: #6c7086;
}
message {
	background-color: %s;
	border-radius: 8px;
	margin: 4px 12px;
	padding: 6px 12px;
}
textbox {
	background-color: transparent;
	text-color: #6c7086;
	font: "JetBrainsMono Nerd Font 9";
}
listview {
	columns: 1;
	lines: 16;
	scrollbar: false;
	background-color: transparent;
	padding: 4px 8px 8px 8px;
	fixed-height: false;
}
element {
	padding: 6px 16px;
	border-radius: 10px;
	background-color: transparent;
	text-color: %s;
}
element selected {
	background-color: %s;
	text-color: %s;
}
element-text {
	background-color: transparent;
	text-color: inherit;
	vertical-align: 0.5;
}
	`, BG, BG_ALT, BG_SURFACE, FG, ACCENT, RED, GREEN, BLUE, ACCENT, BG, BG_ALT, ACCENT, FG, BG_ALT, FG, BG_ALT, ACCENT)
}

func filterEmptyLines(input string) string {
	var keep []string
	for _, line := range strings.Split(input, "\n") {
		if strings.TrimSpace(line) != "" {
			keep = append(keep, line)
		}
	}
	return strings.Join(keep, "\n")
}

// ShowMenu launches the rofi GUI menu
func ShowMenu() error {
	entriesList := buildMenu()
	entriesList = filterEmptyLines(entriesList)

	mesg := fmt.Sprintf("Super+X · %s · %s", getBattery(), getRAM())
	themeConfig := getRofiTheme()

	cmd := exec.Command("rofi", "-dmenu", "-i", "-p", " Nexus", "-mesg", mesg, "-theme-str", themeConfig)
	cmd.Stdin = strings.NewReader(entriesList)
	
	var out bytes.Buffer
	cmd.Stdout = &out

	err := cmd.Run()
	if err != nil {
		// rofi returns exit status 1 if user hits ESC to cancel. This is not an error.
		return nil
	}

	chosen := strings.TrimSpace(out.String())
	if chosen != "" && !strings.HasPrefix(chosen, "──") && !strings.HasPrefix(chosen, "\000") && !strings.HasPrefix(chosen, "─") {
		executeAction(chosen)
	}

	return nil
}
