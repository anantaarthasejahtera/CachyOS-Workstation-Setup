#!/usr/bin/env bash
# Module 07: Editors (Antigravity, Neovim, VS Code Catppuccin)
source "$(dirname "$0")/00-common.sh"
set -euo pipefail
skip_if_current
header "Editors — Antigravity, Neovim, VS Code Config"

# ─── Antigravity (AI Coding Agent) ───────────────────────
# Antigravity is distributed via Debian/RPM repos at antigravity.google
# On Arch, we try AUR first, then extract from .deb, then offer cursor-bin as alternative
log "Installing Antigravity..."

if command -v antigravity &>/dev/null; then
    ok "Antigravity already installed"
elif install_aur antigravity-bin 2>/dev/null; then
    ok "Antigravity installed from AUR"
else
    # Try extracting from official tar.gz package
    AG_TMP="/tmp/antigravity-install"
    mkdir -p "$AG_TMP"
    AG_URL="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/1.20.4-5535391095848960/linux-x64/Antigravity.tar.gz"
    if curl -fsSL -o "$AG_TMP/antigravity.tar.gz" "$AG_URL" 2>/dev/null; then
        (
            cd "$AG_TMP"
            tar xf antigravity.tar.gz 2>/dev/null || true
        )
        if [ -d "$AG_TMP/Antigravity" ]; then
            sudo rm -rf /opt/Antigravity
            sudo mv "$AG_TMP/Antigravity" /opt/
            [ -f /opt/Antigravity/antigravity ] && sudo ln -sf /opt/Antigravity/antigravity /usr/local/bin/antigravity
            [ -f /opt/Antigravity/Antigravity ] && sudo ln -sf /opt/Antigravity/Antigravity /usr/local/bin/antigravity
            ok "Antigravity installed from official .tar.gz extract"
        elif [ -f "$AG_TMP/usr/bin/antigravity" ]; then
            sudo cp "$AG_TMP/usr/bin/antigravity" /usr/local/bin/
            sudo chmod +x /usr/local/bin/antigravity
            ok "Antigravity installed from official tarball extract"
        else
            warn "Antigravity structure unknown. Trying cursor-bin as alternative..."
            install_aur cursor-bin 2>/dev/null || \
            warn "Antigravity/Cursor install failed. Visit: https://antigravity.google for manual install"
        fi
        rm -rf "$AG_TMP"
    else
        warn "Could not download Antigravity. Trying cursor-bin as alternative..."
        install_aur cursor-bin 2>/dev/null || \
        warn "No AI editor installed. Visit https://antigravity.google or https://cursor.sh"
    fi
fi

ok "AI editor module done"

# ─── VS Code / Antigravity Catppuccin Settings ───────────
log "Configuring editor aesthetic (Catppuccin Mocha)..."
VSCODE_DIR="$HOME/.config/Code/User"
mkdir -p "$VSCODE_DIR"
safe_config "$VSCODE_DIR/settings.json"
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
safe_config "$NVIM_DIR/init.lua"

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

# CachyOS Optimization: Check for x86-64-v4 (AVX-512) support
if grep -q "avx512" /proc/cpuinfo && pacman -Sg cachyos-v4 &>/dev/null; then
    log "  Detected AVX-512 support. Using CachyOS-v4 optimized Ollama..."
    install_pkg ollama-vulkan # Often uses GPU/iGPU if available, or fallbacks to v4 CPU
else
    if command -v ollama &>/dev/null; then
        ok "Ollama already installed, skipping download."
    else
        curl -fsSL https://ollama.com/install.sh | sh 2>/dev/null || install_aur ollama-bin 2>/dev/null || true
    fi
fi

if command -v ollama &>/dev/null; then
    sudo systemctl enable --now ollama.service 2>/dev/null || true
    ok "Ollama installed and running"
    log "  Pull models on-demand (not auto-downloaded to save bandwidth):"
    log "    ollama pull qwen2.5-coder:7b    # coding assistant (~4 GB)"
    log "    ollama pull deepseek-r1:7b       # reasoning (~4 GB)"
    log "    ollama pull qwen3:30b-a3b        # general purpose (~17 GB)"
    log "  Quick start: ollama run qwen2.5-coder:7b"
else
    warn "Ollama install failed. Try manually: curl -fsSL https://ollama.com/install.sh | sh"
fi

ok "Editors module complete"
mark_module_done
