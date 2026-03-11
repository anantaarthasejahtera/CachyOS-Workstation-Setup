package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var postInstallCmd = &cobra.Command{
	Use:   "postinstall",
	Short: "First boot onboarding wizard",
	Long:  `Guides the user through post-installation checks, wallpaper setup, and cloud sync.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🚀 Nexus Post-Install Wizard")
		fmt.Println("======================================")

		// 1. Run Health Check
		fmt.Println("\n[1/3] Running System Health Check...")
		healthCmd := exec.Command(os.Args[0], "doctor")
		healthCmd.Stdout = os.Stdout
		healthCmd.Stderr = os.Stderr
		healthCmd.Run()

		// 2. Set Wallpaper
		fmt.Println("\n[2/3] Choose your first wallpaper")
		if _, err := exec.LookPath("waypaper"); err == nil {
			fmt.Println("  Launching Waypaper. Feel free to pick a background and close the window.")
			exec.Command("waypaper").Run()
		} else {
			fmt.Println("  Waypaper not found, skipping wallpaper setup.")
		}

		// 3. Sync Dotfiles
		fmt.Println("\n[3/3] Setting up Cloud Sync")
		syncCmd := exec.Command(os.Args[0], "sync")
		syncCmd.Stdout = os.Stdout
		syncCmd.Stderr = os.Stderr
		syncCmd.Run()

		fmt.Println("\n🎉 All set! Welcome to your new CachyOS Workstation.")
		fmt.Println("   Remember: Press Super+X to open the Nexus Command Center at any time.")

		fmt.Println("\nPress Enter to exit...")
		reader := bufio.NewReader(os.Stdin)
		reader.ReadBytes('\n')
	},
}

func init() {
	rootCmd.AddCommand(postInstallCmd)
}
