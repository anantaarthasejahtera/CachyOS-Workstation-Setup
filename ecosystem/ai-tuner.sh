#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  AI Auto-Tuner Daemon
#  Analyzes system state & asks local Ollama for tuning tips
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

MODEL="qwen2.5-coder:7b"

# Check if ollama binary exists at all
if ! command -v ollama &>/dev/null; then
    rofi -e "❌ Ollama is not installed. Install it via Module 07 (Editors)."
    exit 1
fi

# Check if ollama is running
if ! systemctl is-active --quiet ollama >/dev/null 2>&1 && ! curl -s http://localhost:11434 >/dev/null 2>&1; then
    rofi -e "❌ Ollama is not running. Start it: sudo systemctl start ollama"
    exit 1
fi

# Check if the model is available
if ! ollama list 2>/dev/null | grep -q "$MODEL"; then
    rofi -e "⚠️ Model '$MODEL' not found. Pulling it now... Run 'ollama pull $MODEL' first."
    exit 1
fi

# Show loading notification (only after all checks pass)
notify-send -a "AI Tuner" -i "dialog-information" "Gathering System State..." "This might take a few seconds."

# 1. Gather Telemetry
top_stats=$(top -b -n 1 | head -n 15)
mem_stats=$(free -h)
io_stats=$(vmstat 1 2 | tail -1)

# 2. Construct Prompt
prompt="You are an elite Arch Linux kernel engineer. Analyze this current system state and give exactly 3 concise, actionable performance tweaks (like sysctl commands or things to close). Be extremely brief and direct. Do not use markdown code blocks, just plain text.
System State:
=== TOP ===
$top_stats
=== MEMORY ===
$mem_stats
=== IO ===
$io_stats
"

# 3. Query Local AI (safe: don't crash on failure)
response=$(ollama run "$MODEL" "$prompt" 2>/dev/null || echo "")

# 4. Display result
if [ -z "$response" ]; then
    rofi -e "Failed to get response from $MODEL"
else
    # Show in a nicely formatted rofi popup
    rofi -e "🧠 AI Performance Audit ($MODEL)
─────────────────────────────────────
$response"
fi
