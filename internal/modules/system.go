package modules

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
)

// InstallSystemAndSecurity implements 02-kernel.sh and 03-security.sh logic.
func InstallSystemAndSecurity() error {
	fmt.Println("🌟 [Module 02 & 03: System] Applying Performance Tuning & Security...")

	setupKernelAndPerformance()
	setupSecurity()

	fmt.Println("✅ [Module 02 & 03: System] Deep system tuning and security applied.")
	return nil
}

func setupKernelAndPerformance() {
	// CPU Specific
	out, _ := exec.Command("sh", "-c", "lscpu | grep -i 'intel'").Output()
	if len(out) > 0 {
		fmt.Println("-> Intel CPU detected. Installing thermald...")
		pacman.Install("thermald", "powertop")
		exec.Command("sudo", "systemctl", "enable", "--now", "thermald.service").Run()
	}

	// EarlyOOM and GameMode
	pacman.Install("earlyoom", "gamemode", "lib32-gamemode")
	exec.Command("sudo", "systemctl", "enable", "--now", "earlyoom.service").Run()

	// Pipewire low latency
	fmt.Println("-> Configuring PipeWire low-latency...")
	pwConfig := `context.properties = {
    default.clock.rate          = 48000
    default.clock.quantum       = 512
    default.clock.min-quantum   = 32
    default.clock.max-quantum   = 2048
}`
	pwDir := filepath.Join(os.Getenv("HOME"), ".config/pipewire/pipewire.conf.d")
	os.MkdirAll(pwDir, 0755)
	os.WriteFile(filepath.Join(pwDir, "99-lowlatency.conf"), []byte(pwConfig), 0644)

	// Sysctl tuning
	fmt.Println("-> Applying kernel sysctl tuning...")
	sysctlConfig := `# Memory Management
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# Network Performance
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1

# Hardening
kernel.nmi_watchdog = 0
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
`
	writeSystemFile("/etc/sysctl.d/99-performance.conf", sysctlConfig)
	exec.Command("sudo", "sysctl", "--system").Run()

	// I/O Scheduler
	ioRules := `# NVMe: no scheduler
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
# SATA SSD: mq-deadline
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# HDD: bfq
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
`
	writeSystemFile("/etc/udev/rules.d/60-ioscheduler.rules", ioRules)

	// THP
	fmt.Println("-> Setting THP to madvise...")
	exec.Command("sudo", "mkdir", "-p", "/etc/tmpfiles.d").Run()
	writeSystemFile("/etc/tmpfiles.d/thp.conf", "w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise\n")

	// Fstrim & Journald
	exec.Command("sudo", "systemctl", "enable", "--now", "fstrim.timer").Run()
	exec.Command("sudo", "journalctl", "--vacuum-size=256M").Run()
	exec.Command("sudo", "mkdir", "-p", "/etc/systemd/journald.conf.d").Run()
	writeSystemFile("/etc/systemd/journald.conf.d/size.conf", "[Journal]\nSystemMaxUse=256M\n")
}

func setupSecurity() {
	// UFW
	pacman.Install("ufw")
	if !pacman.IsInstalled("cachyos-snapper-support") && !pacman.IsInstalled("snapper") {
		pacman.Install("timeshift")
	}

	fmt.Println("-> Configuring UFW Firewall...")
	exec.Command("sudo", "ufw", "default", "deny", "incoming").Run()
	exec.Command("sudo", "ufw", "default", "allow", "outgoing").Run()
	exec.Command("sudo", "ufw", "allow", "ssh").Run()
	exec.Command("sudo", "ufw", "--force", "enable").Run()
	exec.Command("sudo", "systemctl", "enable", "--now", "ufw.service").Run()

	// SSH Key
	sshKeyPath := filepath.Join(os.Getenv("HOME"), ".ssh/id_ed25519")
	if _, err := os.Stat(sshKeyPath); os.IsNotExist(err) {
		fmt.Println("-> Generating SSH Key...")
		exec.Command("ssh-keygen", "-t", "ed25519", "-C", "nexus-auto-generated", "-f", sshKeyPath, "-N", "", "-q").Run()
	}

	// Cloudflare DNS
	fmt.Println("-> Setting Cloudflare HTTP/3 DNS...")
	exec.Command("sudo", "mkdir", "-p", "/etc/systemd/resolved.conf.d").Run()
	dnsConf := `[Resolve]
DNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
DNSOverTLS=yes
Domains=~.
`
	writeSystemFile("/etc/systemd/resolved.conf.d/dns.conf", dnsConf)
	exec.Command("sudo", "systemctl", "restart", "systemd-resolved").Run()

	// Global gitignore
	gitIgnore := `# OS files
.DS_Store
Thumbs.db
*~
# Dependencies
node_modules/
__pycache__/
.venv/
`
	ignorePath := filepath.Join(os.Getenv("HOME"), ".gitignore_global")
	os.WriteFile(ignorePath, []byte(gitIgnore), 0644)
	exec.Command("git", "config", "--global", "core.excludesFile", ignorePath).Run()
}

// Helper to wrap sudo file writes safely
func writeSystemFile(path, content string) {
	tmpPath := "/tmp/nexus-" + strings.ReplaceAll(path, "/", "-")
	os.WriteFile(tmpPath, []byte(content), 0644)
	exec.Command("sudo", "mv", tmpPath, path).Run()
	exec.Command("sudo", "chmod", "0644", path).Run()
}
