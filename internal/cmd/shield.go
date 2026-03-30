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

		// Use dedicated marker to track shield state (hosts.bak can exist for other reasons)
		markerPath := "/tmp/.nexus-shield-active"
		isActive := false
		if _, err := os.Stat(markerPath); err == nil {
			isActive = true
		}

		if isActive {
			fmt.Println("Adblock is currently: [ACTIVE]")
			if _, err := os.Stat("/etc/hosts.bak"); err == nil {
				fmt.Println("\n-> Restoring original /etc/hosts...")
				exec.Command("sudo", "cp", "/etc/hosts.bak", "/etc/hosts").Run()
			} else {
				fmt.Println("\n-> No backup found. Fetching clean base hosts file...")
				exec.Command("sudo", "bash", "-c",
					`echo -e "127.0.0.1 localhost\n::1 localhost" > /etc/hosts`).Run()
			}
			os.Remove(markerPath)
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
			os.WriteFile(markerPath, []byte("active"), 0644)
			fmt.Println("-> Shield enabled successfully. Zero CPU overhead adblocking active.")
		}

		return nil
	},
}

func init() {
	rootCmd.AddCommand(shieldCmd)
}
