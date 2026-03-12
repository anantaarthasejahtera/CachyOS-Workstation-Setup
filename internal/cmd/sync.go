package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/charmbracelet/huh"
	"github.com/charmbracelet/lipgloss"
	"github.com/spf13/cobra"
)

var (
	syncStyle = lipgloss.NewStyle().
			Padding(1, 2).
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("#cba6f7")). // Mocha Mauve/Accent
			Foreground(lipgloss.Color("#cdd6f4"))        // Mocha Text

	successStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("#a6e3a1")).Bold(true) // Mocha Green
	errorStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("#f38ba8")).Bold(true) // Mocha Red
	infoStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("#89b4fa"))            // Mocha Blue
)

var syncCmd = &cobra.Command{
	Use:   "sync",
	Short: "Backup and sync dotfiles locally and to cloud",
	Long:  `Automatically backs up current dotfiles (.config) into a git-managed vault and pushes to a remote repository for disaster recovery.`,
	Run: func(cmd *cobra.Command, args []string) {
		homeDir, _ := os.UserHomeDir()
		configDir := filepath.Join(homeDir, ".config")

		header := lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("#cba6f7")).
			Render("☁️  Dotfiles Cloud Sync")

		fmt.Println(syncStyle.Render(header))
		fmt.Println()

		// Check if git is initialized
		gitDir := filepath.Join(configDir, ".git")
		if _, err := os.Stat(gitDir); os.IsNotExist(err) {
			fmt.Println(infoStyle.Render("Initializing git repository in ~/.config..."))
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

		// Add and commit
		exec.Command("git", "-C", configDir, "add", ".").Run()

		statusOut, _ := exec.Command("git", "-C", configDir, "status", "--porcelain").Output()
		if len(statusOut) == 0 {
			fmt.Println(successStyle.Render("✅ Everything is up to date. No changes to sync."))
			exec.Command("notify-send", "Cloud Sync", "Everything is up to date.").Start()
			fmt.Println("\nPress Enter to close...")
			bufio.NewReader(os.Stdin).ReadBytes('\n')
			return
		}

		timestamp := time.Now().Format("2006-01-02 15:04:05")
		commitMsg := fmt.Sprintf("chore: Auto-sync %s via Nexus", timestamp)
		exec.Command("git", "-C", configDir, "commit", "-m", commitMsg).Run()

		// --- Auto-Auth using GitHub CLI (gh) ---
		// Check for remote
		remoteOut, _ := exec.Command("git", "-C", configDir, "remote", "-v").Output()
		hasRemote := len(remoteOut) > 0

		if !hasRemote {
			fmt.Println(infoStyle.Render("🔍 No remote repository found. Checking GitHub CLI authentication..."))
			
			// Check gh auth status
			authCheck := exec.Command("gh", "auth", "status")
			if authErr := authCheck.Run(); authErr != nil {
				fmt.Println(errorStyle.Render("🔴 Not authenticated to GitHub."))
				var doAuth bool
				huh.NewConfirm().
					Title("Authenticate with GitHub CLI now?").
					Description("This will open a browser or prompt for a token.").
					Affirmative("Yes").Negative("Skip Cloud Sync").
					Value(&doAuth).Run()

				if doAuth {
					// Interactive Login
					loginCmd := exec.Command("gh", "auth", "login")
					loginCmd.Stdin = os.Stdin
					loginCmd.Stdout = os.Stdout
					loginCmd.Stderr = os.Stderr
					if err := loginCmd.Run(); err != nil {
						fmt.Println(errorStyle.Render("❌ Authentication failed or aborted. Cloud sync skipped."))
						fmt.Println(successStyle.Render("✅ Local backup committed safely."))
						fmt.Println("\nPress Enter to close...")
						bufio.NewReader(os.Stdin).ReadBytes('\n')
						return
					}
					fmt.Println(successStyle.Render("✅ Successfully authenticated to GitHub!"))
				} else {
					fmt.Println(successStyle.Render("✅ Local backup committed (Cloud push skipped)."))
					fmt.Println("\nPress Enter to close...")
					bufio.NewReader(os.Stdin).ReadBytes('\n')
					return
				}
			}

			// Offer Repo Creation
			var repoAction string
			huh.NewSelect[string]().
				Title("Where should we push your dotfiles?").
				Options(
					huh.NewOption("Create a NEW private repository (dotfiles)", "create"),
					huh.NewOption("Link to an EXISTING repository URL", "link"),
					huh.NewOption("Skip remote push (Local Only)", "skip"),
				).
				Value(&repoAction).Run()

			if repoAction == "create" {
				fmt.Println(infoStyle.Render("📦 Creating private repository 'dotfiles'..."))
				repoCreateCmd := exec.Command("gh", "repo", "create", "dotfiles", "--private", "--source", configDir, "--remote", "origin", "--push")
				repoCreateCmd.Stdout = os.Stdout
				repoCreateCmd.Stderr = os.Stderr
				if err := repoCreateCmd.Run(); err != nil {
					fmt.Println(errorStyle.Render("❌ Failed to create repository."))
				} else {
					hasRemote = true
					exec.Command("git", "-C", configDir, "branch", "-M", "main").Run()
					fmt.Println(successStyle.Render("✅ Repository created and linked!"))
				}
			} else if repoAction == "link" {
				var remoteUrl string
				huh.NewInput().
					Title("Existing Repository").
					Description("Enter your GitHub URL (e.g., git@github.com:user/dotfiles.git)").
					Value(&remoteUrl).Run()

				remoteUrl = strings.TrimSpace(remoteUrl)
				if remoteUrl != "" {
					exec.Command("git", "-C", configDir, "remote", "add", "origin", remoteUrl).Run()
					exec.Command("git", "-C", configDir, "branch", "-M", "main").Run()
					hasRemote = true
				}
			}
		}

		// Push
		if hasRemote {
			fmt.Println(infoStyle.Render("🚀 Pushing to remote repository..."))
			
			// Fail-Fast: Prevent git from hanging on password prompts if auth is somehow broken
			pushCmd := exec.Command("git", "-C", configDir, "push", "-u", "origin", "main")
			pushCmd.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0") // Crucial for unattended/TUI scripts
			pushCmd.Stdout = os.Stdout
			pushCmd.Stderr = os.Stderr
			
			if err := pushCmd.Run(); err != nil {
				fmt.Println(errorStyle.Render("❌ Failed to push to remote. Check SSH keys or network."))
				fmt.Println(infoStyle.Render("\n💡 Troubleshooting Tips:"))
				fmt.Println(infoStyle.Render("  1. Ensure SSH keys are added to GitHub, or you are logged in via 'gh auth login'."))
				fmt.Println(infoStyle.Render("  2. Wrong URL entered? Fix it by typing: git -C ~/.config remote remove origin"))
				exec.Command("notify-send", "-u", "critical", "Cloud Sync", "Push failed.").Start()
			} else {
				fmt.Println(successStyle.Render("✅ Sync Complete!"))
				exec.Command("notify-send", "Cloud Sync", "Dotfiles synced successfully.").Start()
			}
		} else {
			fmt.Println(successStyle.Render("✅ Local backup committed (No remote configured)."))
			exec.Command("notify-send", "Local Sync", "Dotfiles committed locally.").Start()
		}

		fmt.Println("\nPress Enter to close...")
		bufio.NewReader(os.Stdin).ReadBytes('\n')
	},
}

func init() {
	rootCmd.AddCommand(syncCmd)
}
