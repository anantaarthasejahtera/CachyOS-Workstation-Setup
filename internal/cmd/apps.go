package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/charmbracelet/huh"
	"github.com/spf13/cobra"
)

var appsCmd = &cobra.Command{
	Use:   "apps",
	Short: "Interactive application installer",
	Long:  `Launch the sleek TUI application store to browse, search, and install extra tools.`,
	Run: func(cmd *cobra.Command, args []string) {
		var category string
		var appToInstall string
		var confirm bool

		// Step 1: Browse Categories
		err := huh.NewForm(
			huh.NewGroup(
				huh.NewSelect[string]().
					Title("🛒 Welcome to Nexus App Store").
					Description("Choose a curated category to browse").
					Options(
						huh.NewOption("🌐 Browsers & Internet", "browser"),
						huh.NewOption("👨‍💻 Development & Coding", "dev"),
						huh.NewOption("🎮 Gaming & Emulators", "gaming"),
						huh.NewOption("🎨 Design & Media", "media"),
						huh.NewOption("🔧 System Utilities", "utils"),
						huh.NewOption("❌ Exit", "exit"),
					).
					Value(&category),
			),
		).Run()

		if err != nil || category == "exit" {
			return
		}

		var appOptions []huh.Option[string]
		switch category {
		case "browser":
			appOptions = []huh.Option[string]{
				huh.NewOption("🌀 Zen Browser (Sleek & Fast)", "zen-browser-bin"),
				huh.NewOption("🛡️ Brave Browser (Ad-block Native)", "brave-bin"),
				huh.NewOption("🦊 LibreWolf (Privacy Focused)", "librewolf-bin"),
				huh.NewOption("🌐 Google Chrome", "google-chrome"),
			}
		case "dev":
			appOptions = []huh.Option[string]{
				huh.NewOption("🚀 Ghostty (GPU Accelerated Terminal)", "ghostty-git"),
				huh.NewOption("⚡ Zed Editor (Fastest Editor)", "zed-bin"),
				huh.NewOption("🤖 Cursor AI Editor", "cursor-bin"),
				huh.NewOption("💻 Visual Studio Code", "visual-studio-code-bin"),
				huh.NewOption("🐚 Lazygit (Pro Terminal Git)", "lazygit"),
				huh.NewOption("📡 Insomnia (Best API Client)", "insomnia-bin"),
				huh.NewOption("🐘 Docker Desktop", "docker-desktop"),
			}
		case "gaming":
			appOptions = []huh.Option[string]{
				huh.NewOption("🎮 Steam", "steam"),
				huh.NewOption("🕹️ Ryujinx (Switch Emulator)", "ryujinx-bin"),
				huh.NewOption("🦆 DuckStation (PS1 Emulator)", "duckstation-git"),
				huh.NewOption("🦸 Heroic Games Launcher", "heroic-games-launcher-bin"),
				huh.NewOption("👾 Discord", "discord"),
			}
		case "media":
			appOptions = []huh.Option[string]{
				huh.NewOption("📼 MPV (Pro-tier Video Player)", "mpv"),
				huh.NewOption("💎 Obsidian (Knowledge Management)", "obsidian-bin"),
				huh.NewOption("🎵 Spotify (via spotify-launcher)", "spotify-launcher"),
				huh.NewOption("🖌️ Krita (Digital Painting)", "krita"),
				huh.NewOption("✂️ Kdenlive (Video Editor)", "kdenlive"),
			}
		case "utils":
			appOptions = []huh.Option[string]{
				huh.NewOption("🔥 Fastfetch (Modern Fetch)", "fastfetch"),
				huh.NewOption("📈 Btop (Best System Monitor)", "btop"),
				huh.NewOption("📂 Zoxide (Smarter cd)", "zoxide"),
				huh.NewOption("🔒 1Password", "1password"),
				huh.NewOption("⚡ Flameshot (Screenshots)", "flameshot"),
			}
		}

		appOptions = append(appOptions, huh.NewOption("⬅️ Cancel / Back", "cancel"))

		err = huh.NewForm(
			huh.NewGroup(
				huh.NewSelect[string]().
					Title("📦 Select Application").
					Description("Choose an application to install via your package manager").
					Options(appOptions...).
					Value(&appToInstall),
			),
		).Run()

		if err != nil || appToInstall == "cancel" {
			return
		}

		// Step 3: Confirm Installation
		err = huh.NewForm(
			huh.NewGroup(
				huh.NewConfirm().
					Title(fmt.Sprintf("Install %s?", appToInstall)).
					Description("This will execute package installation on your system.").
					Value(&confirm),
			),
		).Run()

		if err != nil || !confirm {
			fmt.Println("Installation cancelled.")
			return
		}

		// Step 4: Installation Execution
		fmt.Printf("\n🚀 Installing %s...\n", appToInstall)

		// Determine package manager (yay preferred for AUR + official repo handling)
		var installCmd *exec.Cmd
		if _, err := exec.LookPath("yay"); err == nil {
			installCmd = exec.Command("yay", "-S", "--noconfirm", appToInstall)
		} else if _, err := exec.LookPath("paru"); err == nil {
			installCmd = exec.Command("paru", "-S", "--noconfirm", appToInstall)
		} else {
			installCmd = exec.Command("sudo", "pacman", "-S", "--noconfirm", appToInstall)
		}

		installCmd.Stdout = os.Stdout
		installCmd.Stderr = os.Stderr

		if err := installCmd.Run(); err != nil {
			fmt.Printf("\n❌ Failed to install %s\n", appToInstall)
			exec.Command("rofi", "-e", fmt.Sprintf("Failed to install package: %s", appToInstall)).Start()
		} else {
			fmt.Printf("\n✅ %s installed successfully!\n", appToInstall)
			exec.Command("notify-send", "App Store", fmt.Sprintf("%s installed successfully!", appToInstall)).Start()
		}

		fmt.Println("\nPress Enter to exit...")
		var dummy string
		fmt.Scanln(&dummy) // scan for Enter
	},
}

func init() {
	rootCmd.AddCommand(appsCmd)
}
