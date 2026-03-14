package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/spf13/cobra"
)

var (
	titleStyle = lipgloss.NewStyle().MarginLeft(2).Bold(true).Foreground(lipgloss.Color("#cba6f7"))
	itemStyle  = lipgloss.NewStyle().PaddingLeft(4)
	selStyle   = lipgloss.NewStyle().PaddingLeft(2).Foreground(lipgloss.Color("#89b4fa"))
)

type themeInfo struct {
	id     string
	name   string
	col1   string
	col2   string
	shadow string
}

var themes = []themeInfo{
	{"catppuccin", "☕ Catppuccin Mocha", "cba6f7", "89b4fa", "1a1a2e"},
	{"nord", "❄️ Nord Frost", "81A1C1", "88C0D0", "2E3440"},
	{"dracula", "🧛 Dracula", "ff79c6", "bd93f9", "282a36"},
}

type themeModel struct {
	cursor   int
	chosen   *themeInfo
	original string // Store the original theme string here if we needed to fully parse, but for now we rely on the filesystem as SSOT upon ESC
	quitting bool
}

func initialModel() themeModel {
	return themeModel{}
}

func (m themeModel) Init() tea.Cmd {
	return nil
}

func (m themeModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q", "esc":
			m.quitting = true
			// Revert to original by reloading hyprland config
			exec.Command("hyprctl", "reload").Run()
			return m, tea.Quit
		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
				applyLivePreview(themes[m.cursor])
			}
		case "down", "j":
			if m.cursor < len(themes)-1 {
				m.cursor++
				applyLivePreview(themes[m.cursor])
			}
		case "enter", " ":
			m.chosen = &themes[m.cursor]
			m.quitting = true
			applyPermanentConfig(*m.chosen)
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m themeModel) View() string {
	if m.quitting {
		if m.chosen != nil {
			return fmt.Sprintf("\n  ✨ Workstation themed to %s! Config saved.\n\n", m.chosen.name)
		}
		return "\n  Theme preview cancelled. Original borders restored.\n\n"
	}

	s := "\n" + titleStyle.Render("Nexus Live Theme Switcher") + "\n\n"
	s += "  (Use Up/Down to preview borders instantly. Enter to save. ESC to cancel)\n\n"

	for i, choice := range themes {
		cursor := " "
		if m.cursor == i {
			cursor = ">"
			s += selStyle.Render(fmt.Sprintf("%s %s", cursor, choice.name)) + "\n"
		} else {
			s += itemStyle.Render(fmt.Sprintf("%s %s", cursor, choice.name)) + "\n"
		}
	}

	s += "\n  Press q to quit.\n"
	return s
}

// applyLivePreview tweaks Hyprland instantly in RAM without saving
func applyLivePreview(t themeInfo) {
	str1 := fmt.Sprintf("rgba(%see)", t.col1)
	str2 := fmt.Sprintf("rgba(%see)", t.col2)
	exec.Command("hyprctl", "keyword", "general:col.active_border", fmt.Sprintf("%s %s 45deg", str1, str2)).Run()

	strShadow := fmt.Sprintf("rgba(%see)", t.shadow)
	exec.Command("hyprctl", "keyword", "decoration:col.shadow", strShadow).Run()
}

// applyPermanentConfig edits hyprland.conf and reloads waybar
func applyPermanentConfig(t themeInfo) {
	homeDir, _ := os.UserHomeDir()
	hyprConfig := filepath.Join(homeDir, ".config", "hypr", "hyprland.conf")

	content, err := os.ReadFile(hyprConfig)
	if err == nil {
		configStr := string(content)

		reBorder := regexp.MustCompile(`col\.active_border\s*=\s*rgba\([a-zA-Z0-9]+\)\s*rgba\([a-zA-Z0-9]+\)\s*\d+deg`)
		replacement := fmt.Sprintf("col.active_border = rgba(%see) rgba(%see) 45deg", t.col1, t.col2)
		configStr = reBorder.ReplaceAllString(configStr, replacement)

		reShadow := regexp.MustCompile(`color\s*=\s*rgba\([a-zA-Z0-9]+\)`)
		shadowReplacement := fmt.Sprintf("color = rgba(%see)", t.shadow)
		configStr = reShadow.ReplaceAllString(configStr, shadowReplacement)

		os.WriteFile(hyprConfig, []byte(configStr), 0644)
	}

	// Update Rofi (config.rasi & media.rasi)
	rofiPaths := []string{
		filepath.Join(homeDir, ".config", "rofi", "config.rasi"),
		filepath.Join(homeDir, ".config", "rofi", "media.rasi"),
	}
	for _, p := range rofiPaths {
		if content, err := os.ReadFile(p); err == nil {
			reAccent := regexp.MustCompile(`accent:\s*#[a-zA-Z0-9]+;`)
			newRofi := reAccent.ReplaceAllString(string(content), fmt.Sprintf("accent:   #%s;", t.col1))
			os.WriteFile(p, []byte(newRofi), 0644)
		}
	}

	// Update Kitty
	kittyConfig := filepath.Join(homeDir, ".config", "kitty", "kitty.conf")
	if content, err := os.ReadFile(kittyConfig); err == nil {
		reTabBg := regexp.MustCompile(`active_tab_background\s*#[a-zA-Z0-9]+`)
		newKitty := reTabBg.ReplaceAllString(string(content), fmt.Sprintf("active_tab_background #%s", t.col1))
		os.WriteFile(kittyConfig, []byte(newKitty), 0644)
	}

	// Update Waybar
	waybarConfig := filepath.Join(homeDir, ".config", "waybar", "style.css")
	if content, err := os.ReadFile(waybarConfig); err == nil {
		wb := string(content)
		// Gradient active workspace
		reGradient := regexp.MustCompile(`linear-gradient\(135deg,\s*#[a-zA-Z0-9]+,\s*#[a-zA-Z0-9]+\)`)
		wb = reGradient.ReplaceAllString(wb, fmt.Sprintf("linear-gradient(135deg, #%s, #%s)", t.col1, t.col2))
		
		// Clock Font Color (specifically targeting the #clock block)
		reClock := regexp.MustCompile(`#clock \{\s*font-weight:\s*600;\s*color:\s*#[a-zA-Z0-9]+;`)
		wb = reClock.ReplaceAllString(wb, fmt.Sprintf("#clock {\n    font-weight: 600;\n    color: #%s;", t.col1))

		// Tooltip Border 
		reBorder := regexp.MustCompile(`border:\s*1px\s*solid\s*#[a-zA-Z0-9]+;`)
		wb = reBorder.ReplaceAllString(wb, fmt.Sprintf("border: 1px solid #%s;", t.col1))

		os.WriteFile(waybarConfig, []byte(wb), 0644)
	}

	// Persist
	exec.Command("hyprctl", "reload").Run()
	// Restart Waybar logic for live CSS changes (placeholder for now/waybar reload)
	exec.Command("killall", "-SIGUSR2", "waybar").Run()
}

var themeCmd = &cobra.Command{
	Use:   "theme [theme_name]",
	Short: "Switch system themes instantaneously",
	Long:  `Instantly preview and switch Hyprland & Waybar themes using an interactive Terminal UI.`,
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) > 0 {
			// Direct CLI apply wrapper
			themeName := args[0]
			var found *themeInfo
			for _, t := range themes {
				if t.id == themeName {
					found = &t
					break
				}
			}
			if found != nil {
				applyLivePreview(*found)
				applyPermanentConfig(*found)
				fmt.Printf("\n✨ Applied ecosystem theme: %s\n\n", found.name)
			} else {
				fmt.Println("❌ Unknown theme.")
			}
			return
		}

		p := tea.NewProgram(initialModel())
		if _, err := p.Run(); err != nil {
			fmt.Printf("Alas, there's been an error: %v", err)
			os.Exit(1)
		}
	},
}

func init() {
	rootCmd.AddCommand(themeCmd)
}
