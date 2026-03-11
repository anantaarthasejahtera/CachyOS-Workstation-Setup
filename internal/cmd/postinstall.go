package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"

	"github.com/charmbracelet/lipgloss"
	"github.com/spf13/cobra"
)

var (
	wizardStyle = lipgloss.NewStyle().
			Padding(1, 2).
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("#cba6f7")). // Mocha Mauve/Accent
			Foreground(lipgloss.Color("#cdd6f4"))      // Mocha Text

	w_headingStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("#cba6f7")).Bold(true)
	w_infoStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("#89b4fa"))
	w_successStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("#a6e3a1")).Bold(true)
)

var postInstallCmd = &cobra.Command{
	Use:   "postinstall",
	Short: "First boot onboarding wizard",
	Long:  `Guides the user through post-installation checks, wallpaper setup, and cloud sync.`,
	Run: func(cmd *cobra.Command, args []string) {
		header := w_headingStyle.Render("🚀 Nexus Post-Install Wizard") + "\n" +
			lipgloss.NewStyle().Foreground(lipgloss.Color("#6c7086")).Render("Welcome to your CachyOS Workstation")
		
		fmt.Println(wizardStyle.Render(header))
		fmt.Println()

		// 1. Run Health Check
		fmt.Println(w_infoStyle.Render("▶ [1/3] Running System Health Check..."))
		healthCmd := exec.Command(os.Args[0], "doctor")
		healthCmd.Stdout = os.Stdout
		healthCmd.Stderr = os.Stderr
		healthCmd.Run()

		// 2. Set Wallpaper
		fmt.Println("\n" + w_infoStyle.Render("▶ [2/3] Choose your first wallpaper"))
		if _, err := exec.LookPath("waypaper"); err == nil {
			fmt.Println("  Launching Waypaper. Pick a background and close the window.")
			exec.Command("waypaper").Run()
		} else {
			fmt.Println("  Waypaper not found, skipping wallpaper setup.")
		}

		// 3. Sync Dotfiles
		fmt.Println("\n" + w_infoStyle.Render("▶ [3/3] Setting up Cloud Sync"))
		syncCmd := exec.Command(os.Args[0], "sync")
		syncCmd.Stdout = os.Stdout
		syncCmd.Stderr = os.Stderr
		syncCmd.Run()

		finishBox := lipgloss.NewStyle().
			Padding(1, 2).
			Border(lipgloss.DoubleBorder()).
			BorderForeground(lipgloss.Color("#a6e3a1")).
			Render(
				w_successStyle.Render("🎉 All set! Welcome to your new Ecosystem.") + "\n" +
				"Remember: Press " + w_headingStyle.Render("Super + X") + " to open the Nexus Command Center at any time.",
			)
			
		fmt.Println("\n" + finishBox)

		fmt.Println("\nPress Enter to exit...")
		reader := bufio.NewReader(os.Stdin)
		reader.ReadBytes('\n')
	},
}

func init() {
	rootCmd.AddCommand(postInstallCmd)
}
