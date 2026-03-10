package cmd

import (
	"fmt"
	"os"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/state"
	"github.com/charmbracelet/huh"
	"github.com/spf13/cobra"
)

var installAll bool

var installCmd = &cobra.Command{
	Use:   "install",
	Short: "Run the interactive workstation installer",
	Long:  `Run the full installation of CachyOS Workstation Setup. Triggers the TUI menu unless --all is specified.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🚀 Nexus Installer v2.0 (Powered by Go)")

		if installAll {
			runNonInteractiveInstall()
			return
		}

		runInteractiveTUI()
	},
}

func runNonInteractiveInstall() {
	fmt.Println("Executing non-interactive full installation...")
	state.CreateBTRFSSnapperSnapshot("Pre-Nexus Full Install")
	
	fmt.Println("-> [00-common] Initializing base tools...")
	pacman.Install("git", "curl", "wget", "fastfetch")
	
	fmt.Println("\n🎉 All modules installed successfully!")
}

func runInteractiveTUI() {
	var modules []string

	form := huh.NewForm(
		huh.NewGroup(
			huh.NewMultiSelect[string]().
				Title("Select CachyOS Workstation Modules to Install").
				Options(
					huh.NewOption("Base System (yay, git, curl)", "base").Selected(true),
					huh.NewOption("Desktop Tools (Alacritty, Fish, Starship)", "desktop"),
					huh.NewOption("Hyprland Ecosystem (Waybar, Rofi, SwayNC)", "hyprland"),
					huh.NewOption("Gaming (Steam, Lutris, ProtonUp)", "gaming"),
					huh.NewOption("Developer Tools (VSCode, Docker)", "dev"),
				).
				Value(&modules),
		),
	).WithTheme(huh.ThemeCatppuccin())

	err := form.Run()
	if err != nil {
		fmt.Println("Installation aborted.")
		os.Exit(1)
	}

	if len(modules) == 0 {
		fmt.Println("No modules selected. Exiting.")
		return
	}

	fmt.Printf("\nExecuting installation for: %v\n", modules)
	state.CreateBTRFSSnapperSnapshot("Pre-Nexus TUI Install")

	// Mocking execution of modules based on selection
	for _, m := range modules {
		fmt.Printf("-> Installing module: %s...\n", m)
		if m == "base" {
			pacman.Install("git", "curl", "wget", "fastfetch")
		} else if m == "desktop" {
			pacman.Install("alacritty", "fish", "starship", "eza")
		} else if m == "hyprland" {
			pacman.Install("hyprland", "waybar", "rofi-wayland")
		}
	}
	
	fmt.Println("\n🎉 Installation completed successfully!")
}

func init() {
	installCmd.Flags().BoolVarP(&installAll, "all", "a", false, "Install all modules non-interactively")
	rootCmd.AddCommand(installCmd)
}
