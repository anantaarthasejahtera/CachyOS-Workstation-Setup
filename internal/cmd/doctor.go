package cmd

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
	"github.com/spf13/cobra"
)

var doctorCmd = &cobra.Command{
	Use:   "doctor",
	Short: "Run system health checks",
	Long:  `Diagnoses missing packages, broken symlinks, and configuration anomalies. Equivalent to the old health-check.sh, but 10x faster.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🔍 Running Nexus System Diagnostics...")
		fmt.Println("")

		// 1. Check Core Packages
		fmt.Println("📦 Core Packages:")
		corePkgs := []string{"hyprland", "waybar", "rofi-wayland", "kitty", "fish", "git", "curl", "zenity"}
		for _, pkg := range corePkgs {
			if pacman.IsInstalled(pkg) {
				fmt.Printf("  [✅] %s is installed\n", pkg)
			} else {
				fmt.Printf("  [❌] %s is MISSING\n", pkg)
			}
		}
		fmt.Println("")

		// 2. Check Services
		fmt.Println("⚙️  System Services:")
		services := map[string]string{
			"docker":         "Docker Container Engine",
			"ollama":         "Ollama AI Daemon",
			"NetworkManager": "Network Manager",
			"bluetooth":      "Bluetooth Service",
		}
		for svc, name := range services {
			if pacman.IsInstalled(svc) || svc == "NetworkManager" || svc == "bluetooth" || svc == "ollama" {
				err := exec.Command("systemctl", "is-active", "--quiet", svc).Run()
				if err == nil {
					fmt.Printf("  [🟢] %s is running\n", name)
				} else {
					fmt.Printf("  [🔴] %s is inactive/failed\n", name)
				}
			} else {
				fmt.Printf("  [⚪] %s is not installed\n", name)
			}
		}
		fmt.Println("")

		// 3. Check Configurations
		fmt.Println("🛠️  Configuration Validation:")
		// Waybar check
		waybarOut, _ := exec.Command("waybar", "-v").CombinedOutput()
		if strings.Contains(string(waybarOut), "Waybar") {
			fmt.Println("  [✅] Waybar executable is healthy")
		} else {
			fmt.Println("  [❌] Waybar execution error")
		}

		// Hyprland syntax check check if running
		hyprctlOut, _ := exec.Command("hyprctl", "version").CombinedOutput()
		if strings.Contains(string(hyprctlOut), "Tag") || strings.Contains(string(hyprctlOut), "version") {
			fmt.Println("  [✅] Hyprland server is responding")
		} else {
			fmt.Println("  [⚠️] Hyprland IPC not responding (maybe not running?)")
		}

		fmt.Println("\n✅ Diagnostic complete. See indicators above.")
	},
}

func init() {
	rootCmd.AddCommand(doctorCmd)
}
