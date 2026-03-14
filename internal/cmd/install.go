package cmd

import (
	"os"
	"os/exec"
	"strings"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/modules"
	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/state"
	"github.com/pterm/pterm"
	"github.com/spf13/cobra"
)

var installAll bool

var installCmd = &cobra.Command{
	Use:   "install",
	Short: "Run the interactive workstation installer",
	Long:  `Run the full installation of CachyOS Workstation Setup. Triggers the GUI menu unless --all is specified.`,
	Run: func(cmd *cobra.Command, args []string) {
		// Removed CLI banner for a full GUI experience.
		if installAll {
			runNonInteractiveInstall()
			return
		}

		runInteractiveTUI()
	},
}

func runNonInteractiveInstall() {
	modules_list := []struct {
		id   string
		name string
		fn   func() error
	}{
		{"base", "Base System", modules.InstallBaseSystem},
		{"security", "System Security", modules.InstallSystemAndSecurity},
		{"dev", "Development & Editors", modules.InstallDevAndEditors},
		{"desktop", "Desktop & Dotfiles", modules.InstallDesktopAndDotfiles},
		{"apps", "Apps & Gaming", modules.InstallAppsAndGaming},
		{"mobile", "Mobile Development", modules.InstallMobile},
		{"vm", "Virtualization", modules.InstallVM},
	}

	w, err := NewWizard("Full Nexus Installation", len(modules_list))
	if err != nil {
		pterm.Error.Println("Error starting wizard:", err.Error())
		return
	}
	defer w.Close()
	pacman.SetLogger(w)

	w.Write([]byte("\n🚀 Starting Full Non-Interactive Installation...\n"))
	state.CreateBTRFSSnapperSnapshot("Pre-Nexus Full Install")

	for _, m := range modules_list {
		w.UpdateProgress("Installing " + m.name + "...")
		m.fn()
	}

	w.Write([]byte("\n🎉 Installation successful!\n"))
	w.Close() // Close wizard before postinstall so it doesn't leave lingering windows
	runPostInstallWizard()
}

func runInteractiveTUI() {
	// Step 1: Select Modules natively using Pterm interactive multiselect
	options := []string{
		"📦 Base System (Yay, GPU, Kernel, Security)",
		"👨‍💻 Development Tools (Docker, Go, Node, Python, Editors)",
		"🎨 Desktop Aesthetic (Hyprland, Waybar, Catppuccin)",
		"🛒 Applications & Gaming (Steam, PCSX2, Zen Browser)",
		"📱 Mobile Dev (Android SDK, Flutter)",
		"🖥️ Virtualization (QEMU/KVM, Bottles)",
	}

	selectedOptions, _ := pterm.DefaultInteractiveMultiselect.
		WithOptions(options).
		WithDefaultOptions(options[:4]). // Default select the first 4 (base, dev, desktop, apps)
		WithFilter(false).
		Show("Select CachyOS Workstation Modules to Install")

	if len(selectedOptions) == 0 {
		pterm.Warning.Println("No modules selected. Installation aborted.")
		return
	}

	// Step 2: Run Wizard
	w, err := NewWizard("Nexus Installation Wizard", len(selectedOptions))
	if err != nil {
		pterm.Error.Println("Error starting wizard:", err.Error())
		return
	}
	defer w.Close()
	pacman.SetLogger(w)

	state.CreateBTRFSSnapperSnapshot("Pre-Nexus Wizard Install")

	for _, m := range selectedOptions {
		if strings.Contains(m, "Base System") {
			w.UpdateProgress("Configuring Base System...")
			modules.InstallBaseSystem()
			modules.InstallSystemAndSecurity()
		} else if strings.Contains(m, "Development Tools") {
			w.UpdateProgress("Setting up Dev Tools...")
			modules.InstallDevAndEditors()
		} else if strings.Contains(m, "Desktop Aesthetic") {
			w.UpdateProgress("Applying Desktop Aesthetics...")
			modules.InstallDesktopAndDotfiles()
		} else if strings.Contains(m, "Applications & Gaming") {
			w.UpdateProgress("Installing Apps & Gaming...")
			modules.InstallAppsAndGaming()
		} else if strings.Contains(m, "Mobile Dev") {
			w.UpdateProgress("Setting up Mobile Dev environment...")
			modules.InstallMobile()
		} else if strings.Contains(m, "Virtualization") {
			w.UpdateProgress("Configuring Virtualization...")
			modules.InstallVM()
		}
	}

	w.Close() // Close before opening postinstall dialog
	runPostInstallWizard()
}

func runPostInstallWizard() {
	exec.Command(os.Args[0], "postinstall").Run()
}

func init() {
	installCmd.Flags().BoolVarP(&installAll, "all", "a", false, "Install all modules non-interactively")
	rootCmd.AddCommand(installCmd)
}
