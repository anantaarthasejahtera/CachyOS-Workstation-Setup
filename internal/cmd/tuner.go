package cmd

import (
	"bytes"
	"fmt"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
)

var tunerCmd = &cobra.Command{
	Use:   "tuner",
	Short: "AI Auto-Tuner & Sysctl Optimization",
	Long:  `Gathers real-time telemetry and pipes it to local qwen3.5:4b via Ollama for system optimization advice.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🧠 Nexus AI Auto-Tuner")
		fmt.Println("Gathering system telemetry...")

		// Gather telemetry securely using exec
		topOut, _ := exec.Command("sh", "-c", "top -b -n 1 | head -n 15").Output()
		freeOut, _ := exec.Command("free", "-h").Output()
		vmstatOut, _ := exec.Command("vmstat", "1", "2").Output()

		telemetry := fmt.Sprintf("TOP:\n%s\n\nFREE:\n%s\n\nVMSTAT:\n%s", topOut, freeOut, vmstatOut)

		prompt := fmt.Sprintf(`Analyze the following Linux system telemetry. Provide 3 highly actionable sysctl or service optimization tips to improve system performance based on the specific telemetry shown below. Be extremely concise. Reply with a short bulleted list only.

Telemetry:
%s`, telemetry)

		fmt.Println("Thinking (querying local qwen3.5:4b)...")

		// Wake up AI daemon
		exec.Command("sudo", "systemctl", "start", "ollama.service").Run()

		// Query Ollama local API via executable
		ollamaCmd := exec.Command("ollama", "run", "qwen3.5:4b")
		ollamaCmd.Stdin = strings.NewReader(prompt)

		var out bytes.Buffer
		ollamaCmd.Stdout = &out
		ollamaCmd.Stderr = &out

		err := ollamaCmd.Run()
		
		// Immediately put daemon back to sleep
		exec.Command("sudo", "systemctl", "stop", "ollama.service").Run()

		if err != nil {
			msg := "❌ Failed to query Ollama. Make sure the model is pulled (`ollama pull qwen3.5:4b`)."
			fmt.Println(msg)
			exec.Command("rofi", "-e", msg).Start()
			return
		}

		result := strings.TrimSpace(out.String())

		// Display the insights in a nice Rofi Notification Menu
		rofiCmd := exec.Command("rofi", "-dmenu", "-i", "-p", "🧠 AI Tuner Advice", "-mesg", "Actionable system optimizations based on live telemetry:")
		rofiCmd.Stdin = strings.NewReader(result)
		rofiCmd.Run()
	},
}

func init() {
	rootCmd.AddCommand(tunerCmd)
}
