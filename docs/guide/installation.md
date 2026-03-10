# 📦 Installation

Installing the CachyOS Workstation Setup is designed to be frictionless and hardware-aware.

### ⚡ One-Liner Install (Recommended)

To bootstrap your system immediately, run this command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/anantaarthasejahtera/CachyOS-Workstation-Setup/main/install.sh | bash
```

This will:
1. Install base dependencies (like `git` and `zenity`).
2. Clone the repository into `~/.cache/cachy-workstation-setup`.
3. Prompt you for your Git identity (Name & Email).
4. Launch the **Bilingual GUI Installer** (zenity-based).

### 🔧 Manual Install

If you prefer to inspect the repository beforehand:

```bash
# Clone the repository
git clone https://github.com/anantaarthasejahtera/CachyOS-Workstation-Setup.git
cd CachyOS-Workstation-Setup

# (Optional) Edit your Git identity inside setup.sh
nano setup.sh

# Run the interactive module selector
chmod +x setup.sh
./setup.sh
```

### 🛑 Uninstallation

We provide a **Graceful Uninstaller** that removes Nexus, Guide, Ecosystem utilities, and Hooks without deleting your personal files or uninstalling core system packages:

```bash
cd ~/.cache/cachy-workstation-setup
./uninstall.sh
```
