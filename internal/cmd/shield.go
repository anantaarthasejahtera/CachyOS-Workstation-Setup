package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var shieldCmd = &cobra.Command{
	Use:   "shield",
	Short: "Toggle OS-level Network Adblock & Malware Shield",
	RunE: func(cmd *cobra.Command, args []string) error {
		fmt.Println("🛡️  Nexus OS-Level Shield Manager")
		fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

		// Check if adblock is active (presence of backup file implies stevenblack is active)
		isActive := false
		if _, err := os.Stat("/etc/hosts.bak"); err == nil {
			isActive = true
		}

		if isActive {
			fmt.Println("Adblock is currently: [ACTIVE]")
			fmt.Println("\n-> Restoring original /etc/hosts...")
			exec.Command("sudo", "mv", "/etc/hosts.bak", "/etc/hosts").Run()
			fmt.Println("-> Shield disabled successfully.")
		} else {
			fmt.Println("Adblock is currently: [DISABLED]")
			fmt.Println("\n-> Backing up original /etc/hosts...")
			exec.Command("sudo", "cp", "/etc/hosts", "/etc/hosts.bak").Run()

			fmt.Println("-> Fetching StevenBlack Unified Hosts (Adware + Malware lists)...")
			err := exec.Command("sudo", "curl", "-#L", "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts", "-o", "/etc/hosts").Run()
			if err != nil {
				fmt.Println("   ❌ Failed to fetch hosts file:", err)
				return err
			}
			fmt.Println("-> Shield enabled successfully. Zero CPU overhead adblocking active.")
		}

		return nil
	},
}

func init() {
	rootCmd.AddCommand(shieldCmd)
}
