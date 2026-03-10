#!/usr/bin/env bash
# — Nexus AI Chat — Advanced Assistant —
# Features: Model Selection, Terminal Access, Debate Mode

set -euo pipefail

# --- 1. Model Selection ---
# Check if Ollama is running
if ! pgrep -x "ollama" > /dev/null; then
    notify-send "Nexus AI" "Starting Ollama service..."
    ollama serve &>/dev/null &
    sleep 2
fi

# Get list of local models
MODELS=$(ollama list | tail -n +2 | awk '{print $1}')

if [ -z "$MODELS" ]; then
    rofi -e "No Ollama models found. Please download one first (e.g., ollama pull deepseek-r1:7b)"
    exit 1
fi

# Rofi Selection
CHOSEN_MODEL=$(echo "$MODELS" | rofi -dmenu -i -p "󰧑 AI Model" -config ~/.config/rofi/config.rasi)
[ -z "$CHOSEN_MODEL" ] && exit 0

# --- 2. Mode Selection ---
CHOICES="💬 Normal Chat\n⚖️ Debate Mode\n💻 Nexus Link (Terminal Access)"
MODE=$(echo -e "$CHOICES" | rofi -dmenu -i -p "⚙️ Mode" -config ~/.config/rofi/config.rasi)
[ -z "$MODE" ] && exit 0

# --- 3. System Prompt Construction ---
SYSTEM_PROMPT="You are a capable AI running on CachyOS (Advan WorkPro). "

if [[ "$MODE" == *"Debate"* ]]; then
    SYSTEM_PROMPT+="Style: Critical and logical. Debate facts with the user in Indonesian."
elif [[ "$MODE" == *"Terminal"* ]]; then
    SYSTEM_PROMPT+="Mode: Terminal Access. Suggest CLI commands when needed. Be technical."
else
    SYSTEM_PROMPT+="Style: Helpful and friendly assistant. Use Indonesian."
fi

# --- 4. Launch Terminal UI ---
CHAT_WRAPPER=$(mktemp /tmp/nexus-chat-session.XXXXXX.sh)
MODEL_FILE=$(mktemp /tmp/nexus-chat-modelfile.XXXXXX)
POWER_FIX="/usr/local/bin/ai-power-fix"

# Create temporary Modelfile for personality
cat > "$MODEL_FILE" << EOF
FROM $CHOSEN_MODEL
SYSTEM "$SYSTEM_PROMPT"
PARAMETER num_ctx 4096
PARAMETER temperature 0.7
PARAMETER num_thread 4
EOF

cat > "$CHAT_WRAPPER" << EOF
#!/usr/bin/env bash
# Cleanup trap: ensure temp model is removed and power mode is restored
cleanup() {
    ollama rm "nexus-temp" > /dev/null 2>&1 || true
    if [ -f "$POWER_FIX" ]; then $POWER_FIX off 2>/dev/null || true; fi
}
trap cleanup EXIT INT TERM

# Enable Turbo Mode
if [ -f "$POWER_FIX" ]; then $POWER_FIX on; fi

echo -e "\033[1;35m━━━ 󰧑 Nexus AI Chat : $CHOSEN_MODEL ━━━\033[0m"
echo -e "\033[1;34mMode: $MODE\033[0m"
echo -e "\033[1;30m(Press Ctrl+D to quit)\033[0m"
echo ""

# Create a temporary model with the personality
ollama create "nexus-temp" -f "$MODEL_FILE" > /dev/null
ollama run "nexus-temp"

# Cleanup is handled by the trap above
EOF

chmod +x "$CHAT_WRAPPER"

# Launch in Kitty with glassmorphism
if command -v kitty >/dev/null; then
    kitty --title "Nexus AI Chat" \
          --override background_opacity=0.85 \
          -e "$CHAT_WRAPPER"
else
    # Fallback to standard terminal if kitty missing
    x-terminal-emulator -e "$CHAT_WRAPPER" || bash "$CHAT_WRAPPER"
fi
