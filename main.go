package main

import (
	"fmt"
	"os"

	"github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/internal/cmd"
)

// Version is injected at build time via: go build -ldflags="-X main.Version=v1.0.0"
var Version = "dev"

func main() {
	cmd.Version = Version
	if err := cmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
