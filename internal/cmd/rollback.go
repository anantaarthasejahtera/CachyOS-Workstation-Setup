package cmd

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"github.com/spf13/cobra"
)

var rollbackCmd = &cobra.Command{
	Use:   "rollback",
	Short: "Time Machine - Restore configurations",
	Long:  `Browse timestamped backups from ~/.config-backup/ and restore them using a Rofi GUI.`,
	Run: func(cmd *cobra.Command, args []string) {
		homeDir, _ := os.UserHomeDir()
		backupDir := filepath.Join(homeDir, ".config-backup")

		// Check if directory exists
		if _, err := os.Stat(backupDir); os.IsNotExist(err) {
			exec.Command("notify-send", "-u", "critical", "Time Machine", "No backups found in ~/.config-backup/").Start()
			return
		}

		// Read backup directories
		entries, err := os.ReadDir(backupDir)
		if err != nil || len(entries) == 0 {
			exec.Command("notify-send", "-u", "critical", "Time Machine", "No backups found in ~/.config-backup/").Start()
			return
		}

		var backups []string
		for _, entry := range entries {
			if entry.IsDir() {
				backups = append(backups, entry.Name())
			}
		}

		if len(backups) == 0 {
			exec.Command("notify-send", "-u", "critical", "Time Machine", "No backups found in ~/.config-backup/").Start()
			return
		}

		// Sort in reverse chronological order (newest first)
		sort.Sort(sort.Reverse(sort.StringSlice(backups)))

		// Create rofi prompt for snapshots
		rofiInput := strings.Join(backups, "\n")
		rofiCmd := exec.Command("rofi", "-dmenu", "-i", "-p", "🛡️ Select Snapshot", "-mesg", "Choose a backup timestamp to restore:")
		rofiCmd.Stdin = strings.NewReader(rofiInput)
		var out bytes.Buffer
		rofiCmd.Stdout = &out

		if err := rofiCmd.Run(); err != nil {
			// User pressed Esc
			return
		}

		selectedSnapshot := strings.TrimSpace(out.String())
		if selectedSnapshot == "" {
			return
		}

		snapshotDir := filepath.Join(backupDir, selectedSnapshot)

		// List files in this snapshot
		files, err := os.ReadDir(snapshotDir)
		if err != nil || len(files) == 0 {
			exec.Command("notify-send", "-u", "critical", "Time Machine", "Empty snapshot: "+selectedSnapshot).Start()
			return
		}

		var fileNames []string
		fileNames = append(fileNames, "📦 RESTORE ALL FILES IN SNAPSHOT")
		for _, f := range files {
			if !f.IsDir() {
				// Convert __ back to / for display
				displayPath := strings.ReplaceAll(f.Name(), "__", "/")
				fileNames = append(fileNames, displayPath)
			}
		}

		// Rofi prompt for files
		rofiFileInput := strings.Join(fileNames, "\n")
		rofiFileCmd := exec.Command("rofi", "-dmenu", "-i", "-p", "📄 Select File", "-mesg", fmt.Sprintf("Snapshot: %s", selectedSnapshot))
		rofiFileCmd.Stdin = strings.NewReader(rofiFileInput)
		var fileOut bytes.Buffer
		rofiFileCmd.Stdout = &fileOut

		if err := rofiFileCmd.Run(); err != nil {
			return
		}

		selectedFile := strings.TrimSpace(fileOut.String())
		if selectedFile == "" {
			return
		}

		// Execute restore logic
		if selectedFile == "📦 RESTORE ALL FILES IN SNAPSHOT" {
			// Restore all
			for _, f := range files {
				if f.IsDir() {
					continue
				}
				realPath := filepath.Join(homeDir, ".config", strings.ReplaceAll(f.Name(), "__", "/"))
				srcPath := filepath.Join(snapshotDir, f.Name())

				// Ensure dest dir exists
				os.MkdirAll(filepath.Dir(realPath), 0755)
				exec.Command("cp", "-r", srcPath, realPath).Run()
			}
			exec.Command("notify-send", "Time Machine", "Restored entire snapshot: "+selectedSnapshot).Start()
		} else {
			// Restore single file
			srcName := strings.ReplaceAll(selectedFile, "/", "__")
			srcPath := filepath.Join(snapshotDir, srcName)
			realPath := filepath.Join(homeDir, ".config", selectedFile)

			os.MkdirAll(filepath.Dir(realPath), 0755)
			if err := exec.Command("cp", "-r", srcPath, realPath).Run(); err == nil {
				exec.Command("notify-send", "Time Machine", "Restored: "+selectedFile).Start()
			} else {
				exec.Command("notify-send", "-u", "critical", "Time Machine", "Failed to restore: "+selectedFile).Start()
			}
		}

		// Reload common services if affected
		exec.Command("hyprctl", "reload").Start()
		exec.Command("killall", "-SIGUSR2", "waybar").Start()
	},
}

func init() {
	rootCmd.AddCommand(rollbackCmd)
}
