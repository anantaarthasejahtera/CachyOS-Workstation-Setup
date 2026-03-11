package cmd

import (
	"bytes"
	"fmt"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/menu"
)

var wifiCmd = &cobra.Command{
	Use:   "wifi",
	Short: "Native Rofi Wi-Fi Scanner",
	Hidden: true, // Hide from standard CLI help
	RunE: func(cmd *cobra.Command, args []string) error {
		// Ensure WiFi is soft unblocked
		exec.Command("nmcli", "radio", "wifi", "on").Run()
		
		// Rescan
		exec.Command("nmcli", "device", "wifi", "rescan").Run()

		// Get networks: SSRID:SIGNAL:BARS:SECURITY:IN-USE
		out, err := exec.Command("nmcli", "-t", "-f", "SSID,SIGNAL,BARS,SECURITY,IN-USE", "device", "wifi", "list").Output()
		if err != nil {
			exec.Command("notify-send", "❌ Wi-Fi Error", "Failed to list networks.").Start()
			return err
		}

		lines := strings.Split(strings.TrimSpace(string(out)), "\n")
		var displayEntries []string
		var rawSsids []string

		for _, line := range lines {
			parts := strings.Split(line, ":")
			if len(parts) >= 5 {
				ssid := parts[0]
				if ssid == "" {
					continue
				}
				signal := parts[1]
				_ = parts[2] // unused bars
				sec := parts[3]
				inUse := parts[4]

				icon := "󰤨 "
				if inUse == "*" {
					icon = "󰤪 (Connected) "
				}
				
				lock := ""
				if sec != "" && sec != "--" {
					lock = " "
				}

				display := fmt.Sprintf("%s %s %s%%%s", icon, ssid, signal, lock)
				displayEntries = append(displayEntries, display)
				rawSsids = append(rawSsids, ssid)
			}
		}

		themeConfig := menu.GetRofiTheme()
		mesg := "📡 Pick a Wi-Fi Network"
		
		rofiCmd := exec.Command("rofi", "-dmenu", "-i", "-p", " Wi-Fi", "-mesg", mesg, "-theme-str", themeConfig)
		rofiCmd.Stdin = strings.NewReader(strings.Join(displayEntries, "\n"))
		var outBuf bytes.Buffer
		rofiCmd.Stdout = &outBuf

		if err := rofiCmd.Run(); err != nil {
			return nil // Canceled
		}

		chosenDisplay := strings.TrimSpace(outBuf.String())
		if chosenDisplay == "" {
			return nil
		}

		// Map display back to raw SSID
		selectedIndex := -1
		for i, de := range displayEntries {
			if de == chosenDisplay {
				selectedIndex = i
				break
			}
		}

		if selectedIndex == -1 {
			return nil
		}
		
		targetSsid := rawSsids[selectedIndex]

		// Ask for password
		passMesg := fmt.Sprintf("🔑 Enter password for %s", targetSsid)
		passCmd := exec.Command("rofi", "-dmenu", "-password", "-p", " Pass", "-mesg", passMesg, "-theme-str", themeConfig)
		var passBuf bytes.Buffer
		passCmd.Stdout = &passBuf
		
		if err := passCmd.Run(); err != nil {
			return nil // canceled
		}
		
		password := strings.TrimSpace(passBuf.String())
		
		exec.Command("notify-send", "📡 Connecting...", fmt.Sprintf("Attempting to connect to %s", targetSsid)).Start()

		connectCmd := exec.Command("nmcli", "device", "wifi", "connect", targetSsid, "password", password)
		if err := connectCmd.Run(); err != nil {
			exec.Command("notify-send", "❌ Connection Failed", fmt.Sprintf("Could not connect to %s", targetSsid)).Start()
		} else {
			exec.Command("notify-send", "✅ Connected", fmt.Sprintf("Successfully connected to %s", targetSsid)).Start()
		}

		return nil
	},
}

func init() {
	rootCmd.AddCommand(wifiCmd)
}
