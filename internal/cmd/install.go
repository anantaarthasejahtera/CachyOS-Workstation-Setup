package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/modules"
	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/state"
	"github.com/charmbracelet/huh"
	"github.com/charmbracelet/lipgloss"
	"github.com/spf13/cobra"
)

var installAll bool

var installCmd = &cobra.Command{
	Use:   "install",
	Short: "Run the interactive workstation installer",
	Long:  `Run the full installation of CachyOS Workstation Setup. Triggers the TUI menu unless --all is specified.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🚀 Nexus Installer v2.0 (Powered by pure Go)")

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

	modules.InstallBaseSystem()
	modules.InstallSystemAndSecurity()
	modules.InstallDevAndEditors()
	modules.InstallDesktopAndDotfiles()
	modules.InstallAppsAndGaming()
	modules.InstallMobile()
	modules.InstallVM()

	fmt.Println("\n🎉 All massive porting modules installed successfully!")

	// Automatically trigger post-install wizard for repo cloud syncing
	runPostInstallWizard()
}

func runInteractiveTUI() {
	var selectedModules []string

	form := huh.NewForm(
		huh.NewGroup(
			huh.NewMultiSelect[string]().
				Title("Select CachyOS Workstation Modules to Install").
				Options(
					huh.NewOption("Base System (Base, Yay, GPU, Kernel, Security)", "base").Selected(true),
					huh.NewOption("Development Tools (Docker, Go, Node, Python, Editors)", "dev").Selected(true),
					huh.NewOption("Desktop Aesthetic (Hyprland, Waybar, Catppuccin)", "desktop").Selected(true),
					huh.NewOption("Applications & Gaming (Steam, PCsX2, Zen Browser)", "apps").Selected(true),
					huh.NewOption("Mobile Dev (Android SDK, Flutter)", "mobile"),
					huh.NewOption("Virtualization (QEMU/KVM, Bottles)", "vm"),
				).
				Value(&selectedModules),
		),
	).WithTheme(huh.ThemeCatppuccin())

	err := form.Run()
	if err != nil {
		fmt.Println("Installation aborted.")
		os.Exit(1)
	}

	if len(selectedModules) == 0 {
		fmt.Println("No modules selected. Exiting.")
		return
	}

	fmt.Printf("\nExecuting installation for: %v\n", selectedModules)
	state.CreateBTRFSSnapperSnapshot("Pre-Nexus TUI Install")

	for _, m := range selectedModules {
		fmt.Printf("\n-> Executing Selection: %s...\n", m)
		if m == "base" {
			modules.InstallBaseSystem()
			modules.InstallSystemAndSecurity()
		} else if m == "dev" {
			modules.InstallDevAndEditors()
		} else if m == "desktop" {
			modules.InstallDesktopAndDotfiles()
		} else if m == "apps" {
			modules.InstallAppsAndGaming()
		} else if m == "mobile" {
			modules.InstallMobile()
		} else if m == "vm" {
			modules.InstallVM()
		}
	}

	fmt.Println("\n🎉 Installation completed successfully!")

	// Automatically trigger post-install wizard for repo cloud syncing
	runPostInstallWizard()
}

func runPostInstallWizard() {
	fmt.Println("\n" + lipgloss.NewStyle().Foreground(lipgloss.Color("#cba6f7")).Bold(true).Render("✨ Launching Final Post-Install Wizard..."))
	exec.Command(os.Args[0], "postinstall").Run()
}

func init() {
	installCmd.Flags().BoolVarP(&installAll, "all", "a", false, "Install all modules non-interactively")
	rootCmd.AddCommand(installCmd)
}
