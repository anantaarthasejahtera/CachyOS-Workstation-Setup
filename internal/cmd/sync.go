package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/pterm/pterm"
	"github.com/spf13/cobra"
)

func (v *syncCommand) run(cmd *cobra.Command, args []string) {
	homeDir, _ := os.UserHomeDir()
	configDir := filepath.Join(homeDir, ".config")

	// Use notify-send for background progress if not in a wizard
	exec.Command("notify-send", "Nexus Sync", "☁️  Dotfiles Cloud Sync Initializing...").Start()

	// Check if git is initialized
	gitDir := filepath.Join(configDir, ".git")
	if _, err := os.Stat(gitDir); os.IsNotExist(err) {
		exec.Command("git", "-C", configDir, "init").Run()
		ignoreContent := `
# 1. Block everything by default in the root of ~/.config
/*

# 2. explicitly ALLOW critical dotfiles directories
# Window Managers & UI
!/hypr/
!/waybar/
!/rofi/
!/mako/
!/dunst/
!/wlogout/
!/swaylock/
!/cachyos-hello/

# Terminals & Shells
!/ghostty/
!/alacritty/
!/kitty/
!/wezterm/
!/fish/
!/nushell/
!/starship.toml

# Editors & Multiplexers
!/nvim/
!/helix/
!/zed/
!/tmux/
!/zellij/

# CLI Tools & Utilities
!/git/
!/lazygit/
!/bat/
!/yazi/
!/ranger/
!/fastfetch/
!/btop/
!/htop/
!/cava/
!/mpv/
!/zathura/

# Theming
!/Kvantum/
!/qt5ct/
!/qt6ct/
!/gtk-3.0/
!/gtk-4.0/
!/xsettingsd/

# 3. Always exclude nested caches and logs just in case
**/*.log
**/*.pid
**/.*
**/.cache/
**/Cache/
**/GPUCache/
`
		os.WriteFile(filepath.Join(configDir, ".gitignore"), []byte(strings.TrimSpace(ignoreContent)), 0644)
	}

	// Add and commit
	exec.Command("git", "-C", configDir, "add", ".").Run()
	statusOut, _ := exec.Command("git", "-C", configDir, "status", "--porcelain").Output()
	if len(statusOut) == 0 {
		exec.Command("notify-send", "Nexus Sync", "✅ Everything is already up to date.").Start()
		return
	}

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	commitMsg := fmt.Sprintf("chore: Auto-sync %s via Nexus", timestamp)
	exec.Command("git", "-C", configDir, "commit", "-m", commitMsg).Run()

	// Check for remote
	remoteOut, _ := exec.Command("git", "-C", configDir, "remote", "-v").Output()
	hasRemote := len(remoteOut) > 0

	if !hasRemote {
		if err := exec.Command("gh", "auth", "status").Run(); err != nil {
			result, _ := pterm.DefaultInteractiveConfirm.
				WithDefaultText("Belum terautentikasi ke GitHub. Login sekarang via browser?").
				Show()
			if result {
				exec.Command("gh", "auth", "login", "-w").Run()
			} else {
				return
			}
		}

		// Selection via Pterm
		options := []string{
			"📦 Buat Private Repo BARU (dotfiles)",
			"🔗 Link ke Repo URL yang sudah ada",
			"🚫 Lewati (Hanya Local Backup)",
		}
		selectedOption, _ := pterm.DefaultInteractiveSelect.
			WithOptions(options).
			WithDefaultText("Kemana kita harus upload dotfiles kamu?").
			Show()

		if strings.Contains(selectedOption, "Repo BARU") {
			pterm.Info.Println("Creating private repository 'dotfiles'...")
			if err := exec.Command("gh", "repo", "create", "dotfiles", "--private", "--source", configDir, "--remote", "origin", "--push").Run(); err == nil {
				hasRemote = true
				exec.Command("git", "-C", configDir, "branch", "-M", "main").Run()
			}
		} else if strings.Contains(selectedOption, "URL yang sudah ada") {
			remoteUrl, _ := pterm.DefaultInteractiveTextInput.WithDefaultText("Masukkan URL GitHub (git@github.com:user/repo.git)").Show()
			remoteUrl = strings.TrimSpace(remoteUrl)
			if remoteUrl != "" {
				exec.Command("git", "-C", configDir, "remote", "add", "origin", remoteUrl).Run()
				exec.Command("git", "-C", configDir, "branch", "-M", "main").Run()
				hasRemote = true
			}
		}
	}

	if hasRemote {
		spinner, _ := pterm.DefaultSpinner.Start("Uploading dotfiles to GitHub...")
		pushCmd := exec.Command("git", "-C", configDir, "push", "-u", "origin", "main")
		pushCmd.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0")
		if err := pushCmd.Run(); err != nil {
			spinner.Fail("Gagal upload ke Cloud. Pastikan SSH Key sudah di-setup di GitHub.")
		} else {
			spinner.Success("Dotfiles Cloud Sync Berhasil!")
			exec.Command("notify-send", "Nexus Sync", "✅ Dotfiles Cloud Sync Berhasil!").Start()
		}
	}
}

var syncCmd = &cobra.Command{
	Use:   "sync",
	Short: "Backup and sync dotfiles locally and to cloud",
	Long:  `Automatically backs up current dotfiles (.config) into a git-managed vault and pushes to a remote repository for disaster recovery.`,
	Run: func(cmd *cobra.Command, args []string) {
		s := &syncCommand{}
		s.run(cmd, args)
	},
}

type syncCommand struct{}

func init() {
	rootCmd.AddCommand(syncCmd)
}
