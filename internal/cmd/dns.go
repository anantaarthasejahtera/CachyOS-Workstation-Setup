package cmd

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/menu"
)

var dnsCmd = &cobra.Command{
	Use:   "dns",
	Short: "Switch DNS Providers",
	Hidden: true,
	RunE: func(cmd *cobra.Command, args []string) error {
		entries := []string{
			"  1. Quad9 (Malware Blocking + Privacy)",
			"  2. Cloudflare (Speed & Redundancy)",
			"  3. AdGuard (Ad-Blocking via DNS)",
		}

		mesg := "🌐 Pick your DNS resolver"
		themeConfig := menu.GetRofiTheme()

		rofiCmd := exec.Command("rofi", "-dmenu", "-i", "-p", " DNS", "-mesg", mesg, "-theme-str", themeConfig)
		rofiCmd.Stdin = strings.NewReader(strings.Join(entries, "\n"))
		
		var out bytes.Buffer
		rofiCmd.Stdout = &out
		
		if err := rofiCmd.Run(); err != nil {
			return nil
		}

		chosen := strings.TrimSpace(out.String())
		var dnsConf string
		var providerName string

		switch {
		case strings.Contains(chosen, "Quad9"):
			providerName = "Quad9"
			dnsConf = `[Resolve]
DNS=9.9.9.9 149.112.112.112 2620:fe::fe 2620:fe::9
DNSOverTLS=yes
Domains=~.
`
		case strings.Contains(chosen, "Cloudflare"):
			providerName = "Cloudflare"
			dnsConf = `[Resolve]
DNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
DNSOverTLS=yes
Domains=~.
`
		case strings.Contains(chosen, "AdGuard"):
			providerName = "AdGuard DNS"
			dnsConf = `[Resolve]
DNS=94.140.14.14 94.140.15.15 2a10:50c0::ad1:ff 2a10:50c0::ad2:ff
DNSOverTLS=yes
Domains=~.
`
		default:
			return nil
		}

		tmpPath := "/tmp/nexus-dns.conf"
		os.WriteFile(tmpPath, []byte(dnsConf), 0644)
		exec.Command("sudo", "mkdir", "-p", "/etc/systemd/resolved.conf.d").Run()
		exec.Command("sudo", "mv", tmpPath, "/etc/systemd/resolved.conf.d/dns.conf").Run()
		exec.Command("sudo", "systemctl", "restart", "systemd-resolved").Run()

		exec.Command("notify-send", "🌐 DNS Switched", fmt.Sprintf("Successfully shifted to %s via DoT", providerName)).Start()
		return nil
	},
}

func init() {
	rootCmd.AddCommand(dnsCmd)
}
