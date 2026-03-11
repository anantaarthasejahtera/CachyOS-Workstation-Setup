package pacman

import (
	"os"
	"os/exec"
)

// IsInstalled checks if a package is already installed via pacman -Q
func IsInstalled(pkgName string) bool {
	cmd := exec.Command("pacman", "-Q", pkgName)
	err := cmd.Run()
	return err == nil
}

// Install runs yay -S --noconfirm --needed for the given packages.
// It dynamically filters packages that are already installed to speed up execution.
func Install(packages ...string) error {
	var toInstall []string
	for _, pkg := range packages {
		if !IsInstalled(pkg) {
			toInstall = append(toInstall, pkg)
		}
	}

	if len(toInstall) == 0 {
		return nil // Everything is already installed
	}

	args := append([]string{"-S", "--noconfirm", "--needed"}, toInstall...)
	cmd := exec.Command("yay", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// Remove runs yay -Rns --noconfirm only for installed packages
func Remove(packages ...string) error {
	var toRemove []string
	for _, pkg := range packages {
		if IsInstalled(pkg) {
			toRemove = append(toRemove, pkg)
		}
	}

	if len(toRemove) == 0 {
		return nil // Nothing to remove
	}

	args := append([]string{"-Rns", "--noconfirm"}, toRemove...)
	cmd := exec.Command("yay", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// Optimize mirrors (equivalent to the bash mirror checking logic, simplified for Go)
func OptimizeMirrors() error {
	cmd := exec.Command("sudo", "rate-mirrors", "--allow-root", "--protocol", "https", "arch")
	// For actual implementation, rates-mirrors output should be piped to /etc/pacman.d/mirrorlist
	// Keeping it simple here as a stub for the migration plan.
	return cmd.Run()
}
