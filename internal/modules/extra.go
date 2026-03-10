package modules

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
)

// InstallMobile implements 05-mobile.sh
func InstallMobile() error {
	fmt.Println("🌟 [Module 05: Mobile] Installing Android & Flutter Development...")
	pacman.Install("jdk17-openjdk", "kotlin", "gradle")
	exec.Command("sudo", "archlinux-java", "set", "java-17-openjdk").Run()

	home := os.Getenv("HOME")
	androidHome := filepath.Join(home, "Android/Sdk")
	cmdlineDir := filepath.Join(androidHome, "cmdline-tools")
	os.MkdirAll(cmdlineDir, 0755)

	if _, err := os.Stat(filepath.Join(cmdlineDir, "latest")); os.IsNotExist(err) {
		fmt.Println("-> Downloading Android SDK CLI...")
		zipPath := filepath.Join("/tmp", "cmdline-tools.zip")
		exec.Command("curl", "-fsSL", "-o", zipPath, "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip").Run()
		exec.Command("unzip", "-q", zipPath, "-d", cmdlineDir).Run()
		os.Rename(filepath.Join(cmdlineDir, "cmdline-tools"), filepath.Join(cmdlineDir, "latest"))
		os.Remove(zipPath)
	}

	exec.Command("yes", "|", filepath.Join(androidHome, "cmdline-tools/latest/bin/sdkmanager"), "--licenses").Run()

	pacman.Install("scrcpy", "android-udev")
	exec.Command("sudo", "usermod", "-aG", "adbusers", os.Getenv("USER")).Run()

	fmt.Println("✅ [Module 05: Mobile] Mobile Dev setup complete.")
	return nil
}

// InstallVM implements 12-vm.sh
func InstallVM() error {
	fmt.Println("🌟 [Module 12: VM] Installing Virtualization (QEMU/KVM) & Bottles...")

	pacman.Remove("qemu-full") // Deprecated
	pacman.Install("qemu-desktop", "virt-manager", "libvirt", "edk2-ovmf", "dnsmasq", "iptables-nft", "swtpm", "spice-vdagent", "vde2", "bottles")

	exec.Command("sudo", "systemctl", "enable", "--now", "libvirtd.service").Run()
	exec.Command("sudo", "systemctl", "enable", "--now", "virtlogd.service").Run()

	user := os.Getenv("USER")
	exec.Command("sudo", "usermod", "-aG", "libvirt", user).Run()
	exec.Command("sudo", "usermod", "-aG", "kvm", user).Run()

	// VM Pool
	vmPool := filepath.Join(os.Getenv("HOME"), "VMs")
	os.MkdirAll(vmPool, 0755)

	fmt.Println("✅ [Module 12: VM] Virtualization suite and Bottles installed.")
	return nil
}
