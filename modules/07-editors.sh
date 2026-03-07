#!/usr/bin/env bash
# Module 07: Editors (Antigravity, Neovim)
source "$(dirname "$0")/00-common.sh"
header "Antigravity â€” AI Coding Agent"

# CachyOS is Arch-based, no deb/rpm. Install from source tarball.
log "Installing Antigravity from source tarball..."
AG_TMP="/tmp/antigravity-install"
mkdir -p "$AG_TMP"

# Download latest source tarball
AG_TARBALL_URL="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-debian/pool/antigravity_latest.tar.gz"
if curl -fsSL -o "$AG_TMP/antigravity.tar.gz" "$AG_TARBALL_URL" 2>/dev/null; then
    cd "$AG_TMP"
    tar xzf antigravity.tar.gz 2>/dev/null || true
    # Try to find and install the binary
    if [ -f "$AG_TMP/usr/bin/antigravity" ]; then
        sudo cp "$AG_TMP/usr/bin/antigravity" /usr/local/bin/
        sudo chmod +x /usr/local/bin/antigravity
        ok "Antigravity installed from tarball"
    elif [ -f "$AG_TMP/antigravity" ]; then
        sudo cp "$AG_TMP/antigravity" /usr/local/bin/
        sudo chmod +x /usr/local/bin/antigravity
        ok "Antigravity installed from tarball"
    else
        warn "Antigravity tarball structure unknown. Trying npm..."
        npm install -g @anthropic-ai/claude-code 2>/dev/null || \
        npm install -g @anthropic/antigravity 2>/dev/null || \
        warn "Antigravity needs manual install. Download from: https://developers.google.com/gemini"
    fi
else
    warn "Could not download Antigravity tarball. Trying alternative..."
    # Attempt AUR (community might have it)
    install_aur antigravity-bin 2>/dev/null || \
    warn "Antigravity needs manual install after reboot. Check official site."
fi
rm -rf "$AG_TMP"
cd ~

ok "Antigravity module done"

# --- Ollama (Local AI / LLM) ---
log "Installing Ollama (run AI models locally)..."
curl -fsSL https://ollama.com/install.sh | sh 2>/dev/null || install_aur ollama-bin 2>/dev/null || true
# Pull a lightweight model suitable for 16GB RAM
if command -v ollama &>/dev/null; then
    sudo systemctl enable --now ollama.service 2>/dev/null || true
    # Pull 3 optimal models for 16GB RAM in background
    log "Pulling AI models in background (this may take a while)..."
    log "  1. qwen3:30b-a3b   â†’ MoE reasoning beast (debat, strategi, filosofi)"
    log "  2. deepseek-r1:7b  â†’ Reasoning & math specialist"
    log "  3. qwen2.5-coder:7b â†’ Coding specialist (setara GPT-4o)"
    (
        ollama pull qwen2.5-coder:7b 2>/dev/null
        ollama pull deepseek-r1:7b 2>/dev/null
        ollama pull qwen3:30b-a3b 2>/dev/null
    ) &
    ok "Ollama installed (3 models downloading in background)"
    log "  Quick start: ollama run qwen3:30b-a3b"
else
    warn "Ollama install failed. Try manually: curl -fsSL https://ollama.com/install.sh | sh"
fi

