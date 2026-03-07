# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| `main` branch | ✅ Active |
| Older commits | ❌ Not supported |

This is a rolling release project — always use the latest `main` branch.

## Reporting a Vulnerability

If you discover a security vulnerability, **please do NOT open a public issue**.

Instead, report it privately:

1. **Email**: [security@anartha.com](mailto:security@anartha.com)
2. **Subject**: `[SECURITY] CachyOS-Workstation-Setup: <brief description>`

### What to include

- Description of the vulnerability
- Steps to reproduce
- Affected module(s) and line numbers
- Potential impact
- Suggested fix (if any)

### Response timeline

| Action | Timeline |
|--------|----------|
| Acknowledgment | Within 48 hours |
| Assessment | Within 1 week |
| Fix release | Within 2 weeks (critical), 1 month (moderate) |

## Security Considerations

### What this project does

- Installs packages via `pacman` and `paru` (AUR)
- Modifies user-space configs (`~/.config/`)
- Sets up system services (UFW, Docker, libvirtd)
- Installs ecosystem tools to `/usr/local/bin/`
- Creates a pacman hook in `/etc/pacman.d/hooks/`

### What this project does NOT do

- **No telemetry** — nothing phones home
- **No credentials stored** — API keys, passwords are never saved
- **No partition modifications** — except GRUB theme (cosmetic only)
- **No network listeners** — except standard services (SSH, UFW)

### curl | bash disclaimer

The one-liner installer (`install.sh`) downloads and executes a script. We always recommend:

```bash
# Inspect first, then run
curl -fsSL https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/install.sh -o install.sh
less install.sh
bash install.sh
```

### AI models

All AI models (Ollama) run **100% locally**. No data leaves your machine. No API keys required.
