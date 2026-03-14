package modules

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
	"github.com/pterm/pterm"
)

// InstallSystemAndSecurity implements 02-kernel.sh and 03-security.sh logic.
func InstallSystemAndSecurity() error {
	pterm.Info.Println("🌟 [Module 02 & 03: System] Applying Performance Tuning & Security...")

	setupKernelAndPerformance()
	setupSecurity()
	setupAdblock()
	optimizeFstab()

	pterm.Info.Println("✅ [Module 02 & 03: System] Deep system tuning and security applied.")
	return nil
}

func setupKernelAndPerformance() {
	// CPU Specific
	// We use regular exec.Command here because we need to capture output, not just log it.
	cmd := exec.Command("sh", "-c", "lscpu | grep -i 'intel'")
	out, _ := cmd.Output()
	if len(out) > 0 {
		pterm.Info.Println("-> Intel CPU detected. Installing thermald...")
		pacman.Install("thermald", "powertop")
		pacman.Command("sudo", "systemctl", "enable", "--now", "thermald.service").Run()
	}

	// EarlyOOM and GameMode
	pacman.Install("earlyoom", "gamemode", "lib32-gamemode")
	pacman.Command("sudo", "systemctl", "enable", "--now", "earlyoom.service").Run()

	// Pipewire low latency
	pterm.Info.Println("-> Configuring PipeWire low-latency...")
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
	pterm.Info.Println("-> Applying kernel sysctl tuning...")
	sysctlConfig := `# Memory Management
# Ultra-Lightweight Tuning for ZRAM
vm.swappiness = 60
vm.vfs_cache_pressure = 100
vm.page-cluster = 0
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.max_map_count = 16777216
vm.min_free_kbytes = 1048576
vm.oom_kill_allocating_task = 1

# Network Performance
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1
net.core.default_qdisc = fq_pie
net.ipv4.tcp_congestion_control = bbr

# File Descriptors & Hardening
kernel.nmi_watchdog = 0
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.file-max = 2097152

# Developer & Gaming Mitigations
kernel.split_lock_mitigate = 0
kernel.perf_event_paranoid = 1
`
	writeSystemFile("/etc/sysctl.d/99-performance.conf", sysctlConfig)
	pacman.Command("sudo", "sysctl", "--system").Run()

	// Process File Limits
	pterm.Info.Println("-> Applying process file limits for large monorepos...")
	limitsConfig := `* soft nofile 1048576
* hard nofile 2097152
`
	pacman.Command("sudo", "mkdir", "-p", "/etc/security/limits.d").Run()
	writeSystemFile("/etc/security/limits.d/99-nexus.conf", limitsConfig)

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
	pterm.Info.Println("-> Setting THP to madvise...")
	pacman.Command("sudo", "mkdir", "-p", "/etc/tmpfiles.d").Run()
	writeSystemFile("/etc/tmpfiles.d/thp.conf", "w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise\n")

	// Fstrim & Journald
	pacman.Command("sudo", "systemctl", "enable", "--now", "fstrim.timer").Run()
	pacman.Command("sudo", "journalctl", "--vacuum-size=256M").Run()
	pacman.Command("sudo", "mkdir", "-p", "/etc/systemd/journald.conf.d").Run()
	writeSystemFile("/etc/systemd/journald.conf.d/size.conf", "[Journal]\nSystemMaxUse=256M\n")
}

func setupSecurity() {
	// UFW
	pacman.Install("ufw")
	if !pacman.IsInstalled("cachyos-snapper-support") && !pacman.IsInstalled("snapper") {
		pacman.Install("timeshift")
	}

	pterm.Info.Println("-> Configuring UFW Firewall...")
	pacman.Command("sudo", "ufw", "default", "deny", "incoming").Run()
	pacman.Command("sudo", "ufw", "default", "allow", "outgoing").Run()
	pacman.Command("sudo", "ufw", "allow", "ssh").Run()
	pacman.Command("sudo", "ufw", "--force", "enable").Run()
	pacman.Command("sudo", "systemctl", "enable", "--now", "ufw.service").Run()

	// SSH Key
	sshKeyPath := filepath.Join(os.Getenv("HOME"), ".ssh/id_ed25519")
	if _, err := os.Stat(sshKeyPath); os.IsNotExist(err) {
		pterm.Info.Println("-> Generating SSH Key...")
		pacman.Command("ssh-keygen", "-t", "ed25519", "-C", "nexus-auto-generated", "-f", sshKeyPath, "-N", "", "-q").Run()
	}

	// Quad9 DNS (Malware Blocking)
	pterm.Info.Println("-> Setting Quad9 HTTP/3 DNS (Malware Blocking + Privacy)...")
	pacman.Command("sudo", "mkdir", "-p", "/etc/systemd/resolved.conf.d").Run()
	dnsConf := `[Resolve]
DNS=9.9.9.9 149.112.112.112 2620:fe::fe 2620:fe::9
DNSOverTLS=yes
Domains=~.
`
	writeSystemFile("/etc/systemd/resolved.conf.d/dns.conf", dnsConf)
	pacman.Command("sudo", "systemctl", "restart", "systemd-resolved").Run()

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
	pacman.Command("git", "config", "--global", "core.excludesFile", ignorePath).Run()

	// --- Ultra-Lightweight System Daemon Purge ---
	pterm.Info.Println("-> Purging non-essential background daemons (avahi, cups, ModemManager)...")
	// Avahi: Local network auto-discovery (Airplay, Printers) - Constantly broadcasts mDNS
	pacman.Command("sudo", "systemctl", "disable", "--now", "avahi-daemon.service", "avahi-daemon.socket").Run()
	// NetworkManager Wait: Blocks boot sequence heavily 
	pacman.Command("sudo", "systemctl", "disable", "NetworkManager-wait-online.service").Run()
	// ModemManager: Huawei USB 4G stick support - Useless on wifi workstations
	pacman.Command("sudo", "systemctl", "mask", "ModemManager.service").Run()
	// CUPS: Local physical printing service
	pacman.Command("sudo", "systemctl", "disable", "--now", "cups.service", "cups.socket").Run()
	pacman.Command("sudo", "systemctl", "mask", "cups.service").Run() // Prevent auto-starting when opening print dialogs
}

// Helper to wrap sudo file writes safely
func writeSystemFile(path, content string) {
	tmpPath := "/tmp/nexus-" + strings.ReplaceAll(path, "/", "-")
	os.WriteFile(tmpPath, []byte(content), 0644)
	pacman.Command("sudo", "mv", tmpPath, path).Run()
	pacman.Command("sudo", "chmod", "0644", path).Run()
}

func optimizeFstab() {
	pterm.Info.Println("-> Optimizing /etc/fstab for SSD Longevity (BTRFS/EXT4)...")
	// Convert relatime to noatime
	pacman.Command("sudo", "sed", "-i", `s/relatime/noatime/g`, "/etc/fstab").Run()

	// Append commit=120 and discard=async safely via awk
	script := `
awk '$3 ~ /^(ext4|btrfs)$/ {
    if ($4 !~ /commit=/) $4 = $4 ",commit=120"
    if ($4 !~ /discard=async/ && $3 == "btrfs") $4 = $4 ",discard=async"
}1' /etc/fstab > /tmp/fstab.tmp && sudo mv /tmp/fstab.tmp /etc/fstab`
	pacman.Command("bash", "-c", script).Run()
}

func setupAdblock() {
	pterm.Info.Println("-> Injecting OS-Level Adblock & Malware Shield (/etc/hosts)...")
	// Backup original if not backed up
	if _, err := os.Stat("/etc/hosts.bak"); os.IsNotExist(err) {
		pacman.Command("sudo", "cp", "/etc/hosts", "/etc/hosts.bak").Run()
	}
	// Fetch StevenBlack unified hosts file (adware + malware blocking)
	pacman.Command("sudo", "curl", "-#L", "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts", "-o", "/etc/hosts").Run()
	pterm.Info.Println("   ✓ Adblock active. Zero CPU overhead.")
}
