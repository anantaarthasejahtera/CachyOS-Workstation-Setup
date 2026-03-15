package pacman

import (
	"io"
	"os"
	"os/exec"
	"strings"

	"github.com/pterm/pterm"
)

var defaultLogger io.Writer = os.Stdout

// CheckAndPromptSudo requests administrator privileges natively via terminal
// to prevent silent hangs caused by missing GUI askpass environments.
func CheckAndPromptSudo() error {
	pterm.Warning.Println("🔒 Nexus requires administrator privileges to configure packages and system settings.")
	cmd := exec.Command("sudo", "-v")
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// SetLogger allows redirecting output to a wizard or other writers
func SetLogger(w io.Writer) {
	defaultLogger = w
}

// Command wraps exec.Command and sets Stdout/Stderr to the defaultLogger
func Command(name string, arg ...string) *exec.Cmd {
	cmd := exec.Command(name, arg...)
	cmd.Stdout = defaultLogger
	cmd.Stderr = defaultLogger
	return cmd
}

// IsInstalled checks if a package is already installed via pacman -Q
func IsInstalled(pkgName string) bool {
	cmd := exec.Command("pacman", "-Q", pkgName)
	err := cmd.Run()
	return err == nil
}

// Install runs yay -S --noconfirm --needed for the given packages.
func Install(packages ...string) error {
	var toInstall []string
	for _, pkg := range packages {
		if !IsInstalled(pkg) {
			toInstall = append(toInstall, pkg)
		}
	}

	if len(toInstall) == 0 {
		return nil
	}

	// yay invokes sudo internally. Native terminal sudo caching handles this smoothly.
	args := append([]string{"-S", "--noconfirm", "--needed"}, toInstall...)
	cmd := Command("yay", args...)
	if err := cmd.Run(); err != nil {
		pterm.Error.Prefix = pterm.Prefix{Text: "PACMAN", Style: pterm.NewStyle(pterm.BgRed, pterm.FgBlack)}
		pterm.Error.Printf("Failed to install packages: %s (Exit: %v)\n", strings.Join(toInstall, ", "), err)
		return err
	}
	return nil
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
		return nil
	}

	args := append([]string{"-Rns", "--noconfirm"}, toRemove...)
	cmd := Command("yay", args...)
	if err := cmd.Run(); err != nil {
		pterm.Error.Prefix = pterm.Prefix{Text: "PACMAN", Style: pterm.NewStyle(pterm.BgRed, pterm.FgBlack)}
		pterm.Error.Printf("Failed to remove packages: %s (Exit: %v)\n", strings.Join(toRemove, ", "), err)
		return err
	}
	return nil
}

// Optimize mirrors
func OptimizeMirrors() error {
	cmd := Command("sudo", "rate-mirrors", "--allow-root", "--protocol", "https", "arch")
	return cmd.Run()
}
