package cmd

import (
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "nexus",
	Short: "CachyOS Workstation Setup & Ecosystem Manager",
	Long: `Nexus is the central orchestration tool for CachyOS Workstation Setup.
It handles installation, configuration rollbacks, theme switching, and system health checks
in a premium, type-safe environment.`,
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() error {
	return rootCmd.Execute()
}

func init() {
	// Root command flags can be defined here
	// rootCmd.PersistentFlags().BoolVarP(&Verbose, "verbose", "v", false, "verbose output")
}
