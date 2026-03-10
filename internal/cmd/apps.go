package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var appsCmd = &cobra.Command{
	Use:   "apps",
	Short: "Interactive application installer",
	Long:  `Launch the sleek TUI application store to browse, search, and install extra tools.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🛒 Nexus App Store: Booting TUI...")
		// Placeholder for Charmbracelet Bubbletea interactive list
		fmt.Println("   [1] VSCode")
		fmt.Println("   [2] Docker")
		fmt.Println("   [3] Obsidian")
		fmt.Println("✨ TUI framework will render this with huh/bubbletea in full implementation.")
	},
}

func init() {
	rootCmd.AddCommand(appsCmd)
}
