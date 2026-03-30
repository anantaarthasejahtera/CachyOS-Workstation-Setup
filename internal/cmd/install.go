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

	var errors []string
	defer func() {
		w.CloseWithStatus(len(errors) > 0)
		pacman.ResetLogger()
	}()
	pacman.SetLogger(w)

	w.Write([]byte("\n🚀 Starting Full Non-Interactive Installation...\n"))
	state.CreateBTRFSSnapperSnapshot("Pre-Nexus Full Install")

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

	// Close wizard and reset logger before postinstall dialog
	w.CloseWithStatus(len(errors) > 0)
	pacman.ResetLogger()

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
	// Module registry: each option maps to a unique ID and install function
	type moduleOption struct {
		id      string
		display string
		fn      func() error
	}

	moduleRegistry := []moduleOption{
		{"base", "📦 Base System (Yay, GPU, Kernel, Security)", func() error {
			if err := modules.InstallBaseSystem(); err != nil {
				return err
			}
			return modules.InstallSystemAndSecurity()
		}},
		{"dev", "👨‍💻 Development Tools (Docker, Go, Node, Python, Editors)", modules.InstallDevAndEditors},
		{"desktop", "🎨 Desktop Aesthetic (Hyprland, Waybar, Catppuccin)", modules.InstallDesktopAndDotfiles},
		{"apps", "🛒 Applications & Gaming (Steam, PCSX2, Zen Browser)", modules.InstallAppsAndGaming},
		{"mobile", "📱 Mobile Dev (Android SDK, Flutter)", modules.InstallMobile},
		{"vm", "🖥️ Virtualization (QEMU/KVM, Bottles)", modules.InstallVM},
	}

	var options []string
	var defaultOptions []string
	for i, m := range moduleRegistry {
		options = append(options, m.display)
		if i < 4 { // Default select the first 4 (base, dev, desktop, apps)
			defaultOptions = append(defaultOptions, m.display)
		}
	}

	selectedOptions, _ := pterm.DefaultInteractiveMultiselect.
		WithOptions(options).
		WithDefaultOptions(defaultOptions).
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

	// Build selected module list by matching display strings back to registry
	selectedModules := make(map[string]moduleOption)
	for _, sel := range selectedOptions {
		for _, m := range moduleRegistry {
			if m.display == sel {
				selectedModules[m.id] = m
				break
			}
		}
	}

	// Step 2: Run Wizard
	w, err := NewWizard("Nexus Installation Wizard", len(selectedModules))
	if err != nil {
		pterm.Error.Println("Error starting wizard:", err.Error())
		return
	}
	defer func() {
		pacman.ResetLogger()
	}()
	pacman.SetLogger(w)

	state.CreateBTRFSSnapperSnapshot("Pre-Nexus Wizard Install")

	var errors []string
	// Run in registry order to maintain dependency ordering
	for _, m := range moduleRegistry {
		if _, ok := selectedModules[m.id]; !ok {
			continue
		}
		w.UpdateProgress("Installing " + m.display + "...")
		if err := m.fn(); err != nil {
			errors = append(errors, m.display+": "+err.Error())
		}
	}

	// Close wizard and reset logger before postinstall dialog
	w.CloseWithStatus(len(errors) > 0)
	pacman.ResetLogger()

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

func init() {
	installCmd.Flags().BoolVarP(&installAll, "all", "a", false, "Install all modules non-interactively")
	rootCmd.AddCommand(installCmd)
}
