package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/spf13/cobra"
)

var syncCmd = &cobra.Command{
	Use:   "sync",
	Short: "Backup and sync dotfiles locally and to cloud",
	Long:  `Automatically backs up current dotfiles (.config) into a git-managed vault and pushes to a remote repository for disaster recovery.`,
	Run: func(cmd *cobra.Command, args []string) {
		homeDir, _ := os.UserHomeDir()
		configDir := filepath.Join(homeDir, ".config")
		fmt.Println("☁️  Initiating Dotfiles Cloud Sync...")

		// Check if git is initialized
		gitDir := filepath.Join(configDir, ".git")
		if _, err := os.Stat(gitDir); os.IsNotExist(err) {
			fmt.Println("Initializing git repository in ~/.config...")
			exec.Command("git", "-C", configDir, "init").Run()

			// Create a proper gitignore
			ignoreList := []string{
				".cache/",
				"Nextcloud/",
				"google-chrome/",
				"Code/",
				"1Password/",
				"discord/",
				"Slack/",
				"go/",
				"spotify/",
				"BraveSoftware/",
				"obs-studio/basic/profiles/",
				"menus/",
				"mimeapps.list",
				"pulse/",
				"dconf/",
				"github-copilot/",
				"gh/",
			}
			os.WriteFile(filepath.Join(configDir, ".gitignore"), []byte(strings.Join(ignoreList, "\n")), 0644)
		}

		// Check for remote
		remoteOut, _ := exec.Command("git", "-C", configDir, "remote", "-v").Output()
		if len(remoteOut) == 0 {
			fmt.Print("🔗 No remote repository found. Enter GitHub URL (e.g., git@github.com:user/dotfiles.git) or press Enter to skip: ")
			reader := bufio.NewReader(os.Stdin)
			remoteUrl, _ := reader.ReadString('\n')
			remoteUrl = strings.TrimSpace(remoteUrl)
			if remoteUrl != "" {
				exec.Command("git", "-C", configDir, "remote", "add", "origin", remoteUrl).Run()
				exec.Command("git", "-C", configDir, "branch", "-M", "main").Run()
			}
		}

		// Add and commit
		exec.Command("git", "-C", configDir, "add", ".").Run()

		statusOut, _ := exec.Command("git", "-C", configDir, "status", "--porcelain").Output()
		if len(statusOut) == 0 {
			fmt.Println("✅ Everything is up to date. No changes to sync.")
			exec.Command("notify-send", "Cloud Sync", "Everything is up to date.").Start()
			fmt.Println("\nPress Enter to close...")
			bufio.NewReader(os.Stdin).ReadBytes('\n')
			return
		}

		timestamp := time.Now().Format("2006-01-02 15:04:05")
		commitMsg := fmt.Sprintf("chore: Auto-sync %s via Nexus", timestamp)
		exec.Command("git", "-C", configDir, "commit", "-m", commitMsg).Run()

		// Push
		hasRemote := false
		newRemoteOut, _ := exec.Command("git", "-C", configDir, "remote", "-v").Output()
		if len(newRemoteOut) > 0 {
			hasRemote = true
		}

		if hasRemote {
			fmt.Println("🚀 Pushing to remote repository...")
			pushCmd := exec.Command("git", "-C", configDir, "push", "-u", "origin", "main")
			pushCmd.Stdout = os.Stdout
			pushCmd.Stderr = os.Stderr
			if err := pushCmd.Run(); err != nil {
				fmt.Println("❌ Failed to push to remote. Check SSH keys or network.")
				exec.Command("notify-send", "-u", "critical", "Cloud Sync", "Push failed.").Start()
			} else {
				fmt.Println("✅ Sync Complete!")
				exec.Command("notify-send", "Cloud Sync", "Dotfiles synced successfully.").Start()
			}
		} else {
			fmt.Println("✅ Local backup committed (No remote configured).")
			exec.Command("notify-send", "Local Sync", "Dotfiles committed locally.").Start()
		}

		fmt.Println("\nPress Enter to close...")
		bufio.NewReader(os.Stdin).ReadBytes('\n')
	},
}

func init() {
	rootCmd.AddCommand(syncCmd)
}
