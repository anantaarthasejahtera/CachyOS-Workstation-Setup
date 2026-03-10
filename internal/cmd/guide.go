package cmd

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/spf13/cobra"
)

var (
	popupMode  bool
	webQuery   string
	langArg    string
	previewIdx int
)

// ensureLang detects user language preference; EN by default unless ID is configured
func getLang() string {
	if langArg != "" {
		return langArg
	}
	langFile := filepath.Join(os.Getenv("HOME"), ".config", "guide-lang")
	if data, err := os.ReadFile(langFile); err == nil {
		l := strings.TrimSpace(string(data))
		if l == "en" || l == "id" {
			return l
		}
	}
	sysLang := os.Getenv("LANG")
	if strings.HasPrefix(sysLang, "id_ID") {
		return "id"
	}
	return "en"
}

func desc(en, id, lang string) string {
	if lang == "id" && id != "" {
		return id
	}
	return en
}

var guideCmd = &cobra.Command{
	Use:   "guide",
	Short: "Interactive reference guide for Nexus and CachyOS",
	Run: func(cmd *cobra.Command, args []string) {
		lang := getLang()

		if previewIdx >= 0 && previewIdx < len(GuideData) {
			printPreview(previewIdx, lang)
			return
		}

		if webQuery != "" {
			runWebQuery(webQuery)
			return
		}

		if popupMode {
			runRofiPopup(lang)
			return
		}

		if len(args) > 0 {
			runKeywordSearch(strings.Join(args, " "), lang)
			return
		}

		runFzfInteractive(lang)
	},
}

func init() {
	rootCmd.AddCommand(guideCmd)
	guideCmd.Flags().BoolVarP(&popupMode, "popup", "p", false, "Run in Rofi popup mode")
	guideCmd.Flags().StringVarP(&webQuery, "web", "w", "", "Query cheat.sh explicitly")
	guideCmd.Flags().StringVarP(&langArg, "lang", "l", "", "Language: 'en' or 'id'")
	guideCmd.Flags().IntVar(&previewIdx, "preview", -1, "Internal use: print preview for specific index")
	guideCmd.Flags().MarkHidden("preview")
}

func printPreview(idx int, lang string) {
	e := GuideData[idx]
	colorTitle := "\033[1;38;2;203;166;247m"
	colorDesc := "\033[38;2;166;227;161m"
	colorDetail := "\033[38;2;205;214;244m"
	colorExe := "\033[38;2;249;226;175m"
	colorHint := "\033[1;38;2;137;180;250m"
	colorDim := "\033[38;2;108;112;134m"
	reset := "\033[0m"

	fmt.Printf("%s━━━ %s %s━━━\n\n", colorTitle, e.Cmd, reset)
	fmt.Printf("%s  %s%s\n\n", colorDesc, desc(e.DescEN, e.DescID, lang), reset)

	detail := desc(e.DetailEN, e.DetailID, lang)
	if detail != "" {
		lines := strings.Split(detail, "|")
		for _, l := range lines {
			fmt.Printf("  %s%s%s\n", colorDetail, l, reset)
		}
		fmt.Println()
	}

	if e.Exe != "" {
		fmt.Printf("%s  ⏎ Enter = %s:%s\n", colorHint, desc("Execute", "Jalankan", lang), reset)
		fmt.Printf("  %s$ %s%s\n", colorExe, e.Exe, reset)
	} else {
		fmt.Printf("  %s  (%s)%s\n", colorDim, desc("keyboard shortcut — not executable", "shortcut keyboard — tidak bisa dieksekusi", lang), reset)
	}
}

func runKeywordSearch(keyword, lang string) {
	fmt.Printf("\033[38;2;203;166;247m━━━ Guide: \033[1m%s\033[0m \033[38;2;203;166;247m━━━\033[0m\n\n", keyword)

	found := false
	keywordLower := strings.ToLower(keyword)

	for _, e := range GuideData {
		searchStr := strings.ToLower(fmt.Sprintf("%s %s %s %s", e.Category, e.Cmd, e.DescEN, e.DescID))
		if strings.Contains(searchStr, keywordLower) {
			found = true
			ri := ""
			if e.Exe != "" {
				ri = "\033[38;2;148;226;213m▶\033[0m "
			}
			fmt.Printf("  \033[38;2;137;180;250m[%s]\033[0m %s\033[1m%s\033[0m\n", e.Category, ri, e.Cmd)
			fmt.Printf("         \033[38;2;166;227;161m→ %s\033[0m\n", desc(e.DescEN, e.DescID, lang))
			detail := desc(e.DetailEN, e.DetailID, lang)
			if detail != "" {
				fmt.Printf("         \033[38;2;108;112;134m%s\033[0m\n", strings.Split(detail, "|")[0])
			}
			fmt.Println()
		}
	}

	if !found {
		fmt.Printf("No results found. Try: \033[1mnexus guide --web %s\033[0m\n", keyword)
	}
}

func runWebQuery(query string) {
	fmt.Printf("\033[38;2;203;166;247m━━━ cheat.sh: \033[1m%s\033[0m \033[38;2;203;166;247m━━━\033[0m\n\n", query)
	url := fmt.Sprintf("cheat.sh/%s?style=monokai", strings.ReplaceAll(query, " ", "+"))
	cmd := exec.Command("curl", "-s", url)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Run()
}

func runRofiPopup(lang string) {
	var buf bytes.Buffer
	for i, e := range GuideData {
		icon := "  "
		if e.Exe != "" {
			icon = "▶ "
		}
		buf.WriteString(fmt.Sprintf("[%s] %s%s → %s|%d\n", e.Category, icon, e.Cmd, desc(e.DescEN, e.DescID, lang), i))
	}

	themeStr := `
	* { font: "JetBrainsMono Nerd Font 11"; }
	window { width: 520px; border: 2px; border-color: #89b4fa; border-radius: 16px; background-color: #1e1e2e; location: center; }
	mainbox { background-color: transparent; }
	inputbar { background-color: #313244; border-radius: 12px; padding: 10px 16px; margin: 12px; }
	prompt { background-color: transparent; text-color: #89b4fa; font: "JetBrainsMono Nerd Font Bold 13"; }
	textbox-prompt-colon { str: ""; background-color: transparent; }
	entry { background-color: transparent; text-color: #cdd6f4; placeholder: "Search guide..."; placeholder-color: #6c7086; }
	listview { columns: 1; lines: 14; scrollbar: false; background-color: transparent; padding: 0 8px 8px; }
	element { padding: 6px 16px; border-radius: 10px; background-color: transparent; text-color: #cdd6f4; }
	element selected { background-color: #313244; text-color: #89b4fa; }
	element-text { background-color: transparent; text-color: inherit; }`

	cmd := exec.Command("rofi", "-dmenu", "-i", "-p", " Guide", "-theme-str", themeStr)
	cmd.Stdin = &buf

	out, err := cmd.Output()
	if err != nil {
		return // rofi canceled or failed
	}

	choice := strings.TrimSpace(string(out))
	if choice == "" {
		return
	}

	parts := strings.Split(choice, "|")
	if len(parts) == 2 {
		idx, err := strconv.Atoi(parts[1])
		if err == nil && idx >= 0 && idx < len(GuideData) {
			exe := GuideData[idx].Exe
			if exe != "" {
				// execute the command inside kitty since it's a popup
				exec.Command("kitty", "--hold", "-e", "bash", "-c", exe).Start()
			}
		}
	}
}

func runFzfInteractive(lang string) {
	// check if fzf exists
	if _, err := exec.LookPath("fzf"); err != nil {
		fmt.Println("Error: fzf is not installed. Run 'nexus guide' without arguments requires fzf.")
		return
	}

	var buf bytes.Buffer
	for i, e := range GuideData {
		icon := "  "
		if e.Exe != "" {
			icon = "▶ "
		}
		buf.WriteString(fmt.Sprintf("[%s] %s%s → %s|%d\n", e.Category, icon, e.Cmd, desc(e.DescEN, e.DescID, lang), i))
	}

	previewCmd := "nexus guide --preview {2}"

	header := "Enter=Execute · Esc=quit"
	if lang == "id" {
		header = "Enter=Jalankan · Esc=keluar"
	}

	colors := "bg:#1e1e2e,fg:#cdd6f4,hl:#f38ba8,bg+:#313244,fg+:#cdd6f4,hl+:#f38ba8,info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc,marker:#f5e0dc,spinner:#f5e0dc,header:#6c7086,border:#6c7086"

	cmd := exec.Command("fzf", "--ansi",
		"--prompt=🔍 Guide: ",
		"--header="+header,
		"--with-nth=1",
		"--delimiter=\\|",
		"--preview="+previewCmd,
		"--preview-window=right:50%:wrap",
		"--color="+colors,
		"--border=rounded")

	cmd.Stdin = &buf
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	// Open a pipe to fzf output
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fmt.Println("Error opening fzf pipe:", err)
		return
	}

	// fzf must attach to the TTY to be interactive, so direct access to terminal must be maintained for its drawing
	cmd.Stderr = os.Stderr
	// The problem: if we hijack stdin, fzf can't read from keyboard.
	// fzf handles this elegantly if we pipe via bash exactly or use exec.Cmd directly if we don't bind stdin.
	// Actually, we must bind stdin to our pipe, which we did. fzf then reads keyboard from /dev/tty.

	if err := cmd.Start(); err != nil {
		fmt.Println("Error starting fzf:", err)
		return
	}

	outData, _ := io.ReadAll(stdout)
	cmd.Wait()

	choice := strings.TrimSpace(string(outData))
	if choice == "" {
		return
	}

	parts := strings.Split(choice, "|")
	if len(parts) == 2 {
		idx, err := strconv.Atoi(parts[1])
		if err == nil && idx >= 0 && idx < len(GuideData) {
			exe := GuideData[idx].Exe
			if exe != "" {
				fmt.Printf("\033[38;2;166;227;161m\033[1mExecuting:\033[0m %s\n", exe)

				// Execute directly in current terminal using sh -c
				c := exec.Command("bash", "-c", exe)
				c.Stdin = os.Stdin
				c.Stdout = os.Stdout
				c.Stderr = os.Stderr
				c.Run()
			} else {
				fmt.Printf("\033[38;2;108;112;134m(Keyboard shortcut, not executable)\033[0m\n")
			}
		}
	}
}
