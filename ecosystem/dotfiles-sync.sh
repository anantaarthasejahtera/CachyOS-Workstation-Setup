#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Dotfiles Cloud Sync (Git-based backup)
#  Safely backs up ~/.config to a private repo
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

CONFIG_DIR="$HOME/.config"
REMOTE_FILE="$CONFIG_DIR/.git-sync-remote"
IGNORE_FILE="$CONFIG_DIR/.gitignore"

# ─── Safety Check ─────────────────────────────────────────
# Check if ~/.config already has a git repo for a different purpose
if [ -d "$CONFIG_DIR/.git" ]; then
    existing_remote=$(cd "$CONFIG_DIR" && git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$existing_remote" ] && [ -f "$REMOTE_FILE" ]; then
        saved_remote=$(cat "$REMOTE_FILE")
        if [ "$existing_remote" != "$saved_remote" ]; then
            rofi -e "⚠️ ~/.config already has a Git repo pointing to:
$existing_remote

But your saved remote is:
$saved_remote

Please resolve this conflict manually."
            exit 1
        fi
    fi
fi

cd "$CONFIG_DIR"

# 1. Initialize Git if not present
if [ ! -d ".git" ]; then
    # Confirm with user before initializing
    confirm=$(echo -e "Yes, initialize\nCancel" | rofi -dmenu -i -p "📁 Initialize Git in ~/.config?")
    if [[ "$confirm" != *"Yes"* ]]; then
        rofi -e "Sync cancelled."
        exit 0
    fi
    git init -q
    rofi -e "✅ Initialized local git repository in ~/.config"
fi

# 2. Setup robust .gitignore for ~/.config
cat > "$IGNORE_FILE" << 'IGNEOF'
# ═══ Heavy application caches/state ═══
Code/
Code - OSS/
VSCodium/
google-chrome/
chromium/
BraveSoftware/
microsoft-edge/

# ═══ Chat/Social/Media apps ═══
discord/
Spotify/
Signal/
Slack/
telegram-desktop/
Element/

# ═══ Security-critical (NEVER sync) ═══
gh/
op/
1Password/
gnupg/
ssh/
Nextcloud/
dconf/
keyring/
kwalletd/
**/credentials
**/token*
**/secret*
**/cookie*
**/*.key
**/*.pem
**/*.p12
**/*.pfx

# ═══ Large/dynamic state ═══
obs-studio/
PCSX2/
MangoHud/
lutris/
heroic/
Steam/
bottles/
flatpak/
mimeapps.list

# ═══ Cache directories ═══
**/cache/
**/Cache/
**/CachedData/
**/.cache/
**/blob_storage/
**/GPUCache/
**/ShaderCache/
**/Service Worker/

# ═══ Temp/runtime files ═══
*.log
*.tmp
*.bak
.git-sync-remote
*.lock
pulse/
pipewire/
IGNEOF

# 3. Check / Set Remote URL
if [ ! -f "$REMOTE_FILE" ]; then
    remote=$(rofi -dmenu -i -p "☁️ Private GitHub Repo URL" \
        -theme-str 'entry { placeholder: "git@github.com:user/dotfiles-config.git"; }' -width 600)
    if [ -n "$remote" ]; then
        echo "$remote" > "$REMOTE_FILE"
        git remote add origin "$remote" 2>/dev/null || git remote set-url origin "$remote"
    else
        rofi -e "Sync Cancelled: No remote URL provided."
        exit 1
    fi
else
    remote=$(cat "$REMOTE_FILE")
    git remote add origin "$remote" 2>/dev/null || true
fi

# 4. Show repo size estimate before pushing
repo_size=$(du -sh "$CONFIG_DIR" --exclude='.git' 2>/dev/null | cut -f1)
tracked_estimate=$(git ls-files --others --exclude-standard 2>/dev/null | head -500 | wc -l)

# 5. Perform Backup
# We use kitty terminal to show progress since git push might require SSH auth
kitty --title "Cloud Sync Progress" -e bash -c "
echo -e '\033[1;36m☁️  Dotfiles Cloud Sync\033[0m'
echo -e '\033[0;90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m'
echo ''
echo -e '  📁 Config dir size: \033[1m$repo_size\033[0m (before .gitignore)'
echo -e '  📦 New/untracked files: \033[1m~$tracked_estimate\033[0m'
echo ''
cd \"$CONFIG_DIR\"

echo -e '\033[1;33m[1/3]\033[0m Adding files...'
git add .

echo -e '\033[1;33m[2/3]\033[0m Committing...'
if git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e '  \033[0;90mNo changes to backup.\033[0m'
else
    git commit -m \"Auto-sync: \$(date +'%Y-%m-%d %H:%M:%S')\"
fi

echo -e '\033[1;33m[3/3]\033[0m Pushing to remote: $remote ...'
if git push -u origin \$(git branch --show-current) 2>&1; then
    echo -e '\n\033[1;32m✅ Sync Successful!\033[0m'
else
    echo -e '\n\033[1;31m❌ Sync Failed!\033[0m'
    echo ''
    echo 'Common fixes:'
    echo '  1. Check SSH keys: ssh -T git@github.com'
    echo '  2. Check network: ping github.com'
    echo '  3. Ensure repo exists and is private'
fi

echo -e '\nPress Enter to close.'
read
"

# Notification
command -v notify-send >/dev/null && \
    notify-send -a "Cloud Sync" -i "folder-sync" \
    "Dotfiles Sync" "Backup process completed."
