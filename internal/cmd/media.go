package cmd

import (
	"crypto/md5"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/spf13/cobra"
)

var mediaCmd = &cobra.Command{
	Use:   "rofi-media",
	Short: "Aesthetic Rofi Media Hub",
	Long:  "Fetches current playing media and shows a beautiful dashboard using Rofi",
	RunE: func(cmd *cobra.Command, args []string) error {
		// If an argument is provided, execute the action instead of showing the menu
		if len(args) > 0 {
			return handleMediaAction(args[0])
		}
		return showMediaMenu()
	},
}

func init() {
	rootCmd.AddCommand(mediaCmd)
}

func getCommandOutput(name string, arg ...string) string {
	out, err := exec.Command(name, arg...).Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func showMediaMenu() error {
	status := getCommandOutput("playerctl", "status")
	if status == "" {
		exec.Command("notify-send", "Media Hub", "No media player is currently running.").Run()
		return nil
	}

	rawTitle := getCommandOutput("playerctl", "metadata", "title")
	rawArtist := getCommandOutput("playerctl", "metadata", "artist")

	title := rawTitle
	if len(title) > 35 {
		title = title[:35] + "..."
	}
	if title == "" {
		title = "Unknown Audio"
	}

	artist := rawArtist
	if len(artist) > 35 {
		artist = artist[:35] + "..."
	}
	if artist == "" {
		artist = "Unknown Artist"
	}

	// Cover art logic
	trackID := fmt.Sprintf("%x", md5.Sum([]byte(rawArtist+"-"+rawTitle)))
	coverPath := filepath.Join(os.TempDir(), fmt.Sprintf("rofi-media-cover-%s.png", trackID))

	// Clean up old covers
	files, _ := filepath.Glob(filepath.Join(os.TempDir(), "rofi-media-cover-*.png"))
	for _, f := range files {
		if f != coverPath {
			os.Remove(f)
		}
	}

	if _, err := os.Stat(coverPath); os.IsNotExist(err) {
		artURL := getCommandOutput("playerctl", "metadata", "mpris:artUrl")
		artURL = strings.TrimPrefix(artURL, "file://")

		if artURL != "" {
			if strings.HasPrefix(artURL, "http") {
				downloadCover(artURL, coverPath)
			} else {
				// Handle URL encoded file paths
				decodedURL, _ := url.QueryUnescape(artURL)
				if decodedURL != "" {
					artURL = decodedURL
				}
				copyFile(artURL, coverPath)
			}
		}

		// Ensure file exists even if blank
		if _, e := os.Stat(coverPath); os.IsNotExist(e) {
			os.WriteFile(coverPath, []byte(""), 0644)
		}
	}

	// Build the Rofi list
	prevOpt := "󰒮 Prev"
	nextOpt := "󰒭 Next"
	visOpt := "󱍙 Visualizer"
	playPauseOpt := "󰐊 Play"
	if status == "Playing" {
		playPauseOpt = "󰏤 Pause"
	}

	options := fmt.Sprintf("%s\n%s\n%s\n%s\n", prevOpt, playPauseOpt, nextOpt, visOpt)
	mesg := fmt.Sprintf("<span weight='bold' size='large'>%s</span> - <span size='medium'>%s</span>", escapeMarkup(title), escapeMarkup(artist))
	themeStr := fmt.Sprintf("cover-art { background-image: url(\"%s\", width); }", coverPath)

	home, _ := os.UserHomeDir()
	themePath := filepath.Join(home, ".config", "rofi", "media.rasi")

	cmd := exec.Command("rofi", "-dmenu",
		"-p", "Media",
		"-mesg", mesg,
		"-hover-select",
		"-me-select-entry", "",
		"-me-accept-entry", "MousePrimary",
		"-theme", themePath,
		"-theme-str", themeStr,
	)

	cmd.Stdin = strings.NewReader(options)
	out, err := cmd.Output()
	if err != nil {
		// Used exited Rofi
		return nil
	}

	choice := strings.TrimSpace(string(out))
	if choice != "" {
		return handleMediaAction(choice)
	}

	return nil
}

func handleMediaAction(action string) error {
	switch action {
	case "󰒮 Prev":
		exec.Command("playerctl", "previous").Run()
		waitForMetadataUpdate()
	case "󰏤 Pause", "󰐊 Play":
		exec.Command("playerctl", "play-pause").Run()
	case "󰒭 Next":
		exec.Command("playerctl", "next").Run()
		waitForMetadataUpdate()
	case "󱍙 Visualizer":
		if _, err := exec.LookPath("cava"); err == nil {
			exec.Command("kitty", "--class", "cava-floating", "-e", "cava").Start()
		} else {
			exec.Command("notify-send", "Visualizer", "Cava is not installed. Please install it via 'sudo pacman -S cava'.").Run()
		}
		// Visualizer exits Rofi, so we don't return an empty string to re-render
		return nil
	default:
		// Not recognized or escaping Rofi
		return nil
	}

	// Re-run the rofi-media command (since Rofi will execute the script again automatically if we don't output anything,
	// actually for a Rofi script, printing nothing stops it. But we want to re-render.
	// We can do this by just calling showMediaMenu() again in the same execution instance!
	// Wait, standard rofi script modi expects options on stdout. If an argument is passed,
	// printing new options restarts the UI from that point.
	return showMediaMenu()
}

func waitForMetadataUpdate() {
	rawTitle := getCommandOutput("playerctl", "metadata", "title")
	for i := 0; i < 20; i++ {
		time.Sleep(100 * time.Millisecond)
		newRaw := getCommandOutput("playerctl", "metadata", "title")
		if newRaw != rawTitle {
			break
		}
	}
}

func escapeMarkup(s string) string {
	s = strings.ReplaceAll(s, "&", "&amp;")
	s = strings.ReplaceAll(s, "<", "&lt;")
	s = strings.ReplaceAll(s, ">", "&gt;")
	return s
}

func downloadCover(url, dest string) {
	resp, err := http.Get(url)
	if err != nil {
		return
	}
	defer resp.Body.Close()

	out, err := os.Create(dest)
	if err != nil {
		return
	}
	defer out.Close()
	io.Copy(out, resp.Body)
}

func copyFile(src, dest string) {
	in, err := os.Open(src)
	if err != nil {
		return
	}
	defer in.Close()

	out, err := os.Create(dest)
	if err != nil {
		return
	}
	defer out.Close()
	io.Copy(out, in)
}
