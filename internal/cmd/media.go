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

func runCommand(name string, arg ...string) (string, error) {
	cmd := exec.Command(name, arg...)
	
	// Waybar execution environment often strips standard PATH
	env := os.Environ()
	hasPath := false
	for _, e := range env {
		if strings.HasPrefix(e, "PATH=") {
			hasPath = true
		}
	}
	if !hasPath {
		env = append(env, "PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin")
	}
	cmd.Env = env

	out, err := cmd.Output()
	return strings.TrimSpace(string(out)), err
}

func getCommandOutput(name string, arg ...string) string {
	out, _ := runCommand(name, arg...)
	return out
}

func showMediaMenu() error {
	status := getCommandOutput("playerctl", "status")
	if status == "" {
		runCommand("notify-send", "Media Hub", "No media player is currently running.")
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

	// Rofi script mode protocol

	// 1. Message with large title and medium artist
	mesg := fmt.Sprintf("<span weight='bold' size='large'>%s</span> - <span size='medium'>%s</span>", escapeMarkup(title), escapeMarkup(artist))
	fmt.Printf("\x00message\x1f%s\n", mesg)

	// 2. Prompt title
	fmt.Printf("\x00prompt\x1fMedia\n")

	// 3. Keep selection if re-running
	fmt.Printf("\x00keep-selection\x1ftrue\n")

	// 4. Inject dynamic theme string for cover art
	themeStr := fmt.Sprintf("cover-art { background-image: url(\"%s\", width); }", coverPath)
	fmt.Printf("\x00theme\x1f%s\n", themeStr)

	// Print the options themselves
	fmt.Println(prevOpt)
	fmt.Println(playPauseOpt)
	fmt.Println(nextOpt)
	fmt.Println(visOpt)

	return nil
}

func handleMediaAction(action string) error {
	switch action {
	case "󰒮 Prev":
		runCommand("playerctl", "previous")
		waitForMetadataUpdate()
	case "󰏤 Pause", "󰐊 Play":
		runCommand("playerctl", "play-pause")
	case "󰒭 Next":
		runCommand("playerctl", "next")
		waitForMetadataUpdate()
	case "󱍙 Visualizer":
		if _, err := exec.LookPath("cava"); err == nil {
			cmd := exec.Command("kitty", "--class", "cava-floating", "-e", "cava")
			cmd.Env = append(os.Environ(), "PATH=/usr/local/bin:/usr/bin:/bin")
			cmd.Start()
		} else {
			runCommand("notify-send", "Visualizer", "Cava is not installed. Please install it via 'sudo pacman -S cava'.")
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
