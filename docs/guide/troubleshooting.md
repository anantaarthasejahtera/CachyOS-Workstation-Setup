# 🆘 Troubleshooting & FAQ

No system is perfectly unbreakable, but the CachyOS Workstation provides the tooling to gracefully recover from the vast majority of Linux desktop issues.

## 🕰️ Recovering from a Bad Configuration

Did you edit your `waybar/style.css` and now the bar won't load? Did you add an invalid hook to `hyprland.conf` and now you're staring at a black screen?

**Solution: Use Time Machine**
1. Press `SUPER + X` to open the Nexus, or run `nexus rollback` from the terminal.
2. The system will display all recent changes by date and time in a Rofi menu.
3. Select the snapshot from *before* you broke the config.
4. The system will restore the files and immediately reload your graphical environment.

**If you are trapped in a TTY (Black screen, no UI):**
1. Switch to TTY2 via `Ctrl + Alt + F2`.
2. Login with your username.
3. List available backups: `ls ~/.config-backup/`
4. Pick the latest timestamp and restore manually:
   ```bash
   cp ~/.config-backup/YYYYMMDD-HHMMSS/__home__USER__.config__hypr__hyprland.conf ~/.config/hypr/hyprland.conf
   ```
5. Return to Hyprland: `Ctrl + Alt + F1` or `Hyprland` from TTY.

## 🛠️ Package Update Failures (Pacman Hooks)

If you run `sudo pacman -Syu` and see a massive block of red text from `99-cachy-health.hook`, **STOP**.
The Health Check intercepted a dangerous update (usually related to parsing a bad Hyprland config alongside an update, or a DKMS kernel compilation failure).

**Action:**
Read the explicit error thrown by `nexus doctor`. If it cites an NVIDIA DKMS failure, do not reboot. Run `sudo dkms autoinstall` to force the kernel module to recompile.

## 🐋 Docker Permission Issues

If you try to run `docker ps` and receive a permission error:
1. Ensure the Docker daemon is running: `sudo systemctl start docker`
2. Ensure your user is in the `docker` group: `groups | grep docker`
3. If not, add yourself: `sudo usermod -aG docker $USER` then **log out and back in** for group changes to apply.

## 🧠 Ollama / AI Tuner Too Slow

If `qwen3.5:4b` is generating text very slowly:
1. Your VRAM (GPU Memory) might be saturated. The MoE model needs a minimum of 16GB RAM, but prefers 24GB+ to load entirely into VRAM.
2. **Solution**: Purge background tasks, or switch to the much lighter `deepseek-r1:1.5b` model via Nexus.

## FAQ

**Q: Can I use this Go binary on Ubuntu or Fedora?**
A: No. This relies heavily on `pacman`, `paru`, the AUR, and CachyOS's custom kernel repos.

**Q: Does the Dynamic Themer support my custom Kitty config?**
A: The `nexus theme` feature uses `sed` to replace explicit variable names (like `#f5e0dc`). If you manually hardcoded hex codes into your `kitty.conf` instead of `include mocha.conf`, the themer will ignore them. Keep the `include` statements intact!
