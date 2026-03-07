#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Guide v2 — Interactive Executable Reference for CachyOS Workstation
#  
#  Modes:
#    guide              → fzf interactive (preview pane, Enter = execute)
#    guide <keyword>    → instant filter + colored output
#    guide --popup      → rofi popup mode (integrated with Nexus)
#    guide --web <q>    → query cheat.sh for any command
#
#  Features:
#    • Executable entries — press Enter to RUN the command
#    • Preview pane — detailed explanation + examples
#    • Dynamic detection — only show installed tools
#    • cheat.sh fallback — online reference for anything
#    • Dual UI — terminal (fzf) + popup (rofi)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ─── Catppuccin Colors ────────────────────────────────────
C_MAUVE='\033[38;2;203;166;247m'
C_BLUE='\033[38;2;137;180;250m'
C_GREEN='\033[38;2;166;227;161m'
C_RED='\033[38;2;243;139;168m'
C_YELLOW='\033[38;2;249;226;175m'
C_TEAL='\033[38;2;148;226;213m'
C_TEXT='\033[38;2;205;214;244m'
C_DIM='\033[38;2;108;112;134m'
NC='\033[0m'
BOLD='\033[1m'

# ─── Guide Data ──────────────────────────────────────────
# Format: CATEGORY|COMMAND|DESCRIPTION|DETAIL|EXECUTABLE
# EXECUTABLE = the actual command to run (empty = not runnable)
build_guide_data() {
    local data=""

    # Helper: add entry only if tool exists
    add() {
        local cat="$1" cmd="$2" desc="$3" detail="$4" exe="$5" check="${6:-}"
        if [ -n "$check" ]; then
            command -v "$check" &>/dev/null || return
        fi
        data+="${cat}|${cmd}|${desc}|${detail}|${exe}\n"
    }

    # ── Hyprland ──
    add "hyprland" "Super+Return" "Open Kitty terminal" "Launch the GPU-accelerated Kitty terminal emulator" "" ""
    add "hyprland" "Super+D" "App launcher (Rofi)" "Searchable app launcher with icons" "" ""
    add "hyprland" "Super+X" "Nexus Command Center" "Smart popup with system stats, quick actions, AI tools" "" ""
    add "hyprland" "Super+Q" "Close window" "Kill the currently focused window" "" ""
    add "hyprland" "Super+F" "Fullscreen toggle" "Make current window fullscreen or restore" "" ""
    add "hyprland" "Super+Space" "Toggle floating" "Switch window between tiling and floating mode" "" ""
    add "hyprland" "Super+1-9" "Switch workspace" "Jump to workspace 1-9" "" ""
    add "hyprland" "Super+Shift+1-9" "Move to workspace" "Send window to workspace 1-9" "" ""
    add "hyprland" "Super+Arrow" "Move focus" "Navigate between windows with arrow keys" "" ""
    add "hyprland" "Super+Shift+Arrow" "Move window" "Reposition window in the tiling layout" "" ""
    add "hyprland" "Super+L" "Lock screen" "Hyprlock with blurred wallpaper + clock" "" ""
    add "hyprland" "Super+E" "File manager" "Open Thunar file manager" "" ""
    add "hyprland" "Super+V" "Clipboard history" "Browse copied text/images (cliphist)" "" ""
    add "hyprland" "Super+/" "Keybind cheatsheet" "Show floating window with all shortcuts" "" ""
    add "hyprland" "Super+Shift+S" "Screenshot region" "Select area to screenshot (grim+slurp)" "" ""
    add "hyprland" "Print" "Screenshot full" "Capture entire screen" "" ""

    # ── Terminal ──
    add "terminal" "kitty" "GPU-accelerated terminal" "Features: ligatures, images, transparency|Config: ~/.config/kitty/kitty.conf" "" "kitty"
    add "terminal" "tmux" "Terminal multiplexer" "Split panes, tabs, persistent sessions|Prefix: Ctrl+A (remapped from Ctrl+B)" "" "tmux"
    add "terminal" "Ctrl+A c" "tmux: New window" "Create a new tmux window (tab)" "" ""
    add "terminal" "Ctrl+A n/p" "tmux: Next/prev window" "Switch between tmux windows" "" ""
    add "terminal" "Ctrl+A |" "tmux: Split vertical" "Create vertical split pane" "" ""
    add "terminal" "Ctrl+A -" "tmux: Split horizontal" "Create horizontal split pane" "" ""
    add "terminal" "Ctrl+A Shift+I" "tmux: Install plugins" "Required after first tmux launch to get Catppuccin theme" "" ""

    # ── Shell ──
    add "shell" "z <dir>" "Smart cd (zoxide)" "Learns your frequently used directories. Just type partial name|Example: z proj → jumps to ~/projects" "z" "zoxide"
    add "shell" "Ctrl+R" "Search history" "Fuzzy search through command history with fzf" "" ""
    add "shell" "Tab" "Smart autocomplete" "fzf-tab powered completion with previews" "" ""
    add "shell" "ls / ll / la" "eza (modern ls)" "Icons, git status, tree view|ll = long format, la = show hidden" "eza --icons --group-directories-first" "eza"
    add "shell" "cat <file>" "bat (syntax highlight)" "Like cat but with syntax highlighting, line numbers, git diff|Themes: Catppuccin Mocha" "bat --style=auto" "bat"
    add "shell" "find <name>" "fd (fast find)" "10x faster than find, respects .gitignore|Example: fd '.rs$' → find all Rust files" "fd" "fd"
    add "shell" "grep <pattern>" "rg (ripgrep)" "Blazing fast grep, auto-skips binary/gitignored files|Example: rg 'TODO' → search all files for TODO" "rg" "rg"
    add "shell" "top / btm" "bottom (system monitor)" "Beautiful TUI system monitor with CPU, RAM, disk, network graphs" "btm" "btm"
    add "shell" "ff" "fastfetch (system info)" "Show system info: OS, CPU, GPU, RAM, uptime, theme" "fastfetch" "fastfetch"
    add "shell" "keys" "Keybind cheatsheet" "Show Hyprland keyboard shortcuts reference" "cat ~/.config/hypr/cheatsheet.txt" ""
    add "shell" "update" "System update" "Update pacman + flatpak + rustup in one command" "sudo pacman -Syu && flatpak update -y" ""
    add "shell" "cleanup" "Remove orphan packages" "Clean unused packages and pacman cache" "sudo pacman -Sc --noconfirm" ""

    # ── Git ──
    add "git" "git status" "Check changes" "Show modified, staged, and untracked files" "git status" "git"
    add "git" "git add . && git commit" "Stage & commit" "Stage all changes and open commit editor|Tip: git commit -m 'msg' for inline message" "git add ." "git"
    add "git" "git push" "Push to remote" "Upload commits to GitHub/remote|First push: git push -u origin main" "git push" "git"
    add "git" "gh auth login" "GitHub CLI login" "Authenticate with GitHub for CLI operations" "gh auth login" "gh"
    add "git" "gh repo create" "Create GitHub repo" "Interactive: choose name, visibility, description" "gh repo create" "gh"
    add "git" "gh pr create" "Create pull request" "Open PR from current branch" "gh pr create" "gh"
    add "git" "gl" "Git log (alias)" "Pretty oneline graph with decorations (last 20)" "git log --oneline --graph --decorate -20" "git"

    # ── Docker ──
    add "docker" "docker ps" "List containers" "Show running containers with ports and status|Add -a for all (including stopped)" "docker ps" "docker"
    add "docker" "docker compose up -d" "Start services" "Start all services defined in docker-compose.yml in background" "docker compose up -d" "docker"
    add "docker" "docker compose down" "Stop services" "Stop and remove all compose containers" "docker compose down" "docker"
    add "docker" "lazydocker" "Docker TUI" "Beautiful terminal UI for managing Docker containers, images, volumes" "lazydocker" "lazydocker"

    # ── Node.js ──
    add "node" "fnm use --lts" "Switch to LTS Node" "Fast Node Manager: switch Node.js versions instantly" "fnm use --lts" "fnm"
    add "node" "pnpm install" "Install dependencies" "Fast, disk-efficient package install (hard links)" "pnpm install" "pnpm"
    add "node" "pnpm run dev" "Start dev server" "Run the project's development server" "pnpm run dev" "pnpm"
    add "node" "pnpm add <pkg>" "Add package" "Install and save a new dependency" "" "pnpm"
    add "node" "pnpm dlx <cmd>" "Run CLI tool" "Like npx — run a package without installing globally" "" "pnpm"

    # ── Python ──
    add "python" "uv init" "Create project" "Initialize a new Python project with pyproject.toml" "uv init" "uv"
    add "python" "uv add <pkg>" "Add dependency" "Install package and add to pyproject.toml" "" "uv"
    add "python" "uv run script.py" "Run script" "Execute Python script in managed environment" "" "uv"

    # ── Rust ──
    add "rust" "cargo new <name>" "Create project" "Generate new Rust project with Cargo.toml" "" "cargo"
    add "rust" "cargo build" "Build" "Compile the project (debug mode)" "cargo build" "cargo"
    add "rust" "cargo run" "Run" "Build and execute the project" "cargo run" "cargo"
    add "rust" "cargo test" "Test" "Run all unit and integration tests" "cargo test" "cargo"

    # ── Go ──
    add "go" "go mod init <module>" "Create module" "Initialize a new Go module" "" "go"
    add "go" "go run ." "Run" "Compile and execute the current package" "go run ." "go"
    add "go" "go build" "Build" "Compile the package into binary" "go build" "go"

    # ── Flutter ──
    add "flutter" "flutter create <app>" "New project" "Generate Flutter project with platform dirs" "" "flutter"
    add "flutter" "flutter run" "Run app" "Launch on connected device or emulator" "flutter run" "flutter"
    add "flutter" "flutter build apk" "Build APK" "Create release APK for Android" "flutter build apk" "flutter"
    add "flutter" "flutter doctor" "Check setup" "Verify Flutter installation and dependencies" "flutter doctor" "flutter"
    add "flutter" "emulator -avd Pixel_7" "Launch emulator" "Start Android emulator (API 34 Pixel 7)" "emulator -avd Pixel_7" "emulator"
    add "flutter" "scrcpy" "Mirror phone" "Real-time phone screen mirroring via USB/WiFi" "scrcpy" "scrcpy"
    add "flutter" "adb devices" "List devices" "Show connected Android devices" "adb devices" "adb"

    # ── Editors ──
    add "editor" "antigravity" "AI coding editor" "VS Code fork with built-in AI assistant (Google)" "antigravity" "antigravity"
    add "editor" "nvim <file>" "Neovim" "Configured with lazy.nvim, Catppuccin, Telescope, LSP" "nvim" "nvim"
    add "editor" "nvim: Space" "Leader key" "Opens which-key popup showing all keybinds" "" "nvim"
    add "editor" "nvim: Space+ff" "Find files" "Telescope fuzzy file finder" "" "nvim"
    add "editor" "nvim: Space+fg" "Live grep" "Search text across all files (Telescope)" "" "nvim"

    # ── AI ──
    add "ai" "ollama run qwen3:30b-a3b" "Reasoning AI" "Best for debate, philosophy, strategy. MoE architecture (3B active)|~16GB RAM. Slow start, fast generation." "ollama run qwen3:30b-a3b" "ollama"
    add "ai" "ollama run deepseek-r1:7b" "Math & Logic" "Specialized in mathematical reasoning and proofs" "ollama run deepseek-r1:7b" "ollama"
    add "ai" "ollama run qwen2.5-coder:7b" "Code Assistant" "GPT-4o level coding. Autocomplete, refactor, explain code" "ollama run qwen2.5-coder:7b" "ollama"
    add "ai" "ollama list" "List models" "Show all downloaded models with sizes" "ollama list" "ollama"
    add "ai" "ollama pull <model>" "Download model" "Pull a new model from Ollama registry" "" "ollama"

    # ── Gaming ──
    add "gaming" "steam" "Steam launcher" "PC gaming platform. Proton enabled for Windows games" "steam" "steam"
    add "gaming" "gamemoderun <game>" "GameMode boost" "Auto-optimize CPU/GPU governor for gaming" "" "gamemoderun"
    add "gaming" "mangohud <game>" "FPS overlay" "MangoHud: show FPS, CPU, GPU, RAM. Toggle: F12" "" "mangohud"
    add "gaming" "prismlauncher" "Minecraft" "Open-source Minecraft launcher (multiple instances)" "prismlauncher" "prismlauncher"
    add "gaming" "pcsx2" "PS2 Emulator" "Play PS2 games (Black, GTA, etc). Config optimized for Intel" "pcsx2" "pcsx2"

    # ── VM ──
    add "vm" "virt-manager" "VM Manager" "GUI for creating/managing QEMU/KVM virtual machines" "virt-manager" "virt-manager"
    add "vm" "virsh list --all" "List VMs" "Show all virtual machines (running and stopped)" "virsh list --all" "virsh"
    add "vm" "virsh start <vm>" "Start VM" "Boot a stopped virtual machine" "" "virsh"
    add "vm" "virsh shutdown <vm>" "Stop VM" "Graceful shutdown of virtual machine" "" "virsh"

    # ── Apps ──
    add "apps" "bottles" "Windows apps" "Run Windows applications without a VM (Wine-based)" "flatpak run com.usebottles.bottles" ""
    add "apps" "libreoffice" "Office suite" "Open .docx, .xlsx, .pptx natively" "libreoffice" "libreoffice"
    add "apps" "obsidian" "Markdown notes" "Knowledge base with graph view, plugins, Catppuccin theme" "obsidian" ""
    add "apps" "keepassxc" "Password manager" "AES-256 encrypted, offline, auto-fill" "keepassxc" "keepassxc"
    add "apps" "obs-studio" "Screen recording" "Full recording studio: scenes, sources, streaming" "obs" "obs"

    # ── System ──
    add "system" "btm" "System monitor" "Beautiful graphs: CPU, RAM, disk, network, processes" "btm" "btm"
    add "system" "duf" "Disk usage" "Colorful disk usage with filesystem details" "duf" "duf"
    add "system" "dust <dir>" "Directory sizes" "Visualize which folders use most space" "dust" "dust"
    add "system" "procs" "Process list" "Better ps: colorized, sortable, filterable" "procs" "procs"
    add "system" "timeshift" "System backup" "Create/restore system snapshots (like Time Machine)" "sudo timeshift --create" "timeshift"

    # ── Network ──
    add "network" "nmcli device wifi list" "List WiFi" "Show available WiFi networks with signal strength" "nmcli device wifi list" "nmcli"
    add "network" "nmcli d wifi connect <SSID>" "Connect WiFi" "Connect to a WiFi network|Add: password <pw> for secured networks" "" "nmcli"
    add "network" "curl ifconfig.me" "Public IP" "Show your public IP address" "curl -s ifconfig.me && echo ''" "curl"
    add "network" "ss -tulnp" "Open ports" "Show all listening TCP/UDP ports with process names" "ss -tulnp" "ss"

    # ── Recording ──
    add "record" "wf-recorder -f out.mp4" "Record screen" "Lightweight Wayland screen recorder" "wf-recorder -f ~/Videos/recording-\$(date +%Y%m%d-%H%M%S).mp4" "wf-recorder"
    add "record" "grim ~/pic.png" "Screenshot full" "Full screen capture to PNG" "grim ~/Pictures/Screenshots/\$(date +%Y%m%d-%H%M%S).png" "grim"
    add "record" "grim -g \"\$(slurp)\"" "Screenshot region" "Select area with mouse to capture" "grim -g \"\$(slurp)\" ~/Pictures/Screenshots/\$(date +%Y%m%d-%H%M%S).png" "grim"

    echo -e "$data"
}

# ─── Preview Generator ───────────────────────────────────
generate_preview() {
    local line="$1"
    local cat=$(echo "$line" | cut -d'|' -f1)
    local cmd=$(echo "$line" | cut -d'|' -f2)
    local desc=$(echo "$line" | cut -d'|' -f3)
    local detail=$(echo "$line" | cut -d'|' -f4)
    local exe=$(echo "$line" | cut -d'|' -f5)
    
    echo -e "\033[1;38;2;203;166;247m━━━ $cmd ━━━\033[0m"
    echo ""
    echo -e "\033[38;2;166;227;161m  $desc\033[0m"
    echo ""
    
    if [ -n "$detail" ]; then
        echo "$detail" | tr '|' '\n' | while read -r line; do
            echo -e "  \033[38;2;205;214;244m$line\033[0m"
        done
        echo ""
    fi
    
    if [ -n "$exe" ]; then
        echo -e "\033[1;38;2;137;180;250m  ⏎ Enter to execute:\033[0m"
        echo -e "  \033[38;2;249;226;175m\$ $exe\033[0m"
    else
        echo -e "  \033[38;2;108;112;134m  (shortcut — not executable from here)\033[0m"
    fi
    
    echo ""
    echo -e "\033[38;2;108;112;134m  Category: [$cat]\033[0m"
}

# ─── Display for keyword search ──────────────────────────
display_results() {
    local keyword="$1"
    local data="$2"
    local results=$(echo -e "$data" | grep -i "$keyword")
    
    if [ -z "$results" ]; then
        echo -e "${C_MAUVE}No results for '${BOLD}$keyword${NC}${C_MAUVE}'.${NC}"
        echo -e "${C_DIM}Try: guide docker, guide flutter, guide ai, guide hyprland${NC}"
        echo ""
        echo -e "${C_TEAL}Or query online: ${BOLD}guide --web $keyword${NC}"
        return
    fi
    
    echo -e "${C_MAUVE}━━━ Guide: ${BOLD}$keyword${NC} ${C_MAUVE}━━━${NC}"
    echo ""
    echo "$results" | while IFS='|' read -r cat cmd desc detail exe; do
        local run_indicator=""
        [ -n "$exe" ] && run_indicator="${C_TEAL}▶${NC} "
        echo -e "  ${C_BLUE}[$cat]${NC} ${run_indicator}${BOLD}$cmd${NC}"
        echo -e "         ${C_GREEN}→ $desc${NC}"
        [ -n "$detail" ] && echo -e "         ${C_DIM}$(echo "$detail" | cut -d'|' -f1)${NC}"
        echo ""
    done
    
    echo -e "${C_DIM}Tip: Run 'guide' (no args) for interactive mode with preview + execute${NC}"
}

# ─── Rofi Popup Mode ─────────────────────────────────────
popup_mode() {
    local data=$(build_guide_data)
    local display_entries=""
    
    while IFS='|' read -r cat cmd desc detail exe; do
        [ -z "$cat" ] && continue
        local icon=""
        [ -n "$exe" ] && icon="▶ "
        display_entries+="[$cat] ${icon}$cmd → $desc\n"
    done <<< "$(echo -e "$data")"
    
    local chosen
    chosen=$(echo -e "$display_entries" | sed '/^$/d' | rofi -dmenu \
        -i \
        -p " Guide" \
        -theme-str "
            * { font: \"JetBrainsMono Nerd Font 11\"; }
            window {
                width: 520px;
                border: 2px;
                border-color: #89b4fa;
                border-radius: 16px;
                background-color: #1e1e2e;
                location: center;
            }
            mainbox { background-color: transparent; }
            inputbar {
                background-color: #313244;
                border-radius: 12px;
                padding: 10px 16px;
                margin: 12px;
            }
            prompt { background-color: transparent; text-color: #89b4fa; font: \"JetBrainsMono Nerd Font Bold 13\"; }
            textbox-prompt-colon { str: \"\"; background-color: transparent; }
            entry { background-color: transparent; text-color: #cdd6f4; placeholder: \"Search guide...\"; placeholder-color: #6c7086; }
            listview { columns: 1; lines: 14; scrollbar: false; background-color: transparent; padding: 0 8px 8px; }
            element { padding: 6px 16px; border-radius: 10px; background-color: transparent; text-color: #cdd6f4; }
            element selected { background-color: #313244; text-color: #89b4fa; }
            element-text { background-color: transparent; text-color: inherit; }
        ")
    
    if [ -n "$chosen" ]; then
        # Extract the command part and find matching entry
        local search_cmd=$(echo "$chosen" | sed 's/^\[.*\] //' | sed 's/^▶ //' | sed 's/ →.*//')
        local match=$(echo -e "$data" | grep -F "$search_cmd" | head -1)
        local exe=$(echo "$match" | cut -d'|' -f5)
        
        if [ -n "$exe" ]; then
            kitty --hold -e bash -c "$exe" &
        fi
    fi
}

# ─── cheat.sh Web Query ──────────────────────────────────
web_query() {
    local query="$*"
    echo -e "${C_MAUVE}━━━ cheat.sh: ${BOLD}$query${NC} ${C_MAUVE}━━━${NC}"
    echo ""
    curl -s "cheat.sh/${query// /+}?style=monokai" 2>/dev/null || \
        echo -e "${C_RED}Failed to reach cheat.sh. Check internet connection.${NC}"
}

# ─── Main ─────────────────────────────────────────────────
main() {
    # Handle flags
    case "${1:-}" in
        --popup|-p)
            popup_mode
            return ;;
        --web|-w)
            shift
            web_query "$@"
            return ;;
        --help|-h)
            echo -e "${C_MAUVE}${BOLD}Guide v2${NC} — Interactive Executable Reference"
            echo ""
            echo -e "  ${BOLD}guide${NC}              Interactive fzf (preview + execute)"
            echo -e "  ${BOLD}guide <keyword>${NC}    Filter by keyword (docker, git, etc)"
            echo -e "  ${BOLD}guide --popup${NC}      Rofi popup mode"
            echo -e "  ${BOLD}guide --web <q>${NC}    Query cheat.sh (online)"
            echo ""
            echo -e "  ${C_DIM}Categories: hyprland terminal shell git docker node python"
            echo -e "  rust go flutter editor ai gaming vm apps system network record${NC}"
            return ;;
    esac

    local data=$(build_guide_data)

    if [ -z "$1" ]; then
        # Interactive fzf mode with preview pane
        if command -v fzf &>/dev/null; then
            # Create temp preview script
            local preview_script=$(mktemp /tmp/guide-preview-XXXX.sh)
            cat > "$preview_script" << 'PREV'
#!/bin/bash
line="$1"
cat=$(echo "$line" | cut -d'|' -f1)
cmd=$(echo "$line" | cut -d'|' -f2)
desc=$(echo "$line" | cut -d'|' -f3)
detail=$(echo "$line" | cut -d'|' -f4)
exe=$(echo "$line" | cut -d'|' -f5)

echo -e "\033[1;38;2;203;166;247m━━━ $cmd ━━━\033[0m"
echo ""
echo -e "\033[38;2;166;227;161m  $desc\033[0m"
echo ""
if [ -n "$detail" ]; then
    echo "$detail" | tr '|' '\n' | while read -r l; do
        echo -e "  \033[38;2;205;214;244m$l\033[0m"
    done; echo ""
fi
if [ -n "$exe" ]; then
    echo -e "\033[1;38;2;137;180;250m  ⏎ Press Enter to execute:\033[0m"
    echo -e "  \033[38;2;249;226;175m\$ $exe\033[0m"
else
    echo -e "  \033[38;2;108;112;134m  (keyboard shortcut — not executable)\033[0m"
fi
echo ""
echo -e "\033[38;2;108;112;134m  Category: [$cat]\033[0m"
PREV
            chmod +x "$preview_script"

            # Format display: [cat] cmd → desc
            local display=$(echo -e "$data" | awk -F'|' '{
                exe = ($5 != "") ? "▶ " : "  ";
                if ($1 != "") printf "[%s] %s%s → %s\n", $1, exe, $2, $3
            }')

            local chosen
            chosen=$(echo "$display" | fzf \
                --ansi \
                --prompt="🔍 Guide: " \
                --header="Enter=Execute · Ctrl-W=cheat.sh · Esc=quit" \
                --preview="echo -e '$(echo -e "$data")' | grep -F '{2}' | head -1 | bash $preview_script /dev/stdin || echo 'No preview'" \
                --preview="bash $preview_script \"\$(echo -e '$(echo -e "$data" | sed "s/'/'\\\\''/g")' | grep -F \"\$(echo {} | sed 's/^\\[.*\\] //' | sed 's/^[▶ ]*//' | sed 's/ →.*//')\" | head -1)\"" \
                --preview-window=right:50%:wrap \
                --color="bg:#1e1e2e,fg:#cdd6f4,hl:#f38ba8,bg+:#313244,fg+:#cdd6f4,hl+:#f38ba8,info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc,marker:#f5e0dc,spinner:#f5e0dc,header:#6c7086,border:#6c7086" \
                --border=rounded \
                --bind="ctrl-w:execute(echo {} | sed 's/^\\[.*\\] //' | sed 's/ →.*//' | xargs -I{} curl -s 'cheat.sh/{}' | less)")

            rm -f "$preview_script"

            if [ -n "$chosen" ]; then
                # Extract command and find executable
                local search_cmd=$(echo "$chosen" | sed 's/^\[.*\] //' | sed 's/^[▶ ]*//' | sed 's/ →.*//')
                local match=$(echo -e "$data" | grep -F "$search_cmd" | head -1)
                local exe=$(echo "$match" | cut -d'|' -f5)
                
                if [ -n "$exe" ]; then
                    echo -e "${C_GREEN}${BOLD}Executing:${NC} $exe"
                    eval "$exe"
                else
                    echo -e "${C_DIM}(This entry is a keyboard shortcut, not executable)${NC}"
                fi
            fi
        else
            echo -e "$data" | column -t -s'|' | less
        fi
    else
        # Keyword search mode
        display_results "$*" "$data"
    fi
}

main "$@"
