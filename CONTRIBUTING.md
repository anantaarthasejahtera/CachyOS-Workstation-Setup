# Contributing to CachyOS Workstation Setup

Thank you for your interest in contributing! This project is maintained by [PT Ananta Artha Sejahtera](https://anartha.com).

## 🚀 Quick Start

```bash
# 1. Fork and clone
git clone https://github.com/anantaarthasejahtera/CachyOS-Workstation-Setup.git
cd CachyOS-Workstation-Setup

# 2. Create a feature branch
git checkout -b feature/your-idea

# 3. Make your changes
# Edit any module in modules/

# 4. Test your changes
bash modules/<your-module>.sh

# 5. Commit and push
git commit -m "feat: add your awesome feature"
git push origin feature/your-idea

# 6. Open a Pull Request on GitHub
```

## 📁 Project Architecture

Each module is **independent** — you can edit one without touching others. All modules source `modules/00-common.sh` for shared helpers.

```
setup.sh → installer.sh (TUI) → modules/01-base.sh
                                → modules/02-kernel.sh
                                → modules/03-security.sh
                                → ...
                                → modules/15-ecosystem.sh
```

### Key Conventions

| Convention | Details |
|-----------|---------|
| **Idempotent** | Every module can be re-run safely without side effects |
| **`install_pkg`** | Use this helper (from `00-common.sh`) — it checks if already installed |
| **`install_aur`** | Same but for AUR packages via `paru` |
| **`safe_config`** | Auto-backups config before overwriting to `~/.config-backup/` |
| **`log` / `ok`** | Use these for consistent colored output |
| **Install path** | Ecosystem tools go to `/usr/local/bin/` (not `~/.local/bin/`) |
| **Line endings** | LF only (`.gitattributes` enforces this for `.sh` files) |

## 🧪 Testing

Before submitting a PR:

1. **Run your module** on a fresh CachyOS install or VM
2. **Run ShellCheck**: `shellcheck modules/your-module.sh`
3. **Verify idempotency**: Run the module twice — second run should have no side effects
4. **Check line endings**: Ensure LF (not CRLF) — `file modules/your-module.sh` should say "ASCII text"

## 📝 Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Use |
|--------|-----|
| `feat:` | New feature or module |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `refactor:` | Code restructuring (no behavior change) |
| `style:` | Formatting, whitespace |
| `chore:` | CI, build, tooling |

## 🌍 Guide Translations

The Guide v3 (`guide.sh`) is bilingual (EN/ID). When adding guide entries:

```bash
add "category" "command" \
    "English description" "Indonesian description" \
    "English detail line 1|Detail line 2" "Indonesian detail 1|Detail 2" \
    "executable_command" "check_binary"
```

Both languages are required for every entry.

## 🐛 Reporting Issues

- **Bug reports**: Include your `fastfetch` output and `~/cachy-setup.log`
- **Feature requests**: Describe the use case, not just the solution
- **Hardware issues**: Include `lspci | grep -i vga` output

## 📄 License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
