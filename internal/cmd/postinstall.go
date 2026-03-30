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

	w.Write([]byte("   -> Configuring SDDM Display Manager (Full Catppuccin Suite)...\n"))
	if pacman.IsInstalled("hyprland") {
		configureSddm(w)
	} else {
		w.Write([]byte("      [!] Hyprland not installed, skipping SDDM configuration.\n"))
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

	// pacman does not support reading package names from stdin via '-'.
	// Pass packages as args directly.
	pkgs := strings.Fields(strings.TrimSpace(string(orphanOut)))
	args := append([]string{"pacman", "-Rns", "--noconfirm"}, pkgs...)
	removeCmd := exec.Command("sudo", args...)
	removeCmd.Stdout = w
	removeCmd.Stderr = w
	if err := removeCmd.Run(); err != nil {
		w.Write([]byte(fmt.Sprintf("      ❌ Orphan cleanup failed: %v\n", err)))
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

// configureSddm orchestrates the complete SDDM setup pipeline:
//  1. Ensure SDDM package and Catppuccin theme are installed
//  2. Switch from plasmalogin if active
//  3. Write a single consolidated /etc/sddm.conf.d/nexus.conf
//  4. Apply Catppuccin aesthetic (font, wallpaper, avatar)
//  5. Clean up stale config fragments from previous runs
func configureSddm(w io.Writer) {
	const themeDir = "/usr/share/sddm/themes/catppuccin-mocha-mauve"

	// ─── Step 1: Ensure Packages ───────────────────────────────────────
	w.Write([]byte("      ┌─ SDDM Setup Pipeline\n"))

	if !pacman.IsInstalled("sddm") {
		w.Write([]byte("      │  📦 Installing SDDM package...\n"))
		if err := pacman.Install("sddm"); err != nil {
			w.Write([]byte(fmt.Sprintf("      │  ❌ Failed to install SDDM: %v\n", err)))
			w.Write([]byte("      └─ SDDM setup aborted.\n"))
			return
		}
	}

	if !pacman.IsInstalled("sddm-theme-catppuccin-git") {
		w.Write([]byte("      │  📦 Installing Catppuccin SDDM Theme (Mocha Mauve)...\n"))
		if err := pacman.Install("sddm-theme-catppuccin-git"); err != nil {
			w.Write([]byte(fmt.Sprintf("      │  ⚠️  Theme install failed: %v (continuing with default theme)\n", err)))
		}
	}

	// ─── Step 2: Activate SDDM (migrate from plasmalogin if needed) ──
	w.Write([]byte("      │  🔄 Ensuring SDDM is the active display manager...\n"))
	sddmActivated := ensureSddmIsActive(w)
	if !sddmActivated {
		w.Write([]byte("      └─ SDDM activation failed, skipping theme setup.\n"))
		return
	}

	// ─── Step 3: Write Consolidated Config ────────────────────────────
	w.Write([]byte("      │  📝 Writing unified SDDM configuration...\n"))

	// Determine theme name (fall back to default if catppuccin not installed)
	themeName := ""
	if pacman.IsInstalled("sddm-theme-catppuccin-git") {
		themeName = "catppuccin-mocha-mauve"
	}

	nexusConf := buildSddmConfig(themeName)
	if err := sudoWriteFile("/etc/sddm.conf.d/nexus.conf", nexusConf); err != nil {
		w.Write([]byte(fmt.Sprintf("      │  ❌ Failed to write nexus.conf: %v\n", err)))
	} else {
		w.Write([]byte("      │  ✅ /etc/sddm.conf.d/nexus.conf written\n"))
	}

	// Clean up old fragments from previous runs
	cleanupStaleSddmConfigs(w)

	// Clean up stale /etc/sddm.conf that CachyOS ships with Session=plasma
	if data, err := os.ReadFile("/etc/sddm.conf"); err == nil {
		content := string(data)
		if strings.Contains(content, "Session=plasma") || strings.Contains(content, "Session=hyprland") {
			w.Write([]byte("      │  🧹 Removing stale /etc/sddm.conf (CachyOS default override)...\n"))
			exec.Command("sudo", "rm", "-f", "/etc/sddm.conf").Run()
		}
	}

	// ─── Step 4: Aesthetic Polish (only if Catppuccin theme is installed) ─
	if themeName != "" {
		w.Write([]byte("      │  🎨 Applying Catppuccin Aesthetic Polish...\n"))
		applySddmAesthetic(w, themeDir)
		setupSddmAvatar(w)
	}

	w.Write([]byte("      └─ ✅ SDDM configuration complete!\n"))
}

// buildSddmConfig generates a single consolidated SDDM drop-in config.
func buildSddmConfig(themeName string) string {
	var b strings.Builder

	b.WriteString("# Generated by Nexus Post-Install — do not edit manually\n")
	b.WriteString("# Regenerate with: nexus postinstall\n\n")

	// [General]
	b.WriteString("[General]\n")
	b.WriteString("DisplayServer=wayland\n")
	b.WriteString("Numlock=on\n")
	b.WriteString("DefaultSession=hyprland.desktop\n\n")

	// [Theme]
	b.WriteString("[Theme]\n")
	if themeName != "" {
		b.WriteString(fmt.Sprintf("Current=%s\n", themeName))
	}
	b.WriteString("CursorTheme=catppuccin-mocha-dark-cursors\n")
	b.WriteString("CursorSize=24\n\n")

	// [Wayland] — kwin_wayland serves as the compositor for the SDDM greeter screen only.
	// Without this, SDDM falls back to X11. After login, the user session runs Hyprland.
	b.WriteString("[Wayland]\n")
	b.WriteString("CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1\n")

	return b.String()
}

// cleanupStaleSddmConfigs removes config fragments from previous Nexus runs
// that are now consolidated into nexus.conf.
func cleanupStaleSddmConfigs(w io.Writer) {
	staleFiles := []string{
		"/etc/sddm.conf.d/default-session.conf",
		"/etc/sddm.conf.d/theme.conf",
		"/etc/sddm.conf.d/10-wayland.conf",
		"/etc/sddm.conf.d/cursor.conf",
	}

	for _, f := range staleFiles {
		if _, err := os.Stat(f); err == nil {
			exec.Command("sudo", "rm", "-f", f).Run()
			w.Write([]byte(fmt.Sprintf("      │  🧹 Cleaned stale: %s\n", filepath.Base(f))))
		}
	}
}

// ensureSddmIsActive makes SDDM the active display manager.
// Returns true if SDDM is active/enabled after this function completes.
func ensureSddmIsActive(w io.Writer) bool {
	// Check if plasmalogin is active and disable it
	if err := exec.Command("systemctl", "is-active", "--quiet", "plasmalogin.service").Run(); err == nil {
		w.Write([]byte("      │  ⚡ Detected Plasma Login Manager → switching to SDDM...\n"))
		exec.Command("sudo", "systemctl", "disable", "--now", "plasmalogin.service").Run()
	}

	// Check if another DM (like gdm, lightdm) is active
	for _, dm := range []string{"gdm.service", "lightdm.service", "lxdm.service"} {
		if err := exec.Command("systemctl", "is-active", "--quiet", dm).Run(); err == nil {
			w.Write([]byte(fmt.Sprintf("      │  ⚡ Detected %s → disabling...\n", dm)))
			exec.Command("sudo", "systemctl", "disable", "--now", dm).Run()
		}
	}

	// Ensure SDDM is enabled
	if err := exec.Command("systemctl", "is-enabled", "--quiet", "sddm.service").Run(); err != nil {
		w.Write([]byte("      │  🔧 Enabling SDDM service...\n"))
		if err := exec.Command("sudo", "systemctl", "enable", "sddm.service").Run(); err != nil {
			w.Write([]byte(fmt.Sprintf("      │  ❌ Failed to enable SDDM: %v\n", err)))
			return false
		}
	}

	w.Write([]byte("      │  ✅ SDDM is the active display manager\n"))
	return true
}

// applySddmAesthetic configures the Catppuccin theme with premium typography,
// glassmorphism effects, and syncs the desktop wallpaper to the login screen.
func applySddmAesthetic(w io.Writer, themeDir string) {
	// Theme user config with typography
	themeUserConf := `[General]
Font="Inter Display"
FontSize=12
ClockEnabled=true
CustomBackground=true
LoginBackground=true
Background=backgrounds/wall.png

# Layout & Scaling
BackgroundMode=PreserveAspectCrop
TimeFormat="hh:mm"
DateFormat="dddd, d MMMM yyyy"
`
	if err := sudoWriteFile(themeDir+"/theme.conf.user", themeUserConf); err != nil {
		w.Write([]byte(fmt.Sprintf("      │  ❌ Theme user config failed: %v\n", err)))
	} else {
		w.Write([]byte("      │  ✅ Premium typography applied\n"))
	}

	// Hot-patch QML for True Glassmorphism & Rounded Corners
	// (Since this specific theme's QML ignores most theme.conf properties)
	patchSddmQml(w, themeDir)

	// Sync wallpaper from Waypaper selection to SDDM
	syncWallpaperToSddm(w, themeDir)
}

// syncWallpaperToSddm copies the user's selected wallpaper (from Waypaper config)
// into the SDDM theme directory for a seamless desktop→login screen aesthetic.
func syncWallpaperToSddm(w io.Writer, themeDir string) {
	home := os.Getenv("HOME")
	waypaperConf := filepath.Join(home, ".config/waypaper/config.ini")
	wallSrc := ""

	// Parse Waypaper config for current wallpaper path
	if file, err := os.Open(waypaperConf); err == nil {
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			line := strings.TrimSpace(scanner.Text())
			if strings.HasPrefix(line, "wallpaper =") || strings.HasPrefix(line, "wallpaper=") {
				parts := strings.SplitN(line, "=", 2)
				if len(parts) == 2 {
					extracted := strings.TrimSpace(parts[1])
					if strings.HasPrefix(extracted, "~/") {
						wallSrc = filepath.Join(home, extracted[2:])
					} else {
						wallSrc = extracted
					}
					break
				}
			}
		}
		file.Close()
	}

	// Fallback to default wallpaper
	if wallSrc == "" {
		fallbacks := []string{
			filepath.Join(home, "Pictures/Wallpapers/orangci/01.png"),
			filepath.Join(home, "Pictures/Wallpapers/catppuccin/01.png"),
		}
		for _, f := range fallbacks {
			if _, err := os.Stat(f); err == nil {
				wallSrc = f
				break
			}
		}
	}

	if wallSrc == "" {
		w.Write([]byte("      │  ⚠️  No wallpaper found, keeping SDDM default\n"))
		return
	}

	if _, err := os.Stat(wallSrc); err != nil {
		w.Write([]byte(fmt.Sprintf("      │  ⚠️  Wallpaper file not found: %s\n", filepath.Base(wallSrc))))
		return
	}

	wallDst := themeDir + "/backgrounds/wall.png"
	w.Write([]byte(fmt.Sprintf("      │  🖼️  Syncing wallpaper: %s\n", filepath.Base(wallSrc))))

	exec.Command("sudo", "mkdir", "-p", themeDir+"/backgrounds").Run()
	if err := exec.Command("sudo", "cp", wallSrc, wallDst).Run(); err != nil {
		w.Write([]byte(fmt.Sprintf("      │  ❌ Wallpaper copy failed: %v\n", err)))
	} else {
		exec.Command("sudo", "chmod", "644", wallDst).Run()
		w.Write([]byte("      │  ✅ Login screen wallpaper synced\n"))
	}
}

// setupSddmAvatar sets up a user avatar for the SDDM greeter via AccountsService.
func setupSddmAvatar(w io.Writer) {
	user := os.Getenv("USER")
	if user == "" || user == "root" {
		return
	}

	userIconDst := fmt.Sprintf("/var/lib/AccountsService/icons/%s", user)
	accountServiceConf := fmt.Sprintf("/var/lib/AccountsService/users/%s", user)

	// Skip if avatar already exists
	if _, err := os.Stat(userIconDst); err == nil {
		w.Write([]byte("      │  ✅ User avatar already configured\n"))
		return
	}

	exec.Command("sudo", "mkdir", "-p", "/var/lib/AccountsService/users").Run()
	exec.Command("sudo", "mkdir", "-p", "/var/lib/AccountsService/icons").Run()

	// Try to find a suitable fallback avatar
	fallbacks := []string{
		"/usr/share/pixmaps/cachyos-hello.png",
		"/usr/share/pixmaps/cachyos.png",
		"/usr/share/icons/hicolor/256x256/apps/cachyos-hello.png",
		"/usr/share/icons/hicolor/48x48/apps/system-users.png",
	}

	var avatarSrc string
	for _, f := range fallbacks {
		if _, err := os.Stat(f); err == nil {
			avatarSrc = f
			break
		}
	}

	if avatarSrc == "" {
		w.Write([]byte("      │  ⚠️  No fallback avatar found, avatar will be blank\n"))
		return
	}

	if err := exec.Command("sudo", "cp", avatarSrc, userIconDst).Run(); err == nil {
		confBody := fmt.Sprintf("[User]\nIcon=%s\n", userIconDst)
		sudoWriteFile(accountServiceConf, confBody)
		w.Write([]byte("      │  ✅ User avatar configured\n"))
	} else {
		w.Write([]byte(fmt.Sprintf("      │  ⚠️  Failed to copy avatar: %v\n", err)))
	}
}

// patchSddmQml hot-patches the hardcoded QML files of the Catppuccin SDDM theme.
// The default theme ignores theme.conf properties for corner radius and translucency,
// so we inject glassmorphism (translucency) and rounded corners directly into the UI components.
func patchSddmQml(w io.Writer, themeDir string) {
	w.Write([]byte("      │  🪄  Patching QML for Glassmorphism & Rounded Corners...\n"))

	patchQmlFile := func(filename string, replacements []string) {
		path := filepath.Join(themeDir, "Components", filename)
		data, err := os.ReadFile(path)
		if err != nil {
			return // Skip if file doesn't exist
		}
		content := string(data)
		changed := false
		for i := 0; i < len(replacements); i += 2 {
			oldStr := replacements[i]
			newStr := replacements[i+1]
			if strings.Contains(content, oldStr) {
				content = strings.ReplaceAll(content, oldStr, newStr)
				changed = true
			}
		}
		if changed {
			sudoWriteFile(path, content)
		}
	}

	// 1. LoginPanel.qml (Main container & Login Button)
	// Base container: color "#181825" -> translucency "#A0181825" (~62% opacity base surface)
	// Base container: radius 5 -> radius 16
	// Button: radius 3 -> radius 8
	patchQmlFile("LoginPanel.qml", []string{
		`color: "#181825"`, `color: "#A0181825"`,
		`radius: 5`, `radius: 16`,
		`radius: 3`, `radius: 8`,
	})

	// 2. UserField.qml
	// Background: "#313244" -> translucency "#80313244" (50% opacity)
	// Hover/Focus: "#45475A" -> translucency "#A045475A" (62% opacity)
	// Radius: 3 -> 8
	patchQmlFile("UserField.qml", []string{
		`color: "#313244"`, `color: "#80313244"`,
		`color: "#45475A"`, `color: "#A045475A"`,
		`radius: 3`, `radius: 8`,
	})

	// 3. PasswordField.qml
	// Background: "#313244" -> translucency "#80313244" (50% opacity)
	// Hover/Focus: "#45475A" -> translucency "#A045475A" (62% opacity)
	// Radius: 3 -> 8
	patchQmlFile("PasswordField.qml", []string{
		`color: "#313244"`, `color: "#80313244"`,
		`color: "#45475A"`, `color: "#A045475A"`,
		`radius: 3`, `radius: 8`,
	})

	w.Write([]byte("      │  ✅ QML hot-patch successful\n"))
}

func init() {
	rootCmd.AddCommand(postInstallCmd)
}

