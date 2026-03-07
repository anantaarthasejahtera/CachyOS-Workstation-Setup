#!/usr/bin/env bash
# Module 07: Editors (Antigravity, Neovim, VS Code Catppuccin)
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
header "Editors — Antigravity, Neovim, VS Code Config"

# ─── Antigravity (AI Coding Agent) ───────────────────────
log "Installing Antigravity from source tarball..."
AG_TMP="/tmp/antigravity-install"
mkdir -p "$AG_TMP"

AG_TARBALL_URL="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-debian/pool/antigravity_latest.tar.gz"
if curl -fsSL -o "$AG_TMP/antigravity.tar.gz" "$AG_TARBALL_URL" 2>/dev/null; then
    cd "$AG_TMP"
    tar xzf antigravity.tar.gz 2>/dev/null || true
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
        warn "Antigravity needs manual install. Check: https://docs.anthropic.com/claude-code"
    fi
else
    warn "Could not download Antigravity tarball. Trying alternative..."
    install_aur antigravity-bin 2>/dev/null || \
    warn "Antigravity needs manual install after reboot. Check official site."
fi
rm -rf "$AG_TMP"
cd ~

ok "Antigravity module done"

# ─── VS Code / Antigravity Catppuccin Settings ───────────
log "Configuring editor aesthetic (Catppuccin Mocha)..."
VSCODE_DIR="$HOME/.config/Code/User"
mkdir -p "$VSCODE_DIR"
cat > "$VSCODE_DIR/settings.json" << 'VSCEOF'
{
    "workbench.colorTheme": "Catppuccin Mocha",
    "workbench.iconTheme": "catppuccin-mocha",
    "workbench.productIconTheme": "catppuccin-mocha",
    "editor.fontFamily": "'JetBrainsMono Nerd Font', 'JetBrains Mono', monospace",
    "editor.fontSize": 14,
    "editor.fontLigatures": true,
    "editor.lineHeight": 1.6,
    "editor.cursorBlinking": "smooth",
    "editor.cursorSmoothCaretAnimation": "on",
    "editor.smoothScrolling": true,
    "editor.minimap.enabled": false,
    "editor.renderWhitespace": "boundary",
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": true,
    "editor.stickyScroll.enabled": true,
    "terminal.integrated.fontFamily": "'JetBrainsMono Nerd Font'",
    "terminal.integrated.fontSize": 13,
    "terminal.integrated.cursorStyle": "line",
    "terminal.integrated.defaultProfile.linux": "zsh",
    "window.titleBarStyle": "custom",
    "window.menuBarVisibility": "toggle",
    "workbench.list.smoothScrolling": true,
    "workbench.tree.indent": 16,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000
}
VSCEOF

# Recommend Catppuccin extensions
cat > "$VSCODE_DIR/extensions.json" << 'VSCEXTEOF'
{
    "recommendations": [
        "catppuccin.catppuccin-vsc",
        "catppuccin.catppuccin-vsc-icons",
        "catppuccin.catppuccin-vsc-pack"
    ]
}
VSCEXTEOF
ok "VS Code Catppuccin configured"

# ─── Neovim + Catppuccin (lazy.nvim) ────────────────────
log "Configuring Neovim with Catppuccin..."
install_pkg neovim
NVIM_DIR="$HOME/.config/nvim"
mkdir -p "$NVIM_DIR/lua/plugins"

cat > "$NVIM_DIR/init.lua" << 'NVIMINIT'
-- — Neovim — Catppuccin Mocha —
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({ "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- Catppuccin colorscheme
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
                transparent_background = true,
                integrations = {
                    treesitter = true,
                    telescope = { enabled = true },
                    which_key = true,
                    indent_blankline = { enabled = true },
                    mini = { enabled = true },
                },
            })
            vim.cmd.colorscheme("catppuccin")
        end,
    },
    -- File explorer
    { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" },
      config = function() require("nvim-tree").setup() end },
    -- Fuzzy finder
    { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    -- Statusline
    { "nvim-lualine/lualine.nvim", config = function()
        require("lualine").setup({ options = { theme = "catppuccin" } })
    end },
    -- Treesitter
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    -- Which-key (keybinding helper)
    { "folke/which-key.nvim", config = function() require("which-key").setup() end },
    -- Indent guides
    { "lukas-reineke/indent-blankline.nvim", main = "ibl",
      config = function() require("ibl").setup() end },
    -- Auto pairs
    { "windwp/nvim-autopairs", config = function() require("nvim-autopairs").setup() end },
    -- Git signs
    { "lewis6991/gitsigns.nvim", config = function() require("gitsigns").setup() end },
})
NVIMINIT
ok "Neovim + lazy.nvim + Catppuccin configured"

# ─── Ollama (Local AI / LLM) ────────────────────────────
log "Installing Ollama (run AI models locally)..."
curl -fsSL https://ollama.com/install.sh | sh 2>/dev/null || install_aur ollama-bin 2>/dev/null || true
if command -v ollama &>/dev/null; then
    sudo systemctl enable --now ollama.service 2>/dev/null || true
    # Pull 3 optimal models for 16GB RAM in background
    log "Pulling AI models in background (this may take a while)..."
    log "  1. qwen3:30b-a3b   → MoE reasoning beast (debat, strategi, filosofi)"
    log "  2. deepseek-r1:7b  → Reasoning & math specialist"
    log "  3. qwen2.5-coder:7b → Coding specialist (setara GPT-4o)"
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

ok "Editors module complete"
