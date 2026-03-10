#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Uninstall Wizard for CachyOS Workstation Setup
# GUI popup wizard using zenity
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

# Ensure zenity is available
if ! command -v zenity &>/dev/null; then
    echo "zenity not found. Installing..."
    sudo pacman -S --noconfirm --needed zenity 2>/dev/null || {
        echo "Failed to install zenity. Please install it manually."
        exit 1
    }
fi

# ── Step 1: Welcome & Warning ──
zenity --question \
    --title="🗑️ CachyOS Workstation — Uninstaller" \
    --width=520 --height=380 \
    --ok-label="Continue" \
    --cancel-label="Cancel" \
    --text='<big><b>🗑️ CachyOS Workstation Uninstaller</b></big>

This wizard will remove:

  <b>1.</b> Ecosystem scripts from /usr/local/bin/
  <b>2.</b> Nexus Command Center and Guide
  <b>3.</b> Rofi custom themes and app store configs
  <b>4.</b> System Health Check Pacman Hooks
  <b>5.</b> Internal state tracking (~/.config/cachy-setup)

<b>It will NOT:</b>
  • Uninstall packages (Docker, Steam, etc.)
  • Delete your personal files or dotfiles backups
  • Remove Ollama AI models you downloaded

<span foreground="red"><b>Are you sure you want to proceed?</b></span>' \
    2>/dev/null || exit 0

# ── Step 2: Choose what to remove ──
selections=$(zenity --list --checklist \
    --title="🗑️ Select Components to Remove" \
    --text="Uncheck items you want to keep:" \
    --column="" --column="ID" --column="Component" --column="Details" \
    --width=650 --height=400 \
    --separator=" " --print-column=2 \
    TRUE "ecosystem"  "Ecosystem Tools"        "/usr/local/bin/ scripts" \
    TRUE "hooks"      "Pacman Hooks"           "99-cachy-health.hook" \
    TRUE "rofi"       "Rofi UI Themes"         "Custom Rofi configs" \
    TRUE "state"      "State Tracking"         "\$HOME/.config/cachy-setup/" \
    TRUE "keybinds"   "Hyprland Keybinds"      "Nexus & Guide bindings" \
    2>/dev/null) || exit 0

if [ -z "$selections" ]; then
    zenity --info --title="Cancelled" \
        --text="Nothing selected. No changes made." \
        --width=300 2>/dev/null
    exit 0
fi

# ── Step 3: Run uninstall with progress ──
(
    total=5
    done=0

    # 1. Ecosystem Tools
    if echo "$selections" | grep -qw "ecosystem"; then
        echo "# [1/$total] Removing Ecosystem Tools & Executables..."
        ECO_TOOLS=("guide" "nexus" "theme-switch" "config-rollback" "dotfiles-sync" "ai-tuner" "app-store" "health-check" "post-install-wizard" "nexus-chat" "ai-power-fix")
        for tool in "${ECO_TOOLS[@]}"; do
            if [ -f "/usr/local/bin/$tool" ]; then
                sudo rm -f "/usr/local/bin/$tool"
            fi
        done
    fi
    done=$((done + 1))
    echo $(( done * 100 / total ))

    # 2. Pacman Hooks
    if echo "$selections" | grep -qw "hooks"; then
        echo "# [2/$total] Removing Health Check Pacman Hooks..."
        sudo rm -f /etc/pacman.d/hooks/99-cachy-health.hook 2>/dev/null || true
    fi
    done=$((done + 1))
    echo $(( done * 100 / total ))

    # 3. Rofi UI
    if echo "$selections" | grep -qw "rofi"; then
        echo "# [3/$total] Cleaning up Rofi UI Themes..."
        rm -rf "$HOME/.config/rofi/cachy-setup" 2>/dev/null || true
        rm -f "$HOME/.config/app-store-custom.conf" 2>/dev/null || true
    fi
    done=$((done + 1))
    echo $(( done * 100 / total ))

    # 4. State Tracking
    if echo "$selections" | grep -qw "state"; then
        echo "# [4/$total] Removing State Tracking..."
        rm -rf "$HOME/.config/cachy-setup" 2>/dev/null || true
    fi
    done=$((done + 1))
    echo $(( done * 100 / total ))

    # 5. Hyprland Keybinds
    if echo "$selections" | grep -qw "keybinds"; then
        echo "# [5/$total] Reverting Hyprland Keybinds..."
        HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
        if [ -f "$HYPR_CONF" ]; then
            # Remove Nexus keybind (matches both $mainMod and SUPER variants)
            sed -i '/exec.*nexus/d' "$HYPR_CONF"
            # Remove custom rofi keybind (with -show-icons added by installer)
            sed -i '/exec.*rofi -show drun -show-icons/d' "$HYPR_CONF"
            # Restore vanilla rofi drun keybind if no rofi drun bind exists
            if ! grep -q 'exec.*rofi.*-show drun' "$HYPR_CONF"; then
                echo 'bind = $mainMod, D, exec, rofi -show drun' >> "$HYPR_CONF"
            fi
        fi
    fi
    done=$((done + 1))
    echo $(( done * 100 / total ))

    echo "# ✅ Uninstallation complete!"
    sleep 1

) | zenity --progress \
    --title="🗑️ Uninstalling..." \
    --text="Preparing..." \
    --width=500 --height=120 \
    --auto-close --no-cancel \
    --percentage=0 2>/dev/null

# ── Step 4: Summary ──
zenity --info \
    --title="🎉 Uninstallation Complete" \
    --width=480 --height=280 \
    --text='<big><b>🎉 Uninstallation Complete!</b></big>

<b>To restore original configs:</b>
  1. Look inside <tt>~/.config-backup/</tt>
  2. Copy your original files back to <tt>~/.config/</tt>

<b>To see what was installed:</b>
  Check <tt>~/cachy-setup.log</tt>

Thank you for trying CachyOS Workstation Setup!' \
    2>/dev/null || true
