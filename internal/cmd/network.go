package cmd

import (
	"bytes"
	"os"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/menu"
)

var networkCmd = &cobra.Command{
	Use:   "network",
	Short: "Network Cockpit GUI",
	RunE: func(cmd *cobra.Command, args []string) error {
		entries := []string{
			"  📡 Wi-Fi Scanner (Native Rofi)",
			"  🛡️ Toggle Shield (OS-Level Adblock)",
			"  🌐 Switch DNS Provider (Cloudflare/Quad9/AdGuard)",
			"  🔐 VPN Manager (nmtui)",
		}

		mesg := "🛫 Nexus Network Cockpit"
		themeConfig := menu.GetRofiTheme() // Using the public custom function we'll add to menu/rofi.go

		rofiCmd := exec.Command("rofi", "-dmenu", "-i", "-p", " Network", "-mesg", mesg, "-theme-str", themeConfig)
		rofiCmd.Stdin = strings.NewReader(strings.Join(entries, "\n"))
		
		var out bytes.Buffer
		rofiCmd.Stdout = &out
		
		if err := rofiCmd.Run(); err != nil {
			return nil // User pressed ESC
		}

		chosen := strings.TrimSpace(out.String())
		
		switch {
		case strings.Contains(chosen, "Wi-Fi Scanner"):
			exec.Command(os.Args[0], "wifi").Start()
		case strings.Contains(chosen, "Toggle Shield"):
			exec.Command("kitty", "--hold", "-e", os.Args[0], "shield").Start()
		case strings.Contains(chosen, "Switch DNS"):
			exec.Command(os.Args[0], "dns").Start()
		case strings.Contains(chosen, "VPN Manager"):
			exec.Command("kitty", "-e", "nmtui", "connect").Start() // nmtui can show connections directly
		}

		return nil
	},
}

func init() {
	rootCmd.AddCommand(networkCmd)
}
