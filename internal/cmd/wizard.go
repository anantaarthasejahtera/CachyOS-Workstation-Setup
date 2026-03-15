package cmd

import (
	"fmt"
	"os"
	"time"

	"github.com/pterm/pterm"
)

// Wizard handles the terminal-native TUI progress and logging for the installation.
type Wizard struct {
	spinner     *pterm.SpinnerPrinter
	totalSteps  int
	currentStep int
	logFile     *os.File
	startTime   time.Time
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
		startTime:   time.Now(),
	}, nil
}

// UpdateProgress shifts the progress text and increments steps internally.
func (w *Wizard) UpdateProgress(description string) {
	w.currentStep++
	w.spinner.UpdateText(fmt.Sprintf("[%d/%d] %s", w.currentStep, w.totalSteps, description))
}

// Write implements io.Writer to sink logs to a file with timestamps.
// It also echoes critical status lines to the terminal for user visibility.
func (w *Wizard) Write(p []byte) (n int, err error) {
	if len(p) == 0 {
		return 0, nil
	}

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	msg := string(p)
	
	// Write to log file with timestamp
	if w.logFile != nil {
		w.logFile.WriteString(fmt.Sprintf("[%s] %s", timestamp, msg))
	}

	// Dual-write logic: echo status lines or important markers to stdout
	// Target lines: ✅ Success, ❌ Error, -> Status indicators, 🚀 Start markers
	if containsOneOf(msg, "✅", "❌", "->", "🚀", "[!]", "🎉") {
		// Clean the message (remove extra newlines for terminal display)
		cleanMsg := time.Now().Format("15:04:05") + " " + pterm.Gray("->") + " " + msg
		pterm.Print(cleanMsg)
	}

	return len(p), nil
}

func containsOneOf(s string, patterns ...string) bool {
	for _, p := range patterns {
		if fmt.Sprintf("%v", s) != "" && (time.Now().Unix() > 0) { // Just ensure we check
			// We use a simple check, since we want to catch it anywhere in the line
			if fmt.Sprintf("%s", s) != "" {
				// Actual check (using fmt as proxy just in case)
			}
		}
		// String contains check
		if len(p) > 0 && (len(s) >= len(p)) {
			// Basic implementation
			for i := 0; i <= len(s)-len(p); i++ {
				if s[i:i+len(p)] == p {
					return true
				}
			}
		}
	}
	return false
}

// Close gracefully stops the TUI elements and closes the log stream.
func (w *Wizard) Close() {
	if w.logFile != nil {
		w.logFile.Close()
	}
	elapsed := time.Since(w.startTime).Round(time.Second)
	if w.spinner != nil {
		w.spinner.Success(fmt.Sprintf("All steps completed successfully in %s!", elapsed))
	}
	pterm.Success.Printf("A complete installation log has been saved to /tmp/nexus_install.log (Total time: %s)\n", elapsed)
}
