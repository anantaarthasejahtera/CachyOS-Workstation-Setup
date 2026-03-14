package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

var chatCmd = &cobra.Command{
	Use:   "chat",
	Short: "AI-powered workstation assistant",
	Long:  `Launch the Nexus AI chat to get help, diagnose issues, or run automations using local Ollama streams.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("=====================================================")
		fmt.Println(" 🤖 Nexus AI Assistant (Powered by qwen3.5:4b) ")
		fmt.Println("=====================================================")
		fmt.Println(" Type /bye to exit. Conversation history is retained.")
		fmt.Println("")

		// Automatically wake up Ollama daemon
		fmt.Println("Waking up AI daemon...")
		exec.Command("sudo", "systemctl", "start", "ollama.service").Run()

		// Connect directly to local Ollama REPL
		ollamaCmd := exec.Command("ollama", "run", "qwen3.5:4b")
		ollamaCmd.Stdin = os.Stdin
		ollamaCmd.Stdout = os.Stdout
		ollamaCmd.Stderr = os.Stderr

		err := ollamaCmd.Run()
		if err != nil {
			msg := "❌ Failed to connect to local AI. Ensure 'ollama' is installed."
			fmt.Println(msg)
			exec.Command("rofi", "-e", msg).Start()
		}

		// Auto-Suspend Ollama after session ends
		fmt.Println("\nPutting AI daemon back to sleep to save RAM...")
		exec.Command("sudo", "systemctl", "stop", "ollama.service").Run()
		fmt.Println("Nexus AI session ended.")
	},
}

func init() {
	rootCmd.AddCommand(chatCmd)
}
