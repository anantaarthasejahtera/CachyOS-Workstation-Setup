package cmd

import (
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
	if err := pacman.CheckAndPromptSudo(); err != nil {
		pterm.Error.Println("❌ Sudo authentication failed. Cannot proceed.")
		return
	}

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

	var errors []string
	for _, m := range modules_list {
		w.UpdateProgress("Installing " + m.name + "...")
		if err := m.fn(); err != nil {
			errors = append(errors, m.name+": "+err.Error())
			w.Write([]byte("❌ Error installing " + m.name + ": " + err.Error() + "\n"))
		} else {
			w.Write([]byte("✅ " + m.name + " installed successfully.\n"))
		}
	}

	if len(errors) > 0 {
		w.Write([]byte("\n⚠️  Installation completed with errors:\n"))
		for _, e := range errors {
			w.Write([]byte("   - " + e + "\n"))
		}
	} else {
		w.Write([]byte("\n🎉 All modules installed successfully!\n"))
	}

	w.Close() // Close wizard before postinstall so it doesn't leave lingering windows
	
	// Summary Table
	printSummaryTable(modules_list, errors)

	if len(errors) > 0 {
		result, _ := pterm.DefaultInteractiveConfirm.
			WithDefaultText("Beberapa modul gagal diinstal. Lanjut ke Post-Install?").
			Show()
		if !result {
			return
		}
	}

	RunPostInstallSequence()
}

func printSummaryTable(modules []struct {
	id   string
	name string
	fn   func() error
}, errors []string) {
	data := pterm.TableData{{"Module", "Status"}}
	for _, m := range modules {
		status := pterm.Green("✅ OK")
		for _, e := range errors {
			if strings.HasPrefix(e, m.name+":") {
				status = pterm.Red("❌ FAIL")
				break
			}
		}
		data = append(data, []string{m.name, status})
	}
	pterm.DefaultTable.WithHasHeader().WithData(data).Render()
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

	if err := pacman.CheckAndPromptSudo(); err != nil {
		pterm.Error.Println("❌ Sudo authentication failed. Cannot proceed.")
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

	var errors []string
	for _, m := range selectedOptions {
		if strings.Contains(m, "Base System") {
			w.UpdateProgress("Configuring Base System...")
			if err := modules.InstallBaseSystem(); err != nil {
				errors = append(errors, "Base System: "+err.Error())
			}
			if err := modules.InstallSystemAndSecurity(); err != nil {
				errors = append(errors, "System Security: "+err.Error())
			}
		} else if strings.Contains(m, "Development Tools") {
			w.UpdateProgress("Setting up Dev Tools...")
			if err := modules.InstallDevAndEditors(); err != nil {
				errors = append(errors, "Development Tools: "+err.Error())
			}
		} else if strings.Contains(m, "Desktop Aesthetic") {
			w.UpdateProgress("Applying Desktop Aesthetics...")
			if err := modules.InstallDesktopAndDotfiles(); err != nil {
				errors = append(errors, "Desktop Aesthetic: "+err.Error())
			}
		} else if strings.Contains(m, "Applications & Gaming") {
			w.UpdateProgress("Installing Apps & Gaming...")
			if err := modules.InstallAppsAndGaming(); err != nil {
				errors = append(errors, "Applications & Gaming: "+err.Error())
			}
		} else if strings.Contains(m, "Mobile Dev") {
			w.UpdateProgress("Setting up Mobile Dev environment...")
			if err := modules.InstallMobile(); err != nil {
				errors = append(errors, "Mobile Dev: "+err.Error())
			}
		} else if strings.Contains(m, "Virtualization") {
			w.UpdateProgress("Configuring Virtualization...")
			if err := modules.InstallVM(); err != nil {
				errors = append(errors, "Virtualization: "+err.Error())
			}
		}
	}

	w.Close() // Close before opening postinstall dialog

	// Final summary
	if len(errors) > 0 {
		pterm.Warning.Println("Beberapa modul gagal diinstal:")
		for _, e := range errors {
			pterm.Error.Println("  - " + e)
		}
		result, _ := pterm.DefaultInteractiveConfirm.
			WithDefaultText("Lanjut ke Post-Install Wizard?").
			Show()
		if !result {
			return
		}
	}

	RunPostInstallSequence()
}

// runPostInstallWizard logic moved to RunPostInstallSequence in postinstall.go
func runPostInstallWizard() {
	RunPostInstallSequence()
}

func init() {
	installCmd.Flags().BoolVarP(&installAll, "all", "a", false, "Install all modules non-interactively")
	rootCmd.AddCommand(installCmd)
}
