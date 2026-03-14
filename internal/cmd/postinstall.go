package cmd

import (
	"os"
	"os/exec"
	"strings"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
	"github.com/pterm/pterm"
	"github.com/spf13/cobra"
)

var postInstallCmd = &cobra.Command{
	Use:   "postinstall",
	Short: "First boot onboarding wizard",
	Long:  `Guides the user through post-installation checks, wallpaper setup, and cloud sync.`,
	Run: func(cmd *cobra.Command, args []string) {
		// Welcome Prompt
		pterm.Info.Println("Selamat! Instalasi modul utama selesai.")
		result, _ := pterm.DefaultInteractiveConfirm.
			WithDefaultText("Apakah kamu ingin menjalankan Post-Install Wizard untuk optimasi akhir (Health Check, Wallpaper, Cloud Sync)?").
			Show()
		if !result {
			return
		}

		steps := []string{"System Health Check", "Desktop Aesthetics", "Cloud Sync & Backups", "System Finalization"}
		w, _ := NewWizard("Nexus Post-Install", len(steps))
		defer w.Close()

		w.Write([]byte("\n🚀 NEXUS POST-INSTALL WIZARD - Starting...\n"))

		// 1. Run Health Check (Doctor)
		w.UpdateProgress("🩺 Running System Health Check...")
		doctorCmd := exec.Command(os.Args[0], "doctor")
		doctorOutput, _ := doctorCmd.CombinedOutput()
		w.Write(doctorOutput)

		if doctorCmd.ProcessState.ExitCode() != 0 {
			result, _ := pterm.DefaultInteractiveConfirm.
				WithDefaultText("Nexus Doctor menemukan masalah pada sistem kamu. Lanjut ke setup berikutnya?").
				Show()
			if !result {
				w.Write([]byte("Post-Install aborted due to doctor warnings.\n"))
				return
			}
		} else {
			w.Write([]byte("\n✅ [Intelligence] System health verified. Proceeding...\n"))
		}

		// 2. Set Wallpaper (Interactive)
		w.UpdateProgress("🎨 Configuring Desktop Aesthetics...")
		if os.Getenv("WAYLAND_DISPLAY") != "" || os.Getenv("DISPLAY") != "" {
			if _, err := exec.LookPath("waypaper"); err == nil {
				w.Write([]byte("   Launching Waypaper...\n"))
				exec.Command("waypaper").Run()
				w.Write([]byte("   ✅ Wallpaper configuration saved.\n"))
			} else {
				w.Write([]byte("   [!] Waypaper not found, skipping wallpaper setup.\n"))
			}
		} else {
			w.Write([]byte("   [!] No active display (TTY mode). Run 'waypaper' later from GUI.\n"))
		}

		// 3. Sync Dotfiles (Interactive)
		w.UpdateProgress("☁️  Finalizing Cloud Sync & Backups...")
		syncCmd := exec.Command(os.Args[0], "sync")
		// For sync, we might need real interactive input if it's not GUI-fied yet.
		// But let's pipe its output to the wizard log anyway.
		syncCmd.Stdout = w
		syncCmd.Stderr = w
		if err := syncCmd.Run(); err != nil {
			w.Write([]byte("   [!] Cloud Sync failed or was cancelled.\n"))
		} else {
			w.Write([]byte("   ✅ Cloud Sync completed successfully.\n"))
		}

		// 4. System Finalization (Cleanups, Caches, SDDM, Shells)
		w.UpdateProgress("⚙️  System Finalization & SDDM Configuration...")
		
		pacman.CheckAndPromptSudo()

		w.Write([]byte("   -> Setting up XDG User Directories...\n"))
		exec.Command("xdg-user-dirs-update").Run()

		w.Write([]byte("   -> Generating Font and Bat Caches...\n"))
		exec.Command("fc-cache", "-fv").Run()
		exec.Command("bat", "cache", "--build").Run()

		w.Write([]byte("   -> Enforcing Fish Shell for User and Root...\n"))
		user := os.Getenv("USER")
		exec.Command("sudo", "chsh", "-s", "/usr/bin/fish", user).Run()
		exec.Command("sudo", "chsh", "-s", "/usr/bin/fish", "root").Run()

		w.Write([]byte("   -> Configuring SDDM & Hyprland Autostart...\n"))
		if pacman.IsInstalled("hyprland") {
			// Force SDDM to remember Hyprland
			sudoWriteFile("/etc/sddm.conf.d/default-session.conf", "[Autologin]\nSession=hyprland\n")
			// Apply Catppuccin Theme if installed
			if pacman.IsInstalled("sddm-theme-catppuccin-git") {
				sudoWriteFile("/etc/sddm.conf.d/theme.conf", "[Theme]\nCurrent=catppuccin-mocha\n")
			}
		}

		w.Write([]byte("   -> Performing Deep Orphan Package Cleanup...\n"))
		orphanCmd := exec.Command("sh", "-c", "pacman -Qtdq")
		orphanOut, err := orphanCmd.Output()
		if err == nil && len(strings.TrimSpace(string(orphanOut))) > 0 {
			exec.Command("sh", "-c", "sudo pacman -Rns $(pacman -Qtdq) --noconfirm").Run()
			w.Write([]byte("      ✅ Orphan packages removed gracefully.\n"))
		} else {
			w.Write([]byte("      ✅ No orphan packages found.\n"))
		}

		// Final Success Dialog
		w.Write([]byte("\n✅ POST-INSTALL COMPLETE! Enjoy your new workstation.\n"))
		
		finishMsg := "🎉 Semua tahap instalasi dan optimasi sudah SELESAI!\n\nSistem kamu sekarang sudah 'Ready to Work'.\n\nTips:\n- Tekan Super + X untuk Command Center.\n- Tekan Super + Enter untuk Ghostty Terminal."
		pterm.Info.Println(finishMsg)

		reboot, _ := pterm.DefaultInteractiveConfirm.
			WithDefaultText("⚙️  Semua tahap Workstation selesai. Reboot sistem sekarang?").
			Show()
		if reboot {
			exec.Command("sudo", "reboot").Run()
		}
	},
}

// sudoWriteFile is a helper to securely write configuration files using sudo
func sudoWriteFile(path, content string) {
	cmd := exec.Command("sudo", "sh", "-c", "echo -e '"+content+"' > "+path)
	cmd.Run()
}

func init() {
	rootCmd.AddCommand(postInstallCmd)
}
