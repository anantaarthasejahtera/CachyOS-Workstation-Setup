package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"

	"github.com/charmbracelet/huh"
	"github.com/spf13/cobra"
)

var themeCmd = &cobra.Command{
	Use:   "theme [theme_name]",
	Short: "Switch system themes instantaneously",
	Long:  `Instantly switches your Hyprland border colors and sends reload signals to Waybar. Available presets: catppuccin, nord, dracula.`,
	Run: func(cmd *cobra.Command, args []string) {
		var themeName string

		if len(args) == 0 {
			// Interactive menu
			err := huh.NewForm(
				huh.NewGroup(
					huh.NewSelect[string]().
						Title("🎨 Select System Theme").
						Options(
							huh.NewOption("☕ Catppuccin Mocha", "catppuccin"),
							huh.NewOption("❄️ Nord Frost", "nord"),
							huh.NewOption("🧛 Dracula", "dracula"),
							huh.NewOption("❌ Cancel", "cancel"),
						).
						Value(&themeName),
				),
			).Run()

			if err != nil || themeName == "cancel" {
				return
			}
		} else {
			themeName = args[0]
		}

		fmt.Printf("🎨 Applying theme: %s...\n", themeName)

		// Define colors based on theme
		var col1, col2, shadow string
		switch themeName {
		case "catppuccin":
			col1 = "cba6f7" // Mauve
			col2 = "89b4fa" // Blue
			shadow = "1a1a2e"
		case "nord":
			col1 = "81A1C1"   // Frost Blue
			col2 = "88C0D0"   // Frost Aqua
			shadow = "2E3440" // Night
		case "dracula":
			col1 = "ff79c6"   // Pink
			col2 = "bd93f9"   // Purple
			shadow = "282a36" // Background
		default:
			fmt.Println("❌ Unknown theme preset. Applying Catppuccin defaults.")
			col1 = "cba6f7"
			col2 = "89b4fa"
			shadow = "1a1a2e"
		}

		// Update Hyprland Config
		homeDir, _ := os.UserHomeDir()
		hyprConfig := filepath.Join(homeDir, ".config", "hypr", "hyprland.conf")

		content, err := os.ReadFile(hyprConfig)
		if err == nil {
			configStr := string(content)

			// Replace active_border
			reBorder := regexp.MustCompile(`col\.active_border\s*=\s*rgba\([a-zA-Z0-9]+\)\s*rgba\([a-zA-Z0-9]+\)\s*\d+deg`)
			replacement := fmt.Sprintf("col.active_border = rgba(%see) rgba(%see) 45deg", col1, col2)
			configStr = reBorder.ReplaceAllString(configStr, replacement)

			// Replace shadow color
			reShadow := regexp.MustCompile(`color\s*=\s*rgba\([a-zA-Z0-9]+\)`)
			shadowReplacement := fmt.Sprintf("color = rgba(%see)", shadow)
			configStr = reShadow.ReplaceAllString(configStr, shadowReplacement)

			os.WriteFile(hyprConfig, []byte(configStr), 0644)
			fmt.Println("  [✅] Updated hyprland.conf colors")
		} else {
			fmt.Println("  [❌] Failed to read hyprland.conf")
		}

		// Reload services
		exec.Command("hyprctl", "reload").Run()
		exec.Command("killall", "-SIGUSR2", "waybar").Run()
		exec.Command("notify-send", "Theme Switcher", "Applied theme: "+themeName).Start()

		fmt.Println("✨ Theme applied successfully!")
	},
}

func init() {
	rootCmd.AddCommand(themeCmd)
}
