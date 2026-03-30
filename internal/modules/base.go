package modules

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/pacman"
	"github.com/pterm/pterm"
)

// InstallBaseSystem implements 01-base.sh logic: base-devel, GPU detection & drivers.
// NOTE: System-wide update (pacman -Syu) is intentionally NOT included here.
// On CachyOS rolling release, full upgrades can break the system and should be
// explicitly triggered by the user via the Rofi menu or `sudo pacman -Syu`.
func InstallBaseSystem() error {
	pterm.Info.Println("🌟 [Module 01: Base] Initializing System Foundation...")

	var errs []string

	pterm.Info.Println("-> Installing base development tools...")
	if err := pacman.Install("base-devel", "git", "curl", "wget", "unzip", "zip", "cmake", "ninja", "meson", "pkgconf", "ccache"); err != nil {
		errs = append(errs, "base-devel: "+err.Error())
	}

	if err := installGPUDrivers(); err != nil {
		errs = append(errs, "gpu-drivers: "+err.Error())
	}

	// Ensure yay is installed
	if !pacman.IsInstalled("yay") {
		pterm.Info.Println("-> Installing yay (AUR helper)...")
		installer := `cd /tmp && rm -rf yay-bin && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm && rm -rf /tmp/yay-bin`
		if err := pacman.Command("bash", "-c", installer).Run(); err != nil {
			errs = append(errs, "yay: "+err.Error())
		}
	}

	optimizeMakepkg()

	if len(errs) > 0 {
		pterm.Warning.Println("⚠️ [Module 01: Base] Completed with errors:")
		for _, e := range errs {
			pterm.Warning.Println("  - " + e)
		}
		return fmt.Errorf("base module: %d error(s)", len(errs))
	}

	pterm.Info.Println("✅ [Module 01: Base] System foundation ready.")
	return nil
}

func installGPUDrivers() error {
	pterm.Info.Println("-> Detecting GPU...")
	out, err := exec.Command("sh", "-c", "lspci | grep -i 'vga\\|3d' | head -1").Output()
	if err != nil {
		pterm.Info.Println("   Warning: Could not detect GPU.")
		return nil // Not having a detectable GPU is not an error
	}

	gpu := strings.ToLower(string(out))
	pterm.Info.Printf("   Detected: %s", string(out))

	var installErr error
	if strings.Contains(gpu, "nvidia") {
		pterm.Info.Println("-> Installing NVIDIA drivers...")
		installErr = pacman.Install("nvidia-dkms", "nvidia-utils", "lib32-nvidia-utils", "nvidia-settings", "vulkan-icd-loader", "lib32-vulkan-icd-loader", "mesa", "lib32-mesa", "libva-nvidia-driver")

		// Idempotent DRM KMS injection — only modify if nvidia modules aren't already in MODULES=()
		mkinitConf, err := os.ReadFile("/etc/mkinitcpio.conf")
		if err == nil && !strings.Contains(string(mkinitConf), "nvidia_drm") {
			pterm.Info.Println("-> Enabling DRM KMS for NVIDIA...")
			pacman.Command("sudo", "sed", "-i", `s/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /`, "/etc/mkinitcpio.conf").Run()
			pacman.Command("sudo", "mkinitcpio", "-P").Run()
		} else if err == nil {
			pterm.Info.Println("-> NVIDIA DRM KMS already configured, skipping.")
		} else {
			pterm.Warning.Printf("-> Could not read /etc/mkinitcpio.conf: %v\n", err)
		}

		pterm.Info.Println("⚠️  If Secure Boot is enabled, NVIDIA DKMS requires MOK key enrollment upon reboot.")

	} else if strings.Contains(gpu, "intel") {
		pterm.Info.Println("-> Installing Intel GPU drivers...")
		installErr = pacman.Install("mesa", "lib32-mesa", "intel-media-driver", "vulkan-intel", "lib32-vulkan-intel", "intel-gpu-tools", "libva-utils")
	} else if strings.Contains(gpu, "amd") || strings.Contains(gpu, "radeon") {
		pterm.Info.Println("-> Installing AMD GPU drivers...")
		installErr = pacman.Install("mesa", "lib32-mesa", "vulkan-radeon", "lib32-vulkan-radeon", "libva-mesa-driver", "mesa-vdpau")
	} else {
		pterm.Info.Println("-> Unknown GPU vendor. Installing generic mesa drivers...")
		installErr = pacman.Install("mesa", "lib32-mesa", "vulkan-icd-loader", "lib32-vulkan-icd-loader")
	}
	return installErr
}

func optimizeMakepkg() {
	nproc := runtime.NumCPU()
	pterm.Info.Printf("-> Optimizing makepkg.conf for %d threads, ccache, and Rust...\n", nproc)

	makeflags := fmt.Sprintf("MAKEFLAGS=\"-j%d\"", nproc)
	pacman.Command("sudo", "sed", "-i", fmt.Sprintf(`s/^#MAKEFLAGS=.*/%s/`, makeflags), "/etc/makepkg.conf").Run()
	pacman.Command("sudo", "sed", "-i", `s/^COMPRESSXZ=.*/COMPRESSXZ=(xz -c -z - --threads=0)/`, "/etc/makepkg.conf").Run()
	pacman.Command("sudo", "sed", "-i", `s/^COMPRESSZST=.*/COMPRESSZST=(zstd -c -z -q - --threads=0)/`, "/etc/makepkg.conf").Run()

	// Inject RUSTFLAGS for native optimization
	rustflags := `RUSTFLAGS="-C opt-level=3 -C target-cpu=native"`
	pacman.Command("sudo", "sed", "-i", fmt.Sprintf(`s~^#RUSTFLAGS=.*~%s~`, rustflags), "/etc/makepkg.conf").Run()

	// Enable ccache in BUILDENV
	pacman.Command("sudo", "sed", "-i", `s/!ccache/ccache/g`, "/etc/makepkg.conf").Run()
}
