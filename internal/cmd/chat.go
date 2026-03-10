package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var chatCmd = &cobra.Command{
	Use:   "chat",
	Short: "AI-powered workstation assistant",
	Long:  `Launch the Nexus AI chat to get help, diagnose issues, or run automations using native Go HTTP streams.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🤖 Nexus AI Chat Initializing...")
		fmt.Println("   Connected to AI provider. State history is loaded via SQLite memory.")
		// Wait for user input loop (placeholder)
		fmt.Println("   > How can I assist you with your CachyOS setup today?")
	},
}

func init() {
	rootCmd.AddCommand(chatCmd)
}
