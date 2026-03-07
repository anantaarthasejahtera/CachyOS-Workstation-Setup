#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Post-Install First-Boot Wizard
#  Guides new users through essential configuration via Rofi
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

WIZARD_DONE="$HOME/.config/cachy-setup/.wizard-done"

# Skip if already completed
if [ -f "$WIZARD_DONE" ]; then
    exit 0
fi

mkdir -p "$HOME/.config/cachy-setup"

# ─── Step 1: Welcome ────────────────────────────────────
rofi -e "🎉 Welcome to CachyOS Workstation!

Your system is ready. Let's set up a few things:

1. Git identity (name + email)
2. Choose default Ollama AI model
3. Pick a wallpaper
4. Optional: Cloud dotfiles backup

Press OK to begin."

# ─── Step 2: Git Identity ───────────────────────────────
current_name=$(git config --global user.name 2>/dev/null || echo "")
current_email=$(git config --global user.email 2>/dev/null || echo "")

if [ -z "$current_name" ] || [ "$current_name" = "Your Name" ]; then
    git_name=$(rofi -dmenu -p "👤 Your Full Name" -theme-str 'entry { placeholder: "e.g., John Doe"; }' -width 500)
    if [ -n "$git_name" ]; then
        git config --global user.name "$git_name"
    fi
fi

if [ -z "$current_email" ] || [ "$current_email" = "you@example.com" ]; then
    git_email=$(rofi -dmenu -p "📧 Your Git Email" -theme-str 'entry { placeholder: "e.g., john@example.com"; }' -width 500)
    if [ -n "$git_email" ]; then
        git config --global user.email "$git_email"
    fi
fi

# ─── Step 3: Default Ollama Model ────────────────────────
if command -v ollama &>/dev/null; then
    # Check which models are already downloaded
    local_models=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' || echo "")
    
    if [ -n "$local_models" ]; then
        model_list=""
        while IFS= read -r model; do
            [ -z "$model" ] && continue
            model_list+="$model\n"
        done <<< "$local_models"
        
        default_model=$(echo -e "$model_list" | rofi -dmenu -i -p "🧠 Default AI Model" -theme-str 'listview { lines: 5; }' -width 500)
        
        if [ -n "$default_model" ]; then
            mkdir -p "$HOME/.config/cachy-setup"
            echo "$default_model" > "$HOME/.config/cachy-setup/default-model"
            
            # Add convenience alias to .zshrc if not present
            if ! grep -q "alias ai=" "$HOME/.zshrc" 2>/dev/null; then
                echo "" >> "$HOME/.zshrc"
                echo "# Default AI model (set by post-install wizard)" >> "$HOME/.zshrc"
                echo "alias ai='ollama run $default_model'" >> "$HOME/.zshrc"
            fi
        fi
    fi
fi

# ─── Step 4: Wallpaper ──────────────────────────────────
wallpaper_dir="$HOME/Pictures/Wallpapers"
if [ -d "$wallpaper_dir" ] && [ "$(ls -1 "$wallpaper_dir" 2>/dev/null | wc -l)" -gt 0 ]; then
    selected_wp=$(ls -1 "$wallpaper_dir" | rofi -dmenu -i -p "🖼️ Choose Wallpaper" -width 500)
    if [ -n "$selected_wp" ] && [ -f "$wallpaper_dir/$selected_wp" ]; then
        # Set via hyprpaper or swaybg
        if command -v hyprctl &>/dev/null; then
            hyprctl hyprpaper preload "$wallpaper_dir/$selected_wp" 2>/dev/null || true
            hyprctl hyprpaper wallpaper ",$wallpaper_dir/$selected_wp" 2>/dev/null || true
        fi
    fi
else
    rofi -e "📁 No wallpapers found in ~/Pictures/Wallpapers/
Place your wallpaper images there and re-run this wizard."
fi

# ─── Step 5: Dotfiles Cloud Sync ────────────────────────
if command -v dotfiles-sync &>/dev/null; then
    setup_sync=$(echo -e "Yes, set up cloud backup\nSkip for now" | rofi -dmenu -i -p "☁️ Dotfiles Cloud Sync?" -width 500)
    if [[ "$setup_sync" == *"Yes"* ]]; then
        dotfiles-sync &
    fi
fi

# ─── Done ───────────────────────────────────────────────
touch "$WIZARD_DONE"

rofi -e "✅ Setup Complete!

Your workstation is personalized. Quick reminders:

  Super+X     → Nexus Command Center
  Super+D     → App Launcher
  Super+L     → Lock Screen
  guide       → 160+ searchable entries

Enjoy your CachyOS workstation! 🚀"
