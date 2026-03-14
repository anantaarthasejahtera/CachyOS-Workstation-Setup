package modules

import (
	"os"
	"path/filepath"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
	"github.com/pterm/pterm"
)

// InstallMobile implements 05-mobile.sh
func InstallMobile() error {
	pterm.Info.Println("🌟 [Module 05: Mobile] Installing Android & Flutter Development...")
	pacman.Install("jdk17-openjdk", "kotlin", "gradle")
	pacman.Command("sudo", "archlinux-java", "set", "java-17-openjdk").Run()

	home := os.Getenv("HOME")
	androidHome := filepath.Join(home, "Android/Sdk")
	cmdlineDir := filepath.Join(androidHome, "cmdline-tools")
	os.MkdirAll(cmdlineDir, 0755)

	if _, err := os.Stat(filepath.Join(cmdlineDir, "latest")); os.IsNotExist(err) {
		pterm.Info.Println("-> Downloading Android SDK CLI...")
		zipPath := filepath.Join("/tmp", "cmdline-tools.zip")
		pacman.Command("curl", "-fsSL", "-o", zipPath, "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip").Run()
		pacman.Command("unzip", "-q", zipPath, "-d", cmdlineDir).Run()
		os.Rename(filepath.Join(cmdlineDir, "cmdline-tools"), filepath.Join(cmdlineDir, "latest"))
		os.Remove(zipPath)
	}

	pacman.Command("bash", "-c", "yes | "+filepath.Join(androidHome, "cmdline-tools/latest/bin/sdkmanager")+" --licenses").Run()

	pacman.Install("scrcpy", "android-udev")
	pacman.Command("sudo", "usermod", "-aG", "adbusers", os.Getenv("USER")).Run()

	pterm.Info.Println("✅ [Module 05: Mobile] Mobile Dev setup complete.")
	return nil
}

// InstallVM implements 12-vm.sh
func InstallVM() error {
	pterm.Info.Println("🌟 [Module 12: VM] Installing Virtualization (QEMU/KVM) & Bottles...")

	pacman.Remove("qemu-full") // Deprecated
	pacman.Install("qemu-desktop", "virt-manager", "libvirt", "edk2-ovmf", "dnsmasq", "iptables-nft", "swtpm", "spice-vdagent", "vde2", "bottles")

	// Ultra-Lightweight Adjustment: Rely on socket activation.
	// virt-manager will automatically wake libvirtd.socket when launched.
	// This prevents ~100MB RAM overhead from running a virtualization daemon 24/7.
	pterm.Info.Println("   Note: libvirtd daemon relies on socket activation to save RAM.")
	pacman.Command("sudo", "systemctl", "disable", "libvirtd.service").Run()
	pacman.Command("sudo", "systemctl", "disable", "virtlogd.service").Run()

	user := os.Getenv("USER")
	pacman.Command("sudo", "usermod", "-aG", "libvirt", user).Run()
	pacman.Command("sudo", "usermod", "-aG", "kvm", user).Run()

	// VM Pool
	vmPool := filepath.Join(os.Getenv("HOME"), "VMs")
	os.MkdirAll(vmPool, 0755)

	pterm.Info.Println("✅ [Module 12: VM] Virtualization suite and Bottles installed.")
	return nil
}
