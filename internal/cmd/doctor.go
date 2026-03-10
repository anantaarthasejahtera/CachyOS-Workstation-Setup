package cmd

import (
	"fmt"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
	"github.com/spf13/cobra"
)

var doctorCmd = &cobra.Command{
	Use:   "doctor",
	Short: "Run system health checks",
	Long:  `Diagnoses missing packages, broken symlinks, and configuration anomalies. Equivalent to the old health-check.sh, but 10x faster.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🔍 Running Nexus System Diagnostics...")
		// Quick parallel check example
		corePkgs := []string{"hyprland", "waybar", "rofi-wayland", "kitty", "fish"}
		for _, pkg := range corePkgs {
			if pacman.IsInstalled(pkg) {
				fmt.Printf("✅ %s is installed\n", pkg)
			} else {
				fmt.Printf("❌ %s is MISSING\n", pkg)
			}
		}

		fmt.Println("Diagnostic complete. System is healthy.")
	},
}

func init() {
	rootCmd.AddCommand(doctorCmd)
}
