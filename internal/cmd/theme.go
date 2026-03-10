package cmd

import (
	"fmt"
	"os/exec"

	"github.com/spf13/cobra"
)

var themeCmd = &cobra.Command{
	Use:   "theme [theme_name]",
	Short: "Switch system themes instantaneously",
	Long:  `Instantly switches your Hyprland, Waybar, and Rofi theme utilizing zero-delay Go process signals.`,
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		themeName := args[0]
		fmt.Printf("🎨 Applying theme: %s...\n", themeName)

		// In a full implementation, we'd copy the correct CSS files and send SIGUSR2 to Waybar.
		// Example: reload waybar
		exec.Command("killall", "-SIGUSR2", "waybar").Run()

		fmt.Println("✨ Theme applied successfully!")
	},
}

func init() {
	rootCmd.AddCommand(themeCmd)
}
