# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Build Commands
- `make build` - Output binary is `./nexus` (NOT the project name)
- `make install` - Builds and installs to /usr/local/bin/nexus with sudo
- `make dev` - Build + run ./nexus doctor
- `make test` - go test -v -race ./...
- `make lint` - go vet ./...
- `make init` - Setup git hooks (.githooks → .git/hooks)
- `VERSION=x.x.x make build` - Inject version via ldflags

## Critical Coding Rules

### Config Writes - MUST use state.SafeWriteConfig()
Location: internal/state/state.go:73
- Automatically backs up to ~/.config-backup/YYYYMMDD-HHMMSS/ before overwrite
- NEVER use os.WriteFile() for config - lose backup protection

### Pacman Logger - MANDATORY Reset
Location: internal/pacman/pacman.go
- Use `pacman.SetLogger(w)` to redirect output
- MUST call `pacman.ResetLogger()` in defer block after wizard close
- Forgetting ResetLogger() causes crash when writing to closed writer

### Sudo Pattern - Use CheckAndPromptSudo First
Location: internal/pacman/pacman.go:16
- ALWAYS call pacman.CheckAndPromptSudo() before pacman.Install()
- Uses zenity GUI if display active, fallback to terminal

### Idempotent Modifications - Check Before Modify
Location: internal/modules/base.go:72
- Always check if modification already exists: `if !strings.Contains(content, "target")`
- Never overwrite existing configs blindly

### Config Content - Trim and Add Newline
```go
state.SafeWriteConfig(path, []byte(strings.TrimSpace(content)+"\n"), 0644)
```

### Error Handling - Aggregate Pattern
- Collect errors in slice, return single error at end
- Module functions return error, caller handles exit code
- NEVER call os.Exit() in module functions

### Dotfiles as Const Strings
Location: internal/modules/desktop.go:175
- All dotfile configs (kitty, hyprland, waybar) are hardcoded as string const
- No external file dependencies - keeps binary self-contained

## Architecture

```
main.go → cmd.Execute() → root.go (Cobra)
  └── No args → ShowMenu() (Rofi GUI)
  └── With args → run subcommand

Key directories:
- internal/cmd/    - Cobra commands (install, wizard, doctor, etc.)
- internal/modules/ - Pure installation logic (base, desktop, dev, etc.)
- internal/state/  - State management + config backup
- internal/pacman/  - Package manager abstraction
```

### Wizard Pattern - io.Writer Implementation
Location: internal/cmd/wizard.go
- Thread-safe with sync.Mutex
- sync.Once prevents double-close panic
- Dual-write to file + terminal with emoji detection

### State Management
Location: internal/state/state.go:18
- File: ~/.local/share/nexus/state.json
- Always nil-safe check: `if cfg.PackagesInstalled == nil`

## Dependencies

### Go Packages
github.com/pterm/pterm (TUI/spinners), github.com/spf13/cobra (CLI)

### System Dependencies
- yay (AUR helper) - auto-installed by base.go if missing
- snapper (optional) - for BTRFS snapshots
- zenity (optional) - for GUI sudo prompt