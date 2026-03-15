package cmd

import (
	"bufio"
	"bytes"
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
	"github.com/pterm/pterm"
	"github.com/spf13/cobra"
)

var postInstallCmd = &cobra.Command{
	Use:   "postinstall",
	Short: "First boot onboarding wizard",
	Long:  `Guides the user through post-installation checks, wallpaper setup, and cloud sync.`,
	Run: func(cmd *cobra.Command, args []string) {
		RunPostInstallSequence()
	},
}

// RunPostInstallSequence executes the full post-installation cycle.
// This is decoupled from the Cobra command to allow direct calls from install.go.
func RunPostInstallSequence() {
	// Welcome Prompt
	pterm.Info.Println("Selamat! Instalasi modul utama selesai.")
	result, _ := pterm.DefaultInteractiveConfirm.
		WithDefaultText("Apakah kamu ingin menjalankan Post-Install Wizard untuk optimasi akhir (Health Check, Wallpaper, Cloud Sync)?").
		Show()
	if !result {
		return
	}

	steps := []string{"System Health Check", "Desktop Aesthetics", "Cloud Sync & Backups", "System Finalization"}
	w, err := NewWizard("Nexus Post-Install", len(steps))
	if err != nil {
		pterm.Error.Printf("Failed to start wizard: %v\n", err)
		return
	}
	defer w.Close()

	w.Write([]byte("\n🚀 NEXUS POST-INSTALL WIZARD - Starting...\n"))

	// 1. Run Health Check (Doctor)
	w.UpdateProgress("🩺 Running System Health Check...")
	doctorCmd := exec.Command(os.Args[0], "doctor")
	doctorOutput, err := doctorCmd.CombinedOutput()
	w.Write(doctorOutput)

	if err != nil {
		// Command failed to run or exited non-zero
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

	// 2. Set Wallpaper (Interactive) — with timeout to prevent indefinite blocking
	w.UpdateProgress("🎨 Configuring Desktop Aesthetics...")
	if os.Getenv("WAYLAND_DISPLAY") != "" || os.Getenv("DISPLAY") != "" {
		if _, err := exec.LookPath("waypaper"); err == nil {
			w.Write([]byte("   -> Launching Waypaper (auto-closes in 5 minutes)...\n"))
			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
			defer cancel()
			if err := exec.CommandContext(ctx, "waypaper").Run(); err != nil {
				if ctx.Err() == context.DeadlineExceeded {
					w.Write([]byte("   [!] Waypaper timed out after 5 minutes, continuing...\n"))
				} else {
					w.Write([]byte(fmt.Sprintf("   [!] Waypaper exited with error: %v\n", err)))
				}
			} else {
				w.Write([]byte("   ✅ Wallpaper configuration saved.\n"))
			}
		} else {
			w.Write([]byte("   [!] Waypaper not found, skipping wallpaper setup.\n"))
		}
	} else {
		w.Write([]byte("   [!] No active display (TTY mode). Run 'waypaper' later from GUI.\n"))
	}

	// 3. Sync Dotfiles (Interactive) — forward stdin for interactive prompts
	w.UpdateProgress("☁️  Finalizing Cloud Sync & Backups...")
	syncCmd := exec.Command(os.Args[0], "sync")
	syncCmd.Stdin = os.Stdin
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
	if err := exec.Command("xdg-user-dirs-update").Run(); err != nil {
		w.Write([]byte(fmt.Sprintf("      [!] xdg-user-dirs-update failed: %v\n", err)))
	}

	w.Write([]byte("   -> Generating Font Cache...\n"))
	fcCmd := exec.Command("fc-cache", "-fv")
	fcCmd.Stdout = w
	fcCmd.Stderr = w
	if err := fcCmd.Run(); err != nil {
		w.Write([]byte(fmt.Sprintf("      [!] fc-cache failed: %v\n", err)))
	}

	w.Write([]byte("   -> Building Bat Syntax Cache...\n"))
	batCmd := exec.Command("bat", "cache", "--build")
	batCmd.Stdout = w
	batCmd.Stderr = w
	if err := batCmd.Run(); err != nil {
		w.Write([]byte(fmt.Sprintf("      [!] bat cache build failed: %v\n", err)))
	}

	w.Write([]byte("   -> Enforcing Fish Shell for User and Root...\n"))
	user := os.Getenv("USER")
	if user == "" {
		w.Write([]byte("      [!] $USER not set, skipping chsh.\n"))
	} else {
		if err := exec.Command("sudo", "chsh", "-s", "/usr/bin/fish", user).Run(); err != nil {
			w.Write([]byte(fmt.Sprintf("      [!] chsh for %s failed: %v\n", user, err)))
		}
		if err := exec.Command("sudo", "chsh", "-s", "/usr/bin/fish", "root").Run(); err != nil {
			w.Write([]byte(fmt.Sprintf("      [!] chsh for root failed: %v\n", err)))
		}
	}

	w.Write([]byte("   -> Configuring SDDM & Hyprland Autostart...\n"))
	if pacman.IsInstalled("hyprland") {
		// Set Hyprland as the default session (not auto-login)
		sddmSessionConf := "[General]\nDefaultSession=hyprland.desktop\n"
		if err := sudoWriteFile("/etc/sddm.conf.d/default-session.conf", sddmSessionConf); err != nil {
			w.Write([]byte(fmt.Sprintf("      ❌ SDDM session config GAGAL: %v\n", err)))
		} else {
			w.Write([]byte("      ✅ SDDM session → Hyprland applied.\n"))
		}
		// Apply Catppuccin Theme if installed (mauve = our accent color)
		if pacman.IsInstalled("sddm-theme-catppuccin-git") {
			if err := sudoWriteFile("/etc/sddm.conf.d/theme.conf", "[Theme]\nCurrent=catppuccin-mocha-mauve\n"); err != nil {
				w.Write([]byte(fmt.Sprintf("      ❌ SDDM theme config GAGAL: %v\n", err)))
			} else {
				w.Write([]byte("      ✅ SDDM theme → Catppuccin Mocha Mauve applied.\n"))
			}
			setupSddmAesthetic(w)
		}
	}

	w.Write([]byte("   -> Performing Deep Orphan Package Cleanup...\n"))
	cleanupOrphanPackages(w)

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
}

// cleanupOrphanPackages removes orphan packages in a single pass,
// piping the package list directly via stdin to avoid TOCTOU races.
func cleanupOrphanPackages(w io.Writer) {
	orphanOut, err := exec.Command("pacman", "-Qtdq").Output()
	if err != nil || len(strings.TrimSpace(string(orphanOut))) == 0 {
		w.Write([]byte("      ✅ No orphan packages found.\n"))
		return
	}

	// Pipe the captured list directly to pacman -Rns via stdin (single pass, no shell expansion)
	removeCmd := exec.Command("sudo", "pacman", "-Rns", "--noconfirm", "-")
	removeCmd.Stdin = bytes.NewReader(orphanOut)
	removeCmd.Stdout = w
	removeCmd.Stderr = w
	if err := removeCmd.Run(); err != nil {
		// Fallback: pass packages as args directly (some pacman versions don't support stdin)
		pkgs := strings.Fields(strings.TrimSpace(string(orphanOut)))
		args := append([]string{"pacman", "-Rns", "--noconfirm"}, pkgs...)
		fallbackCmd := exec.Command("sudo", args...)
		fallbackCmd.Stdout = w
		fallbackCmd.Stderr = w
		if err := fallbackCmd.Run(); err != nil {
			w.Write([]byte(fmt.Sprintf("      ❌ Orphan cleanup failed: %v\n", err)))
		} else {
			w.Write([]byte("      ✅ Orphan packages removed gracefully.\n"))
		}
	} else {
		w.Write([]byte("      ✅ Orphan packages removed gracefully.\n"))
	}
}

// sudoWriteFile writes a config file via sudo tee, creating parent dirs if needed.
// Returns an error if the write fails instead of silently discarding it.
func sudoWriteFile(path, content string) error {
	// Ensure parent directory exists
	dir := filepath.Dir(path)
	if err := exec.Command("sudo", "mkdir", "-p", dir).Run(); err != nil {
		return fmt.Errorf("mkdir -p %s: %w", dir, err)
	}

	cmd := exec.Command("sudo", "tee", path)
	cmd.Stdin = strings.NewReader(content)
	cmd.Stdout = io.Discard
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("tee %s: %s", path, strings.TrimSpace(stderr.String()))
	}
	return nil
}

// setupSddmAesthetic polishes the SDDM login screen to match our desktop:
// - Overrides font to Inter (consistent with GTK, Waybar, Rofi)
// - Copies our Catppuccin wallpaper as the SDDM background
func setupSddmAesthetic(w io.Writer) {
	const themeDir = "/usr/share/sddm/themes/catppuccin-mocha-mauve"

	// Override font and size via theme.conf.user (takes priority over theme.conf)
	w.Write([]byte("      -> SDDM: Overriding font to Inter...\n"))
	themeUserConf := "[General]\nFont=\"Inter\"\nFontSize=10\n"
	if err := sudoWriteFile(themeDir+"/theme.conf.user", themeUserConf); err != nil {
		w.Write([]byte(fmt.Sprintf("      ❌ SDDM font override GAGAL: %v\n", err)))
	}

	// Synergistic approach: Sync SDDM wallpaper with user's Waypaper choice
	home := os.Getenv("HOME")
	waypaperConf := filepath.Join(home, ".config/waypaper/config.ini")
	wallSrc := ""

	if file, err := os.Open(waypaperConf); err == nil {
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			line := strings.TrimSpace(scanner.Text())
			if strings.HasPrefix(line, "wallpaper =") {
				parts := strings.SplitN(line, "=", 2)
				if len(parts) == 2 {
					extracted := strings.TrimSpace(parts[1])
					// Expand ~ to full path
					if strings.HasPrefix(extracted, "~/") {
						wallSrc = filepath.Join(home, extracted[2:])
					} else {
						wallSrc = extracted
					}
					break
				}
			}
		}
		file.Close() // Close explicitly instead of relying on defer inside a non-defer scope
	}

	// Fallback to initial default if waypaper isn't configured yet
	if wallSrc == "" {
		wallSrc = filepath.Join(home, "Pictures/Wallpapers/orangci/01.png")
	}

	wallDst := themeDir + "/backgrounds/wall.png"

	if _, err := os.Stat(wallSrc); err == nil {
		w.Write([]byte(fmt.Sprintf("      -> SDDM: Syncing Waypaper selection to login screen (%s)...\n", filepath.Base(wallSrc))))
		if err := exec.Command("sudo", "cp", wallSrc, wallDst).Run(); err != nil {
			w.Write([]byte(fmt.Sprintf("      ❌ SDDM wallpaper copy GAGAL: %v\n", err)))
		} else {
			// Ensure it's readable by sddm user
			if err := exec.Command("sudo", "chmod", "644", wallDst).Run(); err != nil {
				w.Write([]byte(fmt.Sprintf("      [!] chmod on SDDM wallpaper failed: %v\n", err)))
			}
			w.Write([]byte("      ✅ SDDM aesthetic polish applied.\n"))
		}
	} else {
		w.Write([]byte(fmt.Sprintf("      [!] Wallpaper source not found (%s), keeping SDDM default background.\n", wallSrc)))
	}
}

func init() {
	rootCmd.AddCommand(postInstallCmd)
}
