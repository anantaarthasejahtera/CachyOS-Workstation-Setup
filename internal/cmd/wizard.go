package cmd

import (
	"fmt"
	"os"

	"github.com/pterm/pterm"
)

// Wizard handles the terminal-native TUI progress and logging for the installation.
type Wizard struct {
	spinner     *pterm.SpinnerPrinter
	totalSteps  int
	currentStep int
	logFile     *os.File
}

// NewWizard initializes the Pterm-based progress and log views.
func NewWizard(title string, total int) (*Wizard, error) {
	// Start by printing a beautiful title header
	pterm.DefaultHeader.WithFullWidth().WithBackgroundStyle(pterm.NewStyle(pterm.BgCyan)).WithTextStyle(pterm.NewStyle(pterm.FgBlack)).Println(title)

	// Create a spinner to run continuously above the logs
	spinner, err := pterm.DefaultSpinner.WithShowTimer(true).WithText("Initializing installation...").Start()
	if err != nil {
		return nil, err
	}

	f, _ := os.OpenFile("/tmp/nexus_install.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	
	return &Wizard{
		spinner:     spinner,
		totalSteps:  total,
		currentStep: 0,
		logFile:     f,
	}, nil
}

// UpdateProgress shifts the progress text and increments steps internally.
func (w *Wizard) UpdateProgress(description string) {
	w.currentStep++
	w.spinner.UpdateText(fmt.Sprintf("[%d/%d] %s", w.currentStep, w.totalSteps, description))
}

// Write implements io.Writer to sink logs to a file without breaking the pristine spinner UI.
func (w *Wizard) Write(p []byte) (n int, err error) {
	if w.logFile != nil {
		w.logFile.Write(p)
	}
	return len(p), nil
}

// Close gracefully stops the TUI elements and closes the log stream.
func (w *Wizard) Close() {
	if w.logFile != nil {
		w.logFile.Close()
	}
	if w.spinner != nil {
		w.spinner.Success("All steps completed successfully!")
	}
	pterm.Success.Println("A complete installation log has been saved to /tmp/nexus_install.log")
}
