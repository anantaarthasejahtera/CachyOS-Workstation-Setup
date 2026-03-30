package cmd

import (
	"fmt"
	"os"
	"strings"
	"sync"
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
	mu          sync.Mutex // Guards concurrent writes from subprocess stdout/stderr
	closeOnce   sync.Once  // Prevents double-close panics
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

	f, err := os.OpenFile("/tmp/nexus_install.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		// Non-fatal: proceed without log file
		pterm.Warning.Printf("Could not open log file: %v\n", err)
		f = nil
	}

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
	w.mu.Lock()
	defer w.mu.Unlock()
	w.currentStep++
	w.spinner.UpdateText(fmt.Sprintf("[%d/%d] %s", w.currentStep, w.totalSteps, description))
}

// Write implements io.Writer to sink logs to a file with timestamps.
// It also echoes critical status lines to the terminal for user visibility.
// Thread-safe: guarded by mutex for concurrent subprocess stdout/stderr writes.
func (w *Wizard) Write(p []byte) (n int, err error) {
	if len(p) == 0 {
		return 0, nil
	}

	w.mu.Lock()
	defer w.mu.Unlock()

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	msg := string(p)

	// Write to log file with timestamp
	if w.logFile != nil {
		w.logFile.WriteString(fmt.Sprintf("[%s] %s", timestamp, msg))
	}

	// Dual-write logic: echo status lines or important markers to stdout
	if containsOneOf(msg, "✅", "❌", "->", "🚀", "[!]", "🎉") {
		cleanMsg := time.Now().Format("15:04:05") + " " + pterm.Gray("->") + " " + msg
		pterm.Print(cleanMsg)
	}

	return len(p), nil
}

// containsOneOf returns true if s contains any of the given patterns.
// Uses strings.Contains which is rune-aware and handles multi-byte UTF-8 (emoji) correctly.
func containsOneOf(s string, patterns ...string) bool {
	for _, p := range patterns {
		if strings.Contains(s, p) {
			return true
		}
	}
	return false
}

// Close gracefully stops the TUI elements and closes the log stream.
// Safe to call multiple times thanks to sync.Once.
func (w *Wizard) Close() {
	w.CloseWithStatus(false)
}

// CloseWithStatus gracefully stops TUI elements. If hadErrors is true,
// the spinner shows a warning instead of a misleading success message.
func (w *Wizard) CloseWithStatus(hadErrors bool) {
	w.closeOnce.Do(func() {
		if w.logFile != nil {
			w.logFile.Close()
		}
		elapsed := time.Since(w.startTime).Round(time.Second)
		if w.spinner != nil {
			if hadErrors {
				w.spinner.Warning(fmt.Sprintf("Completed with errors in %s. Check log for details.", elapsed))
			} else {
				w.spinner.Success(fmt.Sprintf("All steps completed successfully in %s!", elapsed))
			}
		}
		pterm.Success.Printf("A complete installation log has been saved to /tmp/nexus_install.log (Total time: %s)\n", elapsed)
	})
}
