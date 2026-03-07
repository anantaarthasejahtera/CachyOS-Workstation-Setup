#!/usr/bin/env bash
# Module 14: Nexus Command Center & Guide System
source "$(dirname "$0")/00-common.sh"
header "Nexus Command Center & Guide System"

# --- Nexus Command Center (popup command palette) ---
log "Installing Nexus Command Center..."
mkdir -p "$HOME/.local/bin"
# Copy nexus from repo or create inline
if [ -f "$(dirname "$0")/nexus.sh" ]; then
    cp "$(dirname "$0")/nexus.sh" "$HOME/.local/bin/nexus"
else
    # If running standalone, download from repo
    curl -fsSL -o "$HOME/.local/bin/nexus" \
        "https://raw.githubusercontent.com/rixzkiye/CachyOS-Workstation-Setup/main/nexus.sh" 2>/dev/null || true
fi
chmod +x "$HOME/.local/bin/nexus"
ok "Nexus installed (Super+X to open)"
log "  35+ quick actions: AI, screenshots, system, apps, dev tools"

log "Creating searchable guide..."
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/guide" << 'GUIDEEOF'
#!/bin/bash
# â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”
#  CachyOS Workstation Guide â€” type 'guide' or 'guide <keyword>'
# â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”â”

GUIDE_DATA="
[hyprland] Super+Return          â†’ Open Kitty terminal
[hyprland] Super+D                â†’ App launcher (Rofi)
[hyprland] Super+Q                â†’ Close window
[hyprland] Super+F                â†’ Fullscreen
[hyprland] Super+Space            â†’ Toggle floating
[hyprland] Super+1-9              â†’ Switch workspace
[hyprland] Super+Shift+1-9        â†’ Move window to workspace
[hyprland] Super+Arrow            â†’ Move focus
[hyprland] Super+Shift+Arrow      â†’ Move window
[hyprland] Super+L                â†’ Lock screen
[hyprland] Super+E                â†’ File manager (Thunar)
[hyprland] Super+V                â†’ Clipboard history
[hyprland] Super+/                â†’ Keybind cheatsheet
[hyprland] Super+Shift+S          â†’ Screenshot (region)
[hyprland] Print                  â†’ Screenshot (full)
[hyprland] Super+Mouse drag       â†’ Move/resize window

[terminal] kitty                  â†’ GPU-accelerated terminal
[terminal] tmux                   â†’ Terminal multiplexer
[terminal] tmux: Ctrl+A c         â†’ New window
[terminal] tmux: Ctrl+A n/p       â†’ Next/prev window
[terminal] tmux: Ctrl+A |         â†’ Split vertical
[terminal] tmux: Ctrl+A -         â†’ Split horizontal
[terminal] tmux: Ctrl+A Shift+I   â†’ Install plugins (first time)

[shell] z <dir>                   â†’ Smart cd (zoxide, learns your dirs)
[shell] Ctrl+R                    â†’ Search command history (fzf)
[shell] Tab                       â†’ Smart autocomplete (fzf-tab)
[shell] ls / ll / la              â†’ eza with icons + git status
[shell] cat <file>                â†’ bat (syntax-highlighted cat)
[shell] find <name>               â†’ fd (fast find replacement)
[shell] grep <pattern>            â†’ rg (ripgrep, 10x faster grep)
[shell] top                       â†’ btm (beautiful system monitor)
[shell] ff                        â†’ fastfetch (system info)
[shell] keys                      â†’ Hyprland keybinding cheatsheet

[git] git status                  â†’ Check changes
[git] git add . && git commit     â†’ Stage & commit
[git] git push                    â†’ Push to remote
[git] gh auth login               â†’ Authenticate GitHub CLI
[git] gh repo create              â†’ Create new repo
[git] gh pr create                â†’ Create pull request
[git] lazydocker                  â†’ Docker TUI manager

[docker] docker ps                â†’ List running containers
[docker] docker compose up -d     â†’ Start compose services
[docker] docker compose down      â†’ Stop compose services
[docker] lazydocker               â†’ Interactive Docker manager

[node] fnm use --lts              â†’ Switch to LTS Node
[node] pnpm install               â†’ Install dependencies
[node] pnpm run dev               â†’ Start dev server
[node] pnpm add <pkg>             â†’ Add package
[node] pnpm dlx <cmd>             â†’ Run npx-like command

[python] uv init                  â†’ Create new project
[python] uv add <pkg>             â†’ Add dependency
[python] uv run script.py         â†’ Run script
[python] uv venv                  â†’ Create virtual env

[rust] cargo new <name>           â†’ Create project
[rust] cargo build                â†’ Build
[rust] cargo run                  â†’ Run
[rust] cargo test                 â†’ Test

[go] go mod init <module>         â†’ Create module
[go] go run .                     â†’ Run
[go] go build                     â†’ Build

[flutter] flutter create <app>    â†’ New Flutter project
[flutter] flutter run             â†’ Run on device/emulator
[flutter] flutter build apk       â†’ Build APK
[flutter] flutter doctor          â†’ Check setup
[flutter] emulator -avd Pixel_7   â†’ Launch Android emulator
[flutter] scrcpy                  â†’ Mirror phone to screen
[flutter] adb devices             â†’ List connected devices

[kotlin] kotlinc file.kt -include-runtime -d app.jar â†’ Compile
[kotlin] java -jar app.jar        â†’ Run compiled
[kotlin] gradle build             â†’ Gradle build
[kotlin] ./gradlew assembleDebug  â†’ Build Android APK

[editor] antigravity              â†’ AI-powered editor (VS Code fork)
[editor] nvim <file>              â†’ Neovim with Catppuccin
[editor] nvim: Space              â†’ Leader key (which-key shows options)
[editor] nvim: Space+ff           â†’ Find files (Telescope)
[editor] nvim: Space+fg           â†’ Live grep (Telescope)
[editor] nvim: Space+e            â†’ File explorer (nvim-tree)

[ai] ollama run qwen3:30b-a3b    â†’ Best reasoning (debat, filosofi)
[ai] ollama run deepseek-r1:7b   â†’ Math & logic specialist
[ai] ollama run qwen2.5-coder:7b â†’ Coding assistant
[ai] ollama list                  â†’ Show downloaded models
[ai] ollama pull <model>          â†’ Download new model
[ai] ollama rm <model>            â†’ Remove model
[ai] antigravity                  â†’ Cloud AI coding agent

[gaming] steam                    â†’ Steam launcher
[gaming] gamemoderun <game>       â†’ Auto-boost CPU/GPU
[gaming] mangohud <game>          â†’ FPS overlay
[gaming] F12 (in game)            â†’ Toggle MangoHud overlay
[gaming] prismlauncher            â†’ Minecraft launcher
[gaming] pcsx2                    â†’ PS2 emulator

[vm] virt-manager                 â†’ VM manager GUI
[vm] virsh list --all              â†’ List all VMs
[vm] virsh start <vm>             â†’ Start VM
[vm] virsh shutdown <vm>          â†’ Stop VM
[vm] cat ~/VMs/README-vm-tips.txt â†’ VM performance tips
[vm] bash ~/VMs/download-windows-iso.sh â†’ Windows ISO links

[apps] bottles                    â†’ Run Windows apps without VM
[apps] libreoffice                â†’ Office suite
[apps] obsidian                   â†’ Markdown notes
[apps] keepassxc                  â†’ Password manager
[apps] obs-studio                 â†’ Screen recording + streaming
[apps] wf-recorder -f out.mp4    â†’ Quick screen record
[apps] scrcpy                     â†’ Mirror phone screen

[system] update                   â†’ Full system update (alias)
[system] cleanup                  â†’ Remove orphan packages (alias)
[system] timeshift                â†’ System backup/restore
[system] btm                      â†’ System monitor
[system] duf                      â†’ Disk usage
[system] dust <dir>               â†’ Directory size analyzer
[system] procs                    â†’ Better ps

[record] wf-recorder -f vid.mp4                â†’ Record full screen
[record] wf-recorder -g \"\$(slurp)\" -f clip.mp4 â†’ Record selected area
[record] obs-studio                             â†’ Full recording studio
[record] grim ~/Pictures/Screenshots/shot.png   â†’ Screenshot full
[record] grim -g \"\$(slurp)\" out.png            â†’ Screenshot region

[network] nmcli device wifi list  â†’ List WiFi networks
[network] nmcli device wifi connect <SSID> password <pw> â†’ Connect
[network] curl ifconfig.me        â†’ Show public IP
[network] ss -tulnp               â†’ Show open ports
"

C1='\033[38;2;203;166;247m'  # mauve
C2='\033[38;2;137;180;250m'  # blue
C3='\033[38;2;166;227;161m'  # green
NC='\033[0m'
BOLD='\033[1m'

if [ -z "$1" ]; then
    # No argument: interactive fzf search
    if command -v fzf &>/dev/null; then
        echo "$GUIDE_DATA" | grep -v '^$' | sed 's/^ *//' | \
            fzf --ansi --prompt="ðŸ” Search guide: " \
                --header="Type to search. Enter to copy. Esc to quit." \
                --color="bg:#1e1e2e,fg:#cdd6f4,hl:#f38ba8,bg+:#313244,fg+:#cdd6f4,hl+:#f38ba8,info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc,marker:#f5e0dc,spinner:#f5e0dc" \
                --border=rounded | wl-copy 2>/dev/null
    else
        echo "$GUIDE_DATA" | less
    fi
else
    # With argument: filter by keyword
    KEYWORD="$*"
    RESULTS=$(echo "$GUIDE_DATA" | grep -i "$KEYWORD" | sed 's/^ *//')
    if [ -z "$RESULTS" ]; then
        echo -e "${C1}No results for '${BOLD}$KEYWORD${NC}${C1}'. Try: guide docker, guide git, guide flutter${NC}"
    else
        echo -e "${C1}â”â”â” Guide: ${BOLD}$KEYWORD${NC} ${C1}â”â”â”${NC}"
        echo "$RESULTS" | while IFS= read -r line; do
            TAG=$(echo "$line" | grep -oP '^\[.*?\]')
            CMD=$(echo "$line" | sed 's/^\[.*\] //' | sed 's/ â†’.*//')
            DESC=$(echo "$line" | grep -oP 'â†’.*' || true)
            echo -e "  ${C2}$TAG${NC} ${BOLD}$CMD${NC} ${C3}$DESC${NC}"
        done
    fi
fi
GUIDEEOF
chmod +x "$HOME/.local/bin/guide"
ok "Guide system installed"
log "  Usage: guide              â†’ interactive search (fzf)"
log "  Usage: guide docker       â†’ search 'docker' entries"
log "  Usage: guide flutter      â†’ search 'flutter' entries"
log "  Usage: guide hyprland     â†’ search shortcuts"

