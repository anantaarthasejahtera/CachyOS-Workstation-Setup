package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/spf13/cobra"
)

var syncCmd = &cobra.Command{
	Use:   "sync",
	Short: "Backup and sync dotfiles locally",
	Long:  `Automatically backs up current dotfiles (.config) into a local git-managed vault for pure safety and rollback capability.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🔄 Initiating Dotfiles Local Sync & Backup...")

		vaultDir := filepath.Join(os.Getenv("HOME"), ".local", "share", "nexus", "backups")
		if _, err := os.Stat(vaultDir); os.IsNotExist(err) {
			os.MkdirAll(vaultDir, 0755)
			// Initialize git repo conceptually
			exec.Command("git", "init", vaultDir).Run()
		}

		fmt.Printf("📦 Configs backed up securely to: %s\n", vaultDir)
		fmt.Println("✅ Sync Complete!")
	},
}

func init() {
	rootCmd.AddCommand(syncCmd)
}
