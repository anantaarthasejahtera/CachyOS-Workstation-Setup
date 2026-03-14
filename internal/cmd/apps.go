package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
)

var appsCmd = &cobra.Command{
	Use:   "apps",
	Short: "Interactive application installer",
	Long:  `Launch the sleek TUI application store to browse, search, and install extra tools.`,
	Run: func(cmd *cobra.Command, args []string) {
		for {
			// Step 1: Browse Categories using Zenity
			categoryCmd := exec.Command("zenity", "--list",
				"--title=Nexus App Store",
				"--text=Choose a curated category to browse",
				"--column=ID", "--column=Category", "--hide-column=1",
				"--width=600", "--height=400",
				"browser", "🌐 Browsers & Internet",
				"dev", "👨‍💻 Development & Coding",
				"gaming", "🎮 Gaming & Emulators",
				"media", "🎨 Design & Media",
				"utils", "🔧 System Utilities",
				"office", "📝 Office & Productivity",
				"exit", "❌ Exit",
			)
			categoryOutput, err := categoryCmd.Output()
			if err != nil {
				// User cancelled or exited
				return
			}

			category := strings.TrimSpace(string(categoryOutput))
			if category == "exit" || category == "" {
				return
			}

			var appOptions []string
			switch category {
			case "browser":
				// Added more lightweight options and categorized them
				appOptions = []string{
					"FALSE", "zen-browser-bin", "🌀 Zen Browser (Sleek & Fast Firefox fork)",
					"FALSE", "brave-bin", "🛡️ Brave Browser (Ad-block Native)",
					"FALSE", "librewolf-bin", "🦊 LibreWolf (Privacy Focused)",
					"FALSE", "google-chrome", "🌐 Google Chrome",
					"FALSE", "chromium-browser-bin", "🌐 Chromium (Open Source Chrome)",
					"FALSE", "epiphany", "🧭 GNOME Web (Epiphany - Ultra Lightweight)",
					"FALSE", "tor-browser", "🧅 Tor Browser (Maximum Privacy)",
				}
			case "dev":
				appOptions = []string{
					"FALSE", "ghostty", "🚀 Ghostty (GPU Accelerated Terminal)",
					"FALSE", "alacritty", "⚡ Alacritty (Fast Rust-based Terminal)",
					"FALSE", "wezterm", "🐚 WezTerm (Lua configurable Terminal)",
					"FALSE", "zed", "⚡ Zed Editor (Fastest Editor)",
					"FALSE", "cursor-bin", "🤖 Cursor AI Editor",
					"FALSE", "visual-studio-code-bin", "💻 Visual Studio Code",
					"FALSE", "neovim", "📝 Neovim (Goat Editor)",
					"FALSE", "lazygit", "🐚 Lazygit (Pro Terminal Git)",
					"FALSE", "insomnia-bin", "📡 Insomnia (API Client)",
					"FALSE", "postman-bin", "🚀 Postman (API Platform)",
					"FALSE", "docker", "🐳 Docker Engine",
					"FALSE", "docker-desktop", "🐘 Docker Desktop (GUI)",
					"FALSE", "dbeaver-ce", "🗄️ DBeaver (Database Tool)",
				}
			case "gaming":
				appOptions = []string{
					"FALSE", "steam", "🎮 Steam",
					"FALSE", "ryujinx-bin", "🕹️ Ryujinx (Switch Emulator)",
					"FALSE", "duckstation-git", "🦆 DuckStation (PS1 Emulator)",
					"FALSE", "pcsx2-latest-bin", "💿 PCSX2 (PS2 Emulator)",
					"FALSE", "rpcs3-bin", "🎮 RPCS3 (PS3 Emulator)",
					"FALSE", "heroic-games-launcher-bin", "🦸 Heroic Games Launcher (Epic/GOG)",
					"FALSE", "lutris", "👾 Lutris (Open Source Gaming Platform)",
					"FALSE", "discord", "💬 Discord",
					"FALSE", "vesktop", "💬 Vesktop (Lighter Discord Client with Screenshare)",
				}
			case "media":
				appOptions = []string{
					"FALSE", "mpv", "📼 MPV (Pro-tier Ultra Light Video Player)",
					"FALSE", "vlc", "🎬 VLC (Media Player)",
					"FALSE", "spotify-launcher", "🎵 Spotify (via spotify-launcher)",
					"FALSE", "spicetify-cli", "🎨 Spicetify (Spotify Themes)",
					"FALSE", "krita", "🖌️ Krita (Digital Painting)",
					"FALSE", "gimp", "🎨 GIMP (Image Editor)",
					"FALSE", "kdenlive", "✂️ Kdenlive (Video Editor)",
					"FALSE", "davinci-resolve", "🎬 DaVinci Resolve (Pro Video Editor)",
					"FALSE", "obs-studio", "🎥 OBS Studio (Streaming/Recording)",
				}
			case "utils":
				appOptions = []string{
					"FALSE", "fastfetch", "🔥 Fastfetch (Modern Fetch)",
					"FALSE", "btop", "📈 Btop (Best System Monitor)",
					"FALSE", "zoxide", "📂 Zoxide (Smarter cd)",
					"FALSE", "1password", "🔒 1Password",
					"FALSE", "keepassxc", "🔐 KeePassXC (Offline Password Manager)",
					"FALSE", "flameshot", "⚡ Flameshot (Screenshots)",
					"FALSE", "hyprpicker", "🎨 Hyprpicker (Color Picker for Wayland)",
					"FALSE", "qbittoorent", "📥 qBittorrent (Torrent Client)",
					"FALSE", "gparted", "💾 GParted (Partition Manager)",
					"FALSE", "stow", "🔗 GNU Stow (Dotfiles Manager)",
				}
			case "office":
				appOptions = []string{
					"FALSE", "obsidian-bin", "💎 Obsidian (Knowledge Management)",
					"FALSE", "logseq-desktop-bin", "📓 Logseq (Privacy-first notes)",
					"FALSE", "libreoffice-fresh", "📄 LibreOffice (Office Suite)",
					"FALSE", "onlyoffice-bin", "📊 OnlyOffice (Modern Office Suite)",
					"FALSE", "zotero-bin", "📚 Zotero (Reference Management)",
					"FALSE", "thunderbird", "📧 Thunderbird (Email Client)",
				}
			}

			// Step 2: Select Applications using Zenity Checklist
			zenityArgs := []string{
				"--list", "--checklist",
				"--title=Select Applications",
				"--text=Select applications to install",
				"--column=Install", "--column=Package", "--column=App Name",
				"--hide-column=2", // Hide the package name column for a cleaner look
				"--width=800", "--height=600",
				"--separator= ",
			}
			zenityArgs = append(zenityArgs, appOptions...)

			appsCmdExe := exec.Command("zenity", zenityArgs...)
			appsOutput, err := appsCmdExe.Output()
			if err != nil {
				// User cancelled, loop back to categories
				continue
			}

			selectedAppsStr := strings.TrimSpace(string(appsOutput))
			if selectedAppsStr == "" {
				continue
			}

			selectedApps := strings.Split(selectedAppsStr, " ")

			// Step 3: Confirm Installation
			confirmMsg := fmt.Sprintf("Install the following %d packages?\n\n%s", len(selectedApps), strings.Join(selectedApps, "\n"))
			confirmCmd := exec.Command("zenity", "--question", "--title=Confirm Installation", "--text="+confirmMsg, "--width=400")
			if err := confirmCmd.Run(); err != nil {
				// Cancelled setup
				continue
			}

			// Step 4: Installation Execution
			fmt.Printf("\n🚀 Installing %d packages: %v...\n", len(selectedApps), selectedApps)

			// Determine package manager
			var installExe string
			var installArgs []string
			if _, err := exec.LookPath("yay"); err == nil {
				installExe = "yay"
				installArgs = append([]string{"-S", "--noconfirm"}, selectedApps...)
			} else if _, err := exec.LookPath("paru"); err == nil {
				installExe = "paru"
				installArgs = append([]string{"-S", "--noconfirm"}, selectedApps...)
			} else {
				installExe = "sudo"
				installArgs = append([]string{"pacman", "-S", "--noconfirm"}, selectedApps...)
			}

			installCmd := exec.Command(installExe, installArgs...)
			installCmd.Stdout = os.Stdout
			installCmd.Stderr = os.Stderr

			if err := installCmd.Run(); err != nil {
				fmt.Printf("\n❌ Failed to install some packages.\n")
				exec.Command("zenity", "--error", "--text=Failed to install some packages. Check terminal for details.").Start()
			} else {
				fmt.Printf("\n✅ All packages installed successfully!\n")
				exec.Command("notify-send", "App Store", "Installation completed successfully!").Start()
			}
			
			// Return to terminal cleanly after a success, no enter needs pressing
			return
		}
	},
}

func init() {
	rootCmd.AddCommand(appsCmd)
}
