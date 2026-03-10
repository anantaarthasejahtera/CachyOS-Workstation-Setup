package state

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

type Config struct {
	PackagesInstalled map[string]bool `json:"packages_installed"`
	LastUpdate        string          `json:"last_update"`
}

var StateDir = filepath.Join(os.Getenv("HOME"), ".local", "share", "nexus")
var StateFile = filepath.Join(StateDir, "state.json")

// Load reads the JSON state file. If it doesn't exist, it returns a new empty state.
func Load() (*Config, error) {
	if _, err := os.Stat(StateDir); os.IsNotExist(err) {
		os.MkdirAll(StateDir, 0755)
	}

	if _, err := os.Stat(StateFile); os.IsNotExist(err) {
		return &Config{PackagesInstalled: make(map[string]bool)}, nil
	}

	data, err := os.ReadFile(StateFile)
	if err != nil {
		return nil, err
	}

	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}

	if cfg.PackagesInstalled == nil {
		cfg.PackagesInstalled = make(map[string]bool)
	}

	return &cfg, nil
}

// Save writes the Config back to the JSON file.
func Save(cfg *Config) error {
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(StateFile, data, 0644)
}

// CreateBTRFSSnapperSnapshot attempts to create a BTRFS snapshot via snapper.
// It fails silently if snapper is not installed or the filesystem is not BTRFS,
// since this is a fail-safe mechanism, not a strict requirement.
func CreateBTRFSSnapperSnapshot(description string) {
	_, err := exec.LookPath("snapper")
	if err != nil {
		return // snapper not installed, ignore
	}

	cmd := exec.Command("sudo", "snapper", "create", "-d", fmt.Sprintf("Nexus: %s", description))
	// Run asynchronously or just don't handle error explicitly to avoid blocking
	_ = cmd.Run()
}
