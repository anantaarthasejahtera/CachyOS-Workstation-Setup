#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Time Machine Config Rollback System
#  Restores configurations backed up by safe_config()
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

BACKUP_ROOT="$HOME/.config-backup"

# 1. Select timestamp
if [ ! -d "$BACKUP_ROOT" ]; then
    rofi -e "No backups found in $BACKUP_ROOT"
    exit 1
fi

timestamp=$(ls -1r "$BACKUP_ROOT" | rofi -dmenu -i -p "🕰️ Select Backup Timestamp")
[ -z "$timestamp" ] && exit 0

BACKUP_DIR="$BACKUP_ROOT/$timestamp"

# 2. Select file to restore
declare -A FILE_MAP
entries=""
for f in "$BACKUP_DIR"/*; do
    [ ! -f "$f" ] && continue
    bname=$(basename "$f")
    # Replace __ with / to get actual path
    actual_path="${bname//__//}"
    # Replace $HOME prefix with ~ for cleaner display (use parameter expansion)
    display_path="${actual_path/#$HOME/~}"
    
    FILE_MAP["$display_path"]="$actual_path"
    entries+="$display_path\n"
done

if [ -z "$entries" ]; then
    rofi -e "No files in backup $timestamp"
    exit 1
fi

entries="[Restore ALL files from $timestamp]\n$entries"

chosen_file=$(echo -e "$entries" | rofi -dmenu -i -p "📄 File to Restore" -width 800)
[ -z "$chosen_file" ] && exit 0

if [[ "$chosen_file" == *"Restore ALL"* ]]; then
    # Confirmation
    ans=$(echo -e "Yes\nNo" | rofi -dmenu -i -p "⚠️ Restore ALL files? Current configs will be overwritten!")
    [ "$ans" != "Yes" ] && exit 0
    
    count=0
    for display_path in "${!FILE_MAP[@]}"; do
        actual_path="${FILE_MAP[$display_path]}"
        # Expand ~ to $HOME for file operations
        actual_path="${actual_path/#\~/$HOME}"
        bname=$(echo "$actual_path" | sed "s|/|__|g")
        mkdir -p "$(dirname "$actual_path")"
        cp "$BACKUP_DIR/$bname" "$actual_path"
        count=$((count+1))
    done
    rofi -e "✅ $count files restored from $timestamp!"
else
    # Restore single file
    actual_path="${FILE_MAP[$chosen_file]}"
    # Expand ~ to $HOME for file operations
    actual_path="${actual_path/#\~/$HOME}"
    bname=$(echo "$actual_path" | sed "s|/|__|g")

    # Show diff preview before restoring (if current file exists and diff is available)
    if [ -f "$actual_path" ] && command -v diff &>/dev/null; then
        diff_output=$(diff --color=never -u "$actual_path" "$BACKUP_DIR/$bname" 2>/dev/null | head -40 || true)
        if [ -n "$diff_output" ]; then
            preview="Changes that will be applied:\n\n$diff_output"
            [ "$(echo "$diff_output" | wc -l)" -ge 40 ] && preview+="\n... (truncated)"
            confirm=$(echo -e "Yes, restore\nCancel" | rofi -dmenu -i -p "📋 Preview diff for $chosen_file" -mesg "$preview" -width 800)
            [[ "$confirm" != *"Yes"* ]] && exit 0
        fi
    fi

    mkdir -p "$(dirname "$actual_path")"
    cp "$BACKUP_DIR/$bname" "$actual_path"
    rofi -e "✅ Restored $chosen_file"
fi

# Soft reload common services just in case
killall -SIGUSR2 waybar 2>/dev/null || true
hyprctl reload 2>/dev/null || true
