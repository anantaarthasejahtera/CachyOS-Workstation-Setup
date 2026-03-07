#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Dotfiles Cloud Sync (Git-based backup)
#  Safely backs up ~/.config to a private repo
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

CONFIG_DIR="$HOME/.config"
REMOTE_FILE="$CONFIG_DIR/.git-sync-remote"
IGNORE_FILE="$CONFIG_DIR/.gitignore"

cd "$CONFIG_DIR"

# 1. Initialize Git if not present
if [ ! -d ".git" ]; then
    git init -q
    rofi -e "Initialized local git repository in ~/.config"
fi

# 2. Setup robust .gitignore for ~/.config
cat > "$IGNORE_FILE" << 'IGNEOF'
# Ignore heavy application caches/state
Code/
google-chrome/
chromium/
discord/
Spotify/
1Password/
Slack/
obs-studio/
VSCodium/

# Ignore tokens and auth
gh/
op/
Nextcloud/
dconf/
gnupg/
**/credentials
**/token*
**/secret*
**/*.key
**/*.pem

# Temp files
*.log
.git-sync-remote
IGNEOF

# 3. Check / Set Remote URL
if [ ! -f "$REMOTE_FILE" ]; then
    remote=$(rofi -dmenu -i -p "☁️ Enter Private GitHub Repo URL (e.g., git@github.com:user/dotfiles.git)" -width 600)
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

# 4. Perform Backup
# We use kitty terminal to show progress since git push might require SSH auth/password
kitty --title "Cloud Sync Progress" -e bash -c "
echo -e '\033[1;36m☁️  Starting Dotfiles Cloud Sync...\033[0m'
cd \"$CONFIG_DIR\"

echo 'Adding files...'
git add . 

echo 'Committing...'
if git diff-index --quiet HEAD --; then
    echo 'No changes to backup.'
else
    git commit -m \"Auto-sync: \$(date +'%Y-%m-%d %H:%M:%S')\"
fi

echo 'Pushing to remote: $remote ...'
if git push -u origin \$(git branch --show-current); then
    echo -e '\n\033[1;32m✅ Sync Successful!\033[0m'
else
    echo -e '\n\033[1;31m❌ Sync Failed!\033[0m Check your SSH keys or network.'
fi

echo -e '\nPress Enter to close.'
read
"

# Notification
command -v notify-send >/dev/null && \
    notify-send -a "Cloud Sync" -i "folder-sync" \
    "Dotfiles Sync" "Backup process completed."
