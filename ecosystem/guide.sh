#!/usr/bin/env bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Guide v3 — Bilingual Interactive Reference (EN/ID)
#  
#  Usage:
#    guide                  → fzf interactive (preview + execute)
#    guide <keyword>        → filter by keyword
#    guide --popup          → rofi popup mode
#    guide --web <q>        → query cheat.sh
#    guide --lang id        → switch to Indonesian
#    guide --lang en        → switch to English (default)
#
#  Language auto-detection from LANG env or ~/.config/guide-lang
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ─── Colors ───────────────────────────────────────────────
C_MAUVE='\033[38;2;203;166;247m'
C_BLUE='\033[38;2;137;180;250m'
C_GREEN='\033[38;2;166;227;161m'
C_RED='\033[38;2;243;139;168m'
C_YELLOW='\033[38;2;249;226;175m'
C_TEAL='\033[38;2;148;226;213m'
C_TEXT='\033[38;2;205;214;244m'
C_DIM='\033[38;2;108;112;134m'
NC='\033[0m'
BOLD='\033[1m'

# ─── Language Detection ──────────────────────────────────
GUIDE_LANG="en"
LANG_FILE="$HOME/.config/guide-lang"

# Check saved preference
if [ -f "$LANG_FILE" ]; then
    GUIDE_LANG=$(cat "$LANG_FILE")
fi

# Check system locale
if [[ "$LANG" == id_ID* ]] && [ ! -f "$LANG_FILE" ]; then
    GUIDE_LANG="id"
fi

# ─── Text helpers ────────────────────────────────────────
# desc() picks EN or ID description based on GUIDE_LANG
desc() {
    if [ "$GUIDE_LANG" = "id" ]; then echo "$2"; else echo "$1"; fi
}

# ─── Guide Data Builder ─────────────────────────────────
build_guide_data() {
    local data=""

    add() {
        local cat="$1" cmd="$2" en="$3" id="$4" detail_en="$5" detail_id="$6" exe="$7" check="${8:-}"
        if [ -n "$check" ]; then
            command -v "$check" &>/dev/null || return
        fi
        local d=$(desc "$en" "$id")
        local dt=$(desc "$detail_en" "$detail_id")
        data+="${cat}|${cmd}|${d}|${dt}|${exe}\n"
    }

    # ══════════════════════════════════════════════════════
    # HYPRLAND — Keyboard Shortcuts
    # ══════════════════════════════════════════════════════
    add "hyprland" "Super+Return" \
        "Open Kitty terminal" "Buka terminal Kitty" \
        "GPU-accelerated terminal with ligatures, images, and transparency" \
        "Terminal GPU-accelerated dengan ligatur, gambar, dan transparansi" \
        "" ""
    add "hyprland" "Super+D" \
        "App launcher (Rofi)" "Peluncur aplikasi (Rofi)" \
        "Searchable app launcher with icons and Catppuccin theme" \
        "Peluncur aplikasi dengan pencarian, ikon, dan tema Catppuccin" \
        "" ""
    add "hyprland" "Super+X" \
        "Nexus Command Center" "Nexus Pusat Kontrol" \
        "Smart popup: system stats, quick actions, AI, apps, recording|Battery, RAM, disk displayed live in header" \
        "Popup pintar: statistik sistem, aksi cepat, AI, aplikasi, rekam|Baterai, RAM, disk ditampilkan live di header" \
        "" ""
    add "hyprland" "Super+Q" \
        "Close focused window" "Tutup jendela aktif" \
        "Immediately kills the focused window" "Langsung menutup jendela yang sedang aktif" \
        "" ""
    add "hyprland" "Super+M" \
        "Exit Hyprland (logout)" "Keluar Hyprland (logout)" \
        "Immediately exits the Hyprland session (returns to login manager)" "Langsung keluar dari sesi Hyprland (kembali ke login manager)" \
        "" ""
    add "hyprland" "Super+F" \
        "Toggle fullscreen" "Toggle layar penuh" \
        "Makes window fill entire screen or restore to tiled" "Membuat jendela penuh layar atau kembali ke tiling" \
        "" ""
    add "hyprland" "Super+Space" \
        "Toggle floating" "Toggle melayang" \
        "Switch between tiling mode and floating mode" "Beralih antara mode tiling dan mode melayang" \
        "" ""
    add "hyprland" "Super+P" \
        "Pseudo-tiling" "Pseudo-tiling" \
        "Keep window's preferred size within tiled slot (partially floating)" "Pertahankan ukuran preferensi jendela dalam slot tiling (setengah melayang)" \
        "" ""
    add "hyprland" "Super+J" \
        "Toggle split orientation" "Toggle orientasi split" \
        "Switch dwindle layout between horizontal and vertical split" "Beralih layout dwindle antara split horizontal dan vertikal" \
        "" ""
    add "hyprland" "Super+1-9" \
        "Switch workspace" "Pindah workspace" \
        "Jump to workspace 1-9. Each workspace is a virtual desktop" "Lompat ke workspace 1-9. Setiap workspace adalah desktop virtual" \
        "" ""
    add "hyprland" "Super+Shift+1-9" \
        "Move window to workspace" "Pindahkan jendela ke workspace" \
        "Send the active window to workspace 1-9" "Kirim jendela aktif ke workspace 1-9" \
        "" ""
    add "hyprland" "Super+Arrow" \
        "Move focus" "Pindah fokus" \
        "Navigate between windows using arrow keys" "Navigasi antar jendela dengan tombol panah" \
        "" ""
    add "hyprland" "Super+Shift+Arrow" \
        "Move window (direction)" "Pindahkan jendela (arah)" \
        "Move the active window to another position in tiling layout" "Pindahkan jendela aktif ke posisi lain dalam layout tiling" \
        "" ""
    add "hyprland" "Super+L" \
        "Lock screen" "Kunci layar" \
        "Hyprlock with blurred wallpaper, clock, and password input" "Hyprlock dengan wallpaper blur, jam, dan input password" \
        "" ""
    add "hyprland" "Super+E" \
        "File manager (Thunar)" "Manajer file (Thunar)" \
        "GTK file manager with sidebar, tabs, and bulk rename" "Manajer file GTK dengan sidebar, tab, dan rename massal" \
        "" ""
    add "hyprland" "Super+V" \
        "Clipboard history" "Riwayat clipboard" \
        "Browse all copied text and images (via cliphist + Rofi)" "Jelajahi semua teks dan gambar yang dicopy (via cliphist + Rofi)" \
        "" ""
    add "hyprland" "Super+N" \
        "Notification history" "Riwayat notifikasi" \
        "Pop the most recent notification from dunst history" "Munculkan notifikasi terbaru dari riwayat dunst" \
        "" ""
    add "hyprland" "Super+/" \
        "Keybind cheatsheet" "Lembar contekan shortcut" \
        "Floating window showing all keyboard shortcuts" "Jendela melayang menampilkan semua shortcut keyboard" \
        "" ""
    add "hyprland" "Super+Shift+S" \
        "Screenshot region" "Screenshot area" \
        "Select area with mouse then save to ~/Pictures/Screenshots/" "Pilih area dengan mouse lalu simpan ke ~/Pictures/Screenshots/" \
        "" ""
    add "hyprland" "Print" \
        "Screenshot fullscreen" "Screenshot layar penuh" \
        "Instantly capture the entire screen" "Langsung tangkap seluruh layar" \
        "" ""
    add "hyprland" "Super+Mouse" \
        "Drag to move/resize" "Drag untuk pindah/ubah ukuran" \
        "Hold Super + left click = move, right click = resize" "Tahan Super + klik kiri = pindah, klik kanan = ubah ukuran" \
        "" ""

    # ── Media Keys (Fn keys on laptop / multimedia keyboards) ──
    add "hyprland" "XF86AudioRaiseVolume" \
        "Volume up (+5%)" "Volume naik (+5%)" \
        "wpctl set-volume on default audio sink" "wpctl set-volume pada audio sink default" \
        "" ""
    add "hyprland" "XF86AudioLowerVolume" \
        "Volume down (-5%)" "Volume turun (-5%)" \
        "wpctl set-volume on default audio sink" "wpctl set-volume pada audio sink default" \
        "" ""
    add "hyprland" "XF86AudioMute" \
        "Mute/unmute" "Bisukan/aktifkan suara" \
        "Toggle mute on default audio sink via wpctl" "Toggle bisukan pada audio sink default via wpctl" \
        "" ""
    add "hyprland" "XF86MonBrightness↑/↓" \
        "Brightness up/down (5%)" "Kecerahan naik/turun (5%)" \
        "Adjust screen brightness via brightnessctl" "Atur kecerahan layar via brightnessctl" \
        "" ""
    add "hyprland" "XF86AudioPlay/Next/Prev" \
        "Media controls" "Kontrol media" \
        "Play/pause, next, previous track via playerctl" "Play/pause, lagu berikut, sebelumnya via playerctl" \
        "" ""

    # ══════════════════════════════════════════════════════
    # TERMINAL — Kitty + tmux
    # ══════════════════════════════════════════════════════
    add "terminal" "kitty" \
        "GPU-accelerated terminal" "Terminal GPU-accelerated" \
        "Features: font ligatures, inline images, tabs, splits, transparency|Config: ~/.config/kitty/kitty.conf|Font: JetBrainsMono Nerd Font" \
        "Fitur: ligatur font, gambar inline, tab, split, transparansi|Config: ~/.config/kitty/kitty.conf|Font: JetBrainsMono Nerd Font" \
        "" "kitty"
    add "terminal" "tmux" \
        "Terminal multiplexer" "Terminal multiplexer" \
        "Split terminal into panes, create windows (tabs), detach/reattach sessions|Prefix changed to Ctrl+A (easier than default Ctrl+B)|Theme: Catppuccin Mocha with status bar" \
        "Bagi terminal jadi panel, buat window (tab), lepas/sambungkan sesi|Prefix diubah ke Ctrl+A (lebih mudah dari Ctrl+B)|Tema: Catppuccin Mocha dengan status bar" \
        "" "tmux"
    add "terminal" "Ctrl+A c" \
        "tmux: New window (tab)" "tmux: Window baru (tab)" \
        "Create a new window in current tmux session" "Buat window baru di sesi tmux saat ini" \
        "" ""
    add "terminal" "Ctrl+A n/p" \
        "tmux: Next/prev window" "tmux: Window berikut/sebelum" \
        "Switch between tmux windows (like browser tabs)" "Berpindah antar window tmux (seperti tab browser)" \
        "" ""
    add "terminal" "Ctrl+A |" \
        "tmux: Split vertical" "tmux: Bagi vertikal" \
        "Split current pane into left and right" "Bagi panel saat ini jadi kiri dan kanan" \
        "" ""
    add "terminal" "Ctrl+A -" \
        "tmux: Split horizontal" "tmux: Bagi horizontal" \
        "Split current pane into top and bottom" "Bagi panel saat ini jadi atas dan bawah" \
        "" ""
    add "terminal" "Ctrl+A d" \
        "tmux: Detach session" "tmux: Lepas sesi" \
        "Detach from tmux (it keeps running in background). Reattach: tmux attach" \
        "Lepas dari tmux (tetap berjalan di latar). Sambung kembali: tmux attach" \
        "" ""
    add "terminal" "t / ta / tn / tl / tk" \
        "tmux shortcut aliases" "Alias singkat tmux" \
        "t=tmux, ta=attach, tn=new session, tl=list, tk=kill session|Example: tn work → creates session named 'work'" \
        "t=tmux, ta=attach, tn=sesi baru, tl=daftar, tk=hapus sesi|Contoh: tn work → buat sesi bernama 'work'" \
        "" ""

    # ══════════════════════════════════════════════════════
    # SHELL — ZSH + Modern CLI Tools (Rust-powered replacements)
    # ══════════════════════════════════════════════════════
    add "shell" "z <dir>" \
        "Smart cd (zoxide)" "cd pintar (zoxide)" \
        "Learns your frequently visited directories. Just type partial name|Example: z proj → ~/projects, z desk → ~/Desktop|Gets smarter over time as you navigate" \
        "Belajar direktori yang sering dikunjungi. Cukup ketik sebagian nama|Contoh: z proj → ~/projects, z desk → ~/Desktop|Makin pintar seiring waktu saat kamu navigasi" \
        "z" "zoxide"
    add "shell" "Ctrl+R" \
        "Fuzzy search history" "Cari riwayat (fuzzy)" \
        "Search through entire command history with fuzzy matching (fzf)|Much better than default reverse search" \
        "Cari seluruh riwayat perintah dengan pencocokan fuzzy (fzf)|Jauh lebih baik dari pencarian balik bawaan" \
        "" ""
    add "shell" "Tab" \
        "Smart autocomplete (fzf-tab)" "Autocomplete pintar (fzf-tab)" \
        "Enhanced tab completion with preview, fuzzy matching|Works for: commands, files, git branches, docker IDs, etc" \
        "Tab completion yang ditingkatkan dengan preview, pencocokan fuzzy|Berlaku untuk: perintah, file, branch git, ID docker, dll" \
        "" ""
    add "shell" "ls / ll / la / lt" \
        "eza (modern ls)" "eza (ls modern)" \
        "ls=icons+dirs first, ll=long+git status, la=all (hidden), lt=tree (2 levels)|Colorized, respects .gitignore, Nerd Font icons" \
        "ls=ikon+folder dulu, ll=panjang+status git, la=semua (tersembunyi), lt=pohon (2 level)|Berwarna, hormati .gitignore, ikon Nerd Font" \
        "eza --icons --group-directories-first" "eza"
    add "shell" "cat <file>" \
        "bat (syntax highlighting)" "bat (pewarnaan sintaks)" \
        "Like cat but with syntax highlighting, line numbers, and git diff|Supports 200+ languages. Theme: Catppuccin Mocha|Tip: bat --plain for clean output (no line numbers)" \
        "Seperti cat tapi dengan pewarnaan sintaks, nomor baris, dan git diff|Mendukung 200+ bahasa. Tema: Catppuccin Mocha|Tips: bat --plain untuk output bersih (tanpa nomor baris)" \
        "bat --style=auto" "bat"
    add "shell" "find <name>" \
        "fd (fast find)" "fd (pencarian cepat)" \
        "10x faster than find, respects .gitignore, regex support|Example: fd '.rs$' → find all Rust files|fd -t d → find only directories" \
        "10x lebih cepat dari find, hormati .gitignore, dukungan regex|Contoh: fd '.rs$' → cari semua file Rust|fd -t d → cari hanya direktori" \
        "fd" "fd"
    add "shell" "grep <pattern>" \
        "rg (ripgrep)" "rg (ripgrep)" \
        "Blazing fast grep. Auto-skips binary files and .gitignore|Example: rg 'TODO' → search all files for TODO|rg -i 'error' --type py → search only Python files (case-insensitive)" \
        "Grep super cepat. Otomatis lewati file biner dan .gitignore|Contoh: rg 'TODO' → cari semua file untuk TODO|rg -i 'error' --type py → cari hanya file Python (tidak peka huruf)" \
        "rg" "rg"
    add "shell" "top / btm" \
        "bottom (system monitor)" "bottom (monitor sistem)" \
        "Beautiful TUI: CPU cores, RAM, disk I/O, network, process tree|Keybinds: e=expand, s=sort, q=quit|Much better than htop or top" \
        "TUI cantik: core CPU, RAM, disk I/O, jaringan, pohon proses|Tombol: e=perluas, s=urutkan, q=keluar|Jauh lebih baik dari htop atau top" \
        "btm" "btm"
    add "shell" "ps / procs" \
        "procs (modern ps)" "procs (ps modern)" \
        "Beautiful process viewer with tree, CPU/MEM%, ports|Replaces 'ps aux'. Alias: ps=procs" \
        "Penampil proses cantik dengan tree, CPU/MEM%, port|Menggantikan 'ps aux'. Alias: ps=procs" \
        "procs" "procs"
    add "shell" "du / dust" \
        "dust (disk usage tree)" "dust (pohon penggunaan disk)" \
        "Visual tree showing which folders use most space|Replaces 'du'. Alias: du=dust" \
        "Pohon visual menampilkan folder yang pakai ruang terbanyak|Menggantikan 'du'. Alias: du=dust" \
        "dust" "dust"
    add "shell" "df / duf" \
        "duf (disk free overview)" "duf (ringkasan disk kosong)" \
        "Colorful overview: filesystem, mount point, size, used, available|Replaces 'df'. Alias: df=duf" \
        "Ringkasan berwarna: filesystem, mount point, ukuran, terpakai, tersedia|Menggantikan 'df'. Alias: df=duf" \
        "duf" "duf"
    add "shell" "ff" \
        "fastfetch (system info)" "fastfetch (info sistem)" \
        "Show: OS, kernel, CPU, GPU, RAM, uptime, theme, resolution|Custom config with Catppuccin colors|Much faster than neofetch" \
        "Tampilkan: OS, kernel, CPU, GPU, RAM, uptime, tema, resolusi|Config kustom dengan warna Catppuccin|Jauh lebih cepat dari neofetch" \
        "fastfetch" "fastfetch"
    add "shell" "update" \
        "Full system update (interactive)" "Update sistem lengkap (interaktif)" \
        "Shows pending packages first, then asks confirmation|Runs: pacman -Syu + flatpak update + rustup update" \
        "Tampilkan paket pending dulu, lalu minta konfirmasi|Jalankan: pacman -Syu + flatpak update + rustup update" \
        "" ""
    add "shell" "cleanup" \
        "Remove orphan packages" "Hapus paket orphan" \
        "Remove unused packages and clear pacman cache|Frees disk space safely" \
        "Hapus paket tidak terpakai dan bersihkan cache pacman|Bebaskan ruang disk dengan aman" \
        "sudo pacman -Sc --noconfirm" ""
    add "shell" "myip" \
        "Show public IP" "Tampilkan IP publik" \
        "Query ifconfig.me to show your public IP address" "Query ifconfig.me untuk menampilkan alamat IP publik" \
        "curl -s ifconfig.me && echo ''" ""
    add "shell" "weather" \
        "Show weather" "Tampilkan cuaca" \
        "Show current weather in one line via wttr.in" "Tampilkan cuaca saat ini dalam satu baris via wttr.in" \
        "curl -s wttr.in/?format=3" ""
    add "shell" "ports" \
        "List open ports" "Lihat port terbuka" \
        "Show all listening TCP/UDP ports with process names" "Tampilkan semua port TCP/UDP yang mendengarkan dengan nama proses" \
        "ss -tulnp" ""
    add "shell" "keys" \
        "Keybind cheatsheet" "Lembar contekan shortcut" \
        "Display the Hyprland keyboard shortcuts reference file" "Tampilkan file referensi shortcut keyboard Hyprland" \
        "cat ~/.config/hypr/cheatsheet.txt" ""

    add "shell" ".. / ..." \
        "Quick parent navigation" "Navigasi cepat ke parent" \
        "..=up 1 dir, ...=up 2 dirs. Uses zoxide under the hood" \
        "..=naik 1 dir, ...=naik 2 dir. Menggunakan zoxide di belakang" \
        "" ""
    add "shell" "mkdir" \
        "mkdir -pv (enhanced)" "mkdir -pv (ditingkatkan)" \
        "Aliased to create parent dirs + verbose output" \
        "Di-alias untuk buat parent dirs + output verbose" \
        "" ""

    # ══════════════════════════════════════════════════════
    # GIT — Version Control + Aliases
    # ══════════════════════════════════════════════════════
    add "git" "git status" \
        "Check repo status" "Cek status repo" \
        "Show modified, staged, and untracked files|Alias: gs" \
        "Tampilkan file yang diubah, staged, dan untracked|Alias: gs" \
        "git status" "git"
    add "git" "git add ." \
        "Stage all changes" "Stage semua perubahan" \
        "Add all modified and new files to staging area|Then commit with: git commit -m 'message'" \
        "Tambahkan semua file yang diubah dan baru ke staging area|Lalu commit dengan: git commit -m 'pesan'" \
        "git add ." "git"
    add "git" "git commit -m 'msg'" \
        "Commit with message" "Commit dengan pesan" \
        "Save staged changes with a descriptive message|Convention: feat:, fix:, refactor:, docs:, chore:" \
        "Simpan perubahan staged dengan pesan deskriptif|Konvensi: feat:, fix:, refactor:, docs:, chore:" \
        "" "git"
    add "git" "git push" \
        "Push to remote" "Push ke remote" \
        "Upload commits to GitHub/remote repository|First time: git push -u origin main" \
        "Unggah commit ke repositori GitHub/remote|Pertama kali: git push -u origin main" \
        "git push" "git"
    add "git" "git pull" \
        "Pull from remote" "Pull dari remote" \
        "Download and merge latest changes from remote|Uses rebase by default (configured in setup)" \
        "Unduh dan gabungkan perubahan terbaru dari remote|Gunakan rebase secara default (dikonfigurasi di setup)" \
        "git pull" "git"
    add "git" "gl" \
        "Git log (pretty)" "Git log (cantik)" \
        "Pretty graph with decorations, shows last 20 commits|Alias for: git log --oneline --graph --decorate -20" \
        "Grafik cantik dengan dekorasi, tampilkan 20 commit terakhir|Alias untuk: git log --oneline --graph --decorate -20" \
        "git log --oneline --graph --decorate -20" "git"
    add "git" "gh auth login" \
        "Login to GitHub CLI" "Login ke GitHub CLI" \
        "Authenticate with GitHub for creating repos, PRs, issues|Uses browser-based OAuth flow" \
        "Autentikasi dengan GitHub untuk buat repo, PR, issue|Gunakan alur OAuth berbasis browser" \
        "gh auth login" "gh"
    add "git" "gh repo create" \
        "Create GitHub repo" "Buat repo GitHub" \
        "Interactive: choose name, visibility (public/private), description|Can also push existing local repo" \
        "Interaktif: pilih nama, visibilitas (publik/privat), deskripsi|Juga bisa push repo lokal yang sudah ada" \
        "gh repo create" "gh"
    add "git" "gh pr create" \
        "Create pull request" "Buat pull request" \
        "Open PR from current branch to main|Interactive: title, body, reviewers" \
        "Buka PR dari branch saat ini ke main|Interaktif: judul, isi, reviewer" \
        "gh pr create" "gh"
    add "git" "git diff" \
        "Show changes" "Tampilkan perubahan" \
        "Show line-by-line changes (uses delta with side-by-side view)|Alias: gd" \
        "Tampilkan perubahan baris per baris (pakai delta dengan tampilan berdampingan)|Alias: gd" \
        "git diff" "git"
    add "git" "git stash" \
        "Stash changes temporarily" "Simpan perubahan sementara" \
        "Save uncommitted changes aside. Restore: git stash pop|Useful when switching branches" \
        "Simpan perubahan yang belum dicommit. Kembalikan: git stash pop|Berguna saat berpindah branch" \
        "" "git"
    add "git" "lazygit" \
        "Terminal Git UI (interactive)" "UI Git Terminal (interaktif)" \
        "Beautiful TUI: stage hunks, branch, rebase, merge conflicts, stash|Navigate: arrow keys, Enter, Space to stage|Much faster than typing git commands manually" \
        "TUI cantik: stage hunk, branch, rebase, konflik merge, stash|Navigasi: panah, Enter, Space untuk stage|Jauh lebih cepat dari mengetik perintah git manual" \
        "lazygit" "lazygit"
    add "git" "ga / gco / gb / gpl" \
        "Git shortcut aliases" "Alias singkat Git" \
        "ga=git add, gco=git checkout, gb=git branch, gpl=git pull|Full list: gs=status, gc=commit, gp=push, gd=diff, gl=log" \
        "ga=git add, gco=git checkout, gb=git branch, gpl=git pull|Daftar lengkap: gs=status, gc=commit, gp=push, gd=diff, gl=log" \
        "" "git"

    # ══════════════════════════════════════════════════════
    # DOCKER — Containers
    # ══════════════════════════════════════════════════════
    add "docker" "docker ps" \
        "List running containers" "Daftar container berjalan" \
        "Show running containers with ports, names, status|Add -a for all (including stopped)|Alias: dps (with formatted table)" \
        "Tampilkan container berjalan dengan port, nama, status|Tambah -a untuk semua (termasuk berhenti)|Alias: dps (dengan tabel terformat)" \
        "docker ps" "docker"
    add "docker" "docker compose up -d" \
        "Start compose services" "Mulai layanan compose" \
        "Start all services defined in docker-compose.yml in background|-d = detached mode (runs in background)" \
        "Mulai semua layanan di docker-compose.yml di latar belakang|-d = mode detached (berjalan di latar)" \
        "docker compose up -d" "docker"
    add "docker" "docker compose down" \
        "Stop compose services" "Hentikan layanan compose" \
        "Stop and remove all compose containers, networks|Add -v to also remove volumes (data)" \
        "Hentikan dan hapus semua container compose, jaringan|Tambah -v untuk hapus juga volume (data)" \
        "docker compose down" "docker"
    add "docker" "lazydocker / lzd" \
        "Docker TUI manager" "Manajer Docker TUI" \
        "Beautiful terminal UI: containers, images, volumes, logs|Navigate with arrow keys, Enter to see logs|Alias: lzd=lazydocker" \
        "UI terminal cantik: container, image, volume, log|Navigasi dengan panah, Enter untuk lihat log|Alias: lzd=lazydocker" \
        "lazydocker" "lazydocker"
    add "docker" "docker logs -f / dlog" \
        "Follow container logs" "Ikuti log container" \
        "Stream real-time logs from a container. Ctrl+C to stop|Alias: dlog=docker logs -f" \
        "Stream log real-time dari container. Ctrl+C untuk berhenti|Alias: dlog=docker logs -f" \
        "" "docker"
    add "docker" "docker exec -it / dex" \
        "Enter container shell" "Masuk shell container" \
        "Open interactive bash inside running container|Use 'sh' instead of 'bash' for Alpine-based images|Alias: dex=docker exec -it" \
        "Buka bash interaktif di dalam container berjalan|Gunakan 'sh' bukan 'bash' untuk image berbasis Alpine|Alias: dex=docker exec -it" \
        "" "docker"
    add "docker" "docker compose / dc" \
        "Docker Compose shortcut" "Singkatan Docker Compose" \
        "Alias: dc=docker compose. Usage: dc up -d, dc down, dc logs" \
        "Alias: dc=docker compose. Pemakaian: dc up -d, dc down, dc logs" \
        "" "docker"
    add "docker" "docker system prune" \
        "Clean Docker junk" "Bersihkan sampah Docker" \
        "Remove: stopped containers, unused networks, dangling images|Add --volumes to also clean volumes. Frees significant disk space" \
        "Hapus: container berhenti, jaringan tak terpakai, image menggantung|Tambah --volumes untuk bersihkan volume. Bebaskan banyak ruang disk" \
        "" "docker"

    # ══════════════════════════════════════════════════════
    # NODE.JS
    # ══════════════════════════════════════════════════════
    add "node" "fnm use --lts" \
        "Switch to LTS Node" "Beralih ke Node LTS" \
        "Fast Node Manager: instantly switch Node.js versions|fnm install --lts → install latest LTS|fnm list → show installed versions|Default: LTS (installed by setup)" \
        "Fast Node Manager: beralih versi Node.js secara instan|fnm install --lts → install LTS terbaru|fnm list → tampilkan versi terinstall|Default: LTS (terinstall oleh setup)" \
        "fnm use --lts" "fnm"
    add "node" "pnpm install" \
        "Install dependencies" "Install dependensi" \
        "Fast, disk-efficient install using hard links|~60% faster than npm, saves gigabytes of disk space" \
        "Install cepat, hemat disk menggunakan hard link|~60% lebih cepat dari npm, hemat gigabyte ruang disk" \
        "pnpm install" "pnpm"
    add "node" "pnpm run dev" \
        "Start dev server" "Mulai server dev" \
        "Run the project's development server (Vite, Next.js, etc)" "Jalankan server development proyek (Vite, Next.js, dll)" \
        "pnpm run dev" "pnpm"
    add "node" "pnpm add <pkg>" \
        "Add package" "Tambah paket" \
        "Install and save a new dependency|pnpm add -D <pkg> → dev dependency" \
        "Install dan simpan dependensi baru|pnpm add -D <pkg> → dependensi dev" \
        "" "pnpm"
    add "node" "pnpm dlx <cmd>" \
        "Run CLI tool (like npx)" "Jalankan CLI tool (seperti npx)" \
        "Execute a package without installing globally|Example: pnpm dlx create-vite@latest" \
        "Eksekusi paket tanpa install global|Contoh: pnpm dlx create-vite@latest" \
        "" "pnpm"

    # ══════════════════════════════════════════════════════
    # PYTHON
    # ══════════════════════════════════════════════════════
    add "python" "uv init" \
        "Create Python project" "Buat proyek Python" \
        "Initialize with pyproject.toml and .venv|Much faster than pip + virtualenv (100x faster)" \
        "Inisialisasi dengan pyproject.toml dan .venv|Jauh lebih cepat dari pip + virtualenv (100x lebih cepat)" \
        "uv init" "uv"
    add "python" "uv add <pkg>" \
        "Add dependency" "Tambah dependensi" \
        "Install package, add to pyproject.toml, lock version|uv add requests pandas numpy" \
        "Install paket, tambah ke pyproject.toml, kunci versi|uv add requests pandas numpy" \
        "" "uv"
    add "python" "uv run script.py" \
        "Run Python script" "Jalankan skrip Python" \
        "Execute in managed environment with correct dependencies|No manual venv activation needed" \
        "Eksekusi di environment terkelola dengan dependensi yang benar|Tidak perlu aktivasi venv manual" \
        "" "uv"
    add "python" "uv sync" \
        "Sync environment" "Sinkron environment" \
        "Install all dependencies from pyproject.toml|Like: pip install -r requirements.txt but faster" \
        "Install semua dependensi dari pyproject.toml|Seperti: pip install -r requirements.txt tapi lebih cepat" \
        "uv sync" "uv"

    # ══════════════════════════════════════════════════════
    # RUST
    # ══════════════════════════════════════════════════════
    add "rust" "cargo new <name>" \
        "Create Rust project" "Buat proyek Rust" \
        "Generate project with src/main.rs and Cargo.toml|cargo new --lib <name> → library project" \
        "Buat proyek dengan src/main.rs dan Cargo.toml|cargo new --lib <name> → proyek library" \
        "" "cargo"
    add "rust" "cargo run" \
        "Build and run" "Build dan jalankan" \
        "Compile and execute the project in one step" "Kompilasi dan eksekusi proyek dalam satu langkah" \
        "cargo run" "cargo"
    add "rust" "cargo build --release" \
        "Release build" "Build rilis" \
        "Optimized build for production (much faster binary)|Output: target/release/<binary>" \
        "Build teroptimasi untuk produksi (binary jauh lebih cepat)|Output: target/release/<binary>" \
        "cargo build --release" "cargo"
    add "rust" "cargo test" \
        "Run tests" "Jalankan tes" \
        "Run all unit tests and integration tests" "Jalankan semua unit test dan integration test" \
        "cargo test" "cargo"
    add "rust" "rustup update" \
        "Update Rust toolchain" "Update toolchain Rust" \
        "Update Rust compiler, cargo, and standard library" "Update compiler Rust, cargo, dan standard library" \
        "rustup update" "rustup"

    # ══════════════════════════════════════════════════════
    # GO
    # ══════════════════════════════════════════════════════
    add "go" "go mod init <module>" \
        "Create Go module" "Buat modul Go" \
        "Initialize a new Go module with go.mod|Example: go mod init github.com/user/project" \
        "Inisialisasi modul Go baru dengan go.mod|Contoh: go mod init github.com/user/project" \
        "" "go"
    add "go" "go run ." \
        "Run Go program" "Jalankan program Go" \
        "Compile and execute the current package" "Kompilasi dan eksekusi paket saat ini" \
        "go run ." "go"
    add "go" "go build" \
        "Build binary" "Build binary" \
        "Compile into executable binary" "Kompilasi jadi binary eksekutabel" \
        "go build" "go"

    # ══════════════════════════════════════════════════════
    # FLUTTER & ANDROID
    # ══════════════════════════════════════════════════════
    add "flutter" "flutter create <app>" \
        "Create Flutter project" "Buat proyek Flutter" \
        "Generate full Flutter project with Android/iOS/Web dirs|flutter create --org com.example myapp" \
        "Buat proyek Flutter lengkap dengan dir Android/iOS/Web|flutter create --org com.example myapp" \
        "" "flutter"
    add "flutter" "flutter run" \
        "Run on device/emulator" "Jalankan di perangkat/emulator" \
        "Hot reload: press 'r'. Hot restart: press 'R'|Auto-detects connected device or running emulator" \
        "Hot reload: tekan 'r'. Hot restart: tekan 'R'|Otomatis deteksi perangkat terhubung atau emulator berjalan" \
        "flutter run" "flutter"
    add "flutter" "flutter build apk" \
        "Build Android APK" "Build APK Android" \
        "Create release APK for Android distribution|Output: build/app/outputs/flutter-apk/app-release.apk" \
        "Buat APK rilis untuk distribusi Android|Output: build/app/outputs/flutter-apk/app-release.apk" \
        "flutter build apk" "flutter"
    add "flutter" "flutter doctor" \
        "Check Flutter setup" "Cek setup Flutter" \
        "Verify: Flutter SDK, Android SDK, devices, licenses|Fix issues shown with [✗] marks" \
        "Verifikasi: Flutter SDK, Android SDK, perangkat, lisensi|Perbaiki masalah yang ditandai [✗]" \
        "flutter doctor" "flutter"
    add "flutter" "scrcpy" \
        "Mirror phone to screen" "Mirror HP ke layar" \
        "Real-time mirror via USB/WiFi. Low latency, high quality|Tip: scrcpy --no-audio for faster mirror" \
        "Mirror real-time via USB/WiFi. Latensi rendah, kualitas tinggi|Tips: scrcpy --no-audio untuk mirror lebih cepat" \
        "scrcpy" "scrcpy"
    add "flutter" "adb devices" \
        "List connected devices" "Daftar perangkat terhubung" \
        "Show all Android devices connected via USB or WiFi|Enable USB Debugging on phone first" \
        "Tampilkan semua perangkat Android terhubung via USB atau WiFi|Aktifkan USB Debugging di HP terlebih dahulu" \
        "adb devices" "adb"
    add "flutter" "emulator -avd Pixel_7" \
        "Launch Android emulator" "Luncurkan emulator Android" \
        "Start the pre-configured Pixel 7 emulator (API 34)|First launch takes ~2 minutes" \
        "Mulai emulator Pixel 7 yang sudah dikonfigurasi (API 34)|Peluncuran pertama memakan ~2 menit" \
        "emulator -avd Pixel_7" "emulator"

    # ══════════════════════════════════════════════════════
    # EDITORS
    # ══════════════════════════════════════════════════════
    add "editor" "antigravity" \
        "AI-powered code editor" "Editor kode berbasis AI" \
        "VS Code fork with built-in Google AI assistant|Supports: code generation, refactoring, debugging, chat" \
        "Fork VS Code dengan asisten AI Google bawaan|Mendukung: generasi kode, refactoring, debugging, chat" \
        "antigravity" "antigravity"
    add "editor" "nvim <file>" \
        "Neovim editor" "Editor Neovim" \
        "Configured with lazy.nvim plugin manager|Theme: Catppuccin Mocha|Plugins: Telescope, nvim-tree, LSP, Treesitter, which-key" \
        "Dikonfigurasi dengan manajer plugin lazy.nvim|Tema: Catppuccin Mocha|Plugin: Telescope, nvim-tree, LSP, Treesitter, which-key" \
        "nvim" "nvim"
    add "editor" "nvim: Space" \
        "Leader key (which-key)" "Tombol leader (which-key)" \
        "Press Space in normal mode → popup showing all available commands|Explore keybinds visually" \
        "Tekan Space di mode normal → popup menampilkan semua perintah|Jelajahi keybind secara visual" \
        "" "nvim"
    add "editor" "nvim: Space+ff" \
        "Find files (Telescope)" "Cari file (Telescope)" \
        "Fuzzy file finder across entire project" "Pencari file fuzzy di seluruh proyek" \
        "" "nvim"
    add "editor" "nvim: Space+fg" \
        "Live grep (Telescope)" "Cari teks (Telescope)" \
        "Search text content across all files in project" "Cari konten teks di seluruh file dalam proyek" \
        "" "nvim"

    # ══════════════════════════════════════════════════════
    # AI — Ollama models
    # ══════════════════════════════════════════════════════
    add "ai" "ollama run qwen3:30b-a3b" \
        "Reasoning AI (best for debate)" "AI Penalaran (terbaik untuk debat)" \
        "30B model with MoE (only 3B active = efficient)|Best for: philosophy, debate, strategy, analysis|~16GB RAM. First run downloads model (~17GB)" \
        "Model 30B dengan MoE (hanya 3B aktif = efisien)|Terbaik untuk: filosofi, debat, strategi, analisis|~16GB RAM. Jalankan pertama mengunduh model (~17GB)" \
        "ollama run qwen3:30b-a3b" "ollama"
    add "ai" "ollama run deepseek-r1:7b" \
        "Math & Logic AI" "AI Matematika & Logika" \
        "Specialized in mathematical reasoning and proofs|Shows thinking process step by step|~5GB RAM" \
        "Spesialisasi penalaran matematika dan pembuktian|Menampilkan proses berpikir langkah demi langkah|~5GB RAM" \
        "ollama run deepseek-r1:7b" "ollama"
    add "ai" "ollama run qwen2.5-coder:7b" \
        "Code Assistant AI" "AI Asisten Koding" \
        "GPT-4o level coding. Code generation, refactor, explain|Understands: Python, JS, Rust, Go, Dart, and more|~5GB RAM" \
        "Koding level GPT-4o. Generasi kode, refactor, penjelasan|Mengerti: Python, JS, Rust, Go, Dart, dan lainnya|~5GB RAM" \
        "ollama run qwen2.5-coder:7b" "ollama"
    add "ai" "ollama list" \
        "List downloaded models" "Daftar model terunduh" \
        "Show all locally downloaded models with sizes" "Tampilkan semua model yang diunduh lokal beserta ukurannya" \
        "ollama list" "ollama"
    add "ai" "ollama pull <model>" \
        "Download new model" "Unduh model baru" \
        "Download from Ollama registry. Browse: ollama.com/library|Popular: llama3.1, codellama, mistral, gemma2" \
        "Unduh dari registry Ollama. Jelajahi: ollama.com/library|Populer: llama3.1, codellama, mistral, gemma2" \
        "" "ollama"

    # ══════════════════════════════════════════════════════
    # GAMING
    # ══════════════════════════════════════════════════════
    add "gaming" "steam" \
        "Steam launcher" "Peluncur Steam" \
        "PC gaming. Proton enabled for Windows games|Settings > Compatibility > Enable Steam Play for all titles" \
        "Gaming PC. Proton aktif untuk game Windows|Settings > Compatibility > Enable Steam Play untuk semua judul" \
        "steam" "steam"
    add "gaming" "gamemoderun <game>" \
        "GameMode performance boost" "GameMode boost performa" \
        "Auto-optimize: CPU governor to performance, GPU clock boost|Example: gamemoderun steam" \
        "Otomatis optimasi: CPU governor ke performa, boost clock GPU|Contoh: gamemoderun steam" \
        "" "gamemoderun"
    add "gaming" "mangohud <game>" \
        "FPS overlay" "Overlay FPS" \
        "MangoHud: show FPS, CPU/GPU usage, temp, frametime|Toggle: F12 in-game|Config: ~/.config/MangoHud/MangoHud.conf" \
        "MangoHud: tampilkan FPS, penggunaan CPU/GPU, suhu, frametime|Toggle: F12 dalam game|Config: ~/.config/MangoHud/MangoHud.conf" \
        "" "mangohud"
    add "gaming" "prismlauncher" \
        "Minecraft launcher" "Peluncur Minecraft" \
        "Open-source launcher: multiple instances, mods, modpacks|Supports: Fabric, Forge, Quilt" \
        "Peluncur open-source: banyak instance, mod, modpack|Mendukung: Fabric, Forge, Quilt" \
        "prismlauncher" "prismlauncher"
    add "gaming" "pcsx2" \
        "PS2 Emulator" "Emulator PS2" \
        "Play PS2 games. GPU-aware config: discrete GPUs get 3x upscale, integrated stays native|Supports: ISO and compressed formats|BIOS required (place in ~/.config/PCSX2/bios/)" \
        "Main game PS2. Config sadar GPU: GPU diskrit 3x upscale, terintegrasi tetap native|Mendukung: format ISO dan terkompresi|BIOS diperlukan (taruh di ~/.config/PCSX2/bios/)" \
        "pcsx2" "pcsx2"

    # ══════════════════════════════════════════════════════
    # VM — QEMU/KVM
    # ══════════════════════════════════════════════════════
    add "vm" "virt-manager" \
        "VM Manager GUI" "GUI Manajer VM" \
        "Create and manage QEMU/KVM virtual machines|Near-native performance (~90-95%)|Hugepages + CPU pinning enabled" \
        "Buat dan kelola mesin virtual QEMU/KVM|Performa mendekati asli (~90-95%)|Hugepages + CPU pinning diaktifkan" \
        "virt-manager" "virt-manager"
    add "vm" "virsh list --all" \
        "List all VMs" "Daftar semua VM" \
        "Show all virtual machines with status (running/shut off)" "Tampilkan semua mesin virtual dengan status (berjalan/mati)" \
        "virsh list --all" "virsh"
    add "vm" "virsh start <vm>" \
        "Start a VM" "Mulai VM" \
        "Boot a stopped virtual machine" "Nyalakan mesin virtual yang berhenti" \
        "" "virsh"
    add "vm" "virsh shutdown <vm>" \
        "Shutdown VM gracefully" "Matikan VM dengan aman" \
        "Send ACPI shutdown signal (like pressing power button)" "Kirim sinyal ACPI shutdown (seperti tekan tombol power)" \
        "" "virsh"

    # ══════════════════════════════════════════════════════
    # APPS — Productivity
    # ══════════════════════════════════════════════════════
    add "apps" "obsidian" \
        "Markdown notes (vault)" "Catatan Markdown (vault)" \
        "Knowledge management: graph view, backlinks, plugins|Create a vault in ~/Obsidian or ~/Documents/notes" \
        "Manajemen pengetahuan: tampilan graf, backlink, plugin|Buat vault di ~/Obsidian atau ~/Documents/notes" \
        "" ""
    add "apps" "keepassxc" \
        "Password manager" "Manajer password" \
        "AES-256 encrypted, fully offline, auto-fill in browser|Database file: keep backed up!" \
        "Enkripsi AES-256, sepenuhnya offline, auto-fill di browser|File database: jaga backup-nya!" \
        "keepassxc" "keepassxc"
    add "apps" "obs" \
        "OBS Studio (recording)" "OBS Studio (rekaman)" \
        "Professional screen recording and live streaming|Scenes, sources, filters, transitions|Supports: Twitch, YouTube, custom RTMP" \
        "Rekaman layar dan streaming langsung profesional|Scene, sumber, filter, transisi|Mendukung: Twitch, YouTube, RTMP kustom" \
        "obs" "obs"
    add "apps" "bottles" \
        "Run Windows apps" "Jalankan aplikasi Windows" \
        "Wine-based app runner without full VM|Great for: office apps, small games, utilities" \
        "Penjalanan app berbasis Wine tanpa VM penuh|Bagus untuk: aplikasi kantor, game kecil, utilitas" \
        "flatpak run com.usebottles.bottles" ""
    add "apps" "libreoffice" \
        "Office suite" "Suite kantor" \
        "Open .docx, .xlsx, .pptx natively|Writer, Calc, Impress, Draw" \
        "Buka .docx, .xlsx, .pptx secara native|Writer, Calc, Impress, Draw" \
        "libreoffice" "libreoffice"

    # ══════════════════════════════════════════════════════
    # SYSTEM — Maintenance & Network
    # ══════════════════════════════════════════════════════
    add "system" "timeshift" \
        "System backup/restore" "Backup/restore sistem" \
        "Create snapshots like macOS Time Machine|Restore from GRUB if system breaks|Auto-snapshots via systemd timer" \
        "Buat snapshot seperti macOS Time Machine|Restore dari GRUB jika sistem rusak|Auto-snapshot via systemd timer" \
        "sudo timeshift --create" "timeshift"
    add "system" "nmcli d wifi list" \
        "List WiFi networks" "Daftar jaringan WiFi" \
        "Show available networks with signal strength, security type" "Tampilkan jaringan tersedia dengan kekuatan sinyal, tipe keamanan" \
        "nmcli device wifi list" "nmcli"
    add "system" "nmtui" \
        "Network TUI manager" "Manajer jaringan TUI" \
        "Simple terminal UI for: WiFi, Ethernet, DNS, hostname" "UI terminal sederhana untuk: WiFi, Ethernet, DNS, hostname" \
        "nmtui" "nmtui"

    # ══════════════════════════════════════════════════════
    # RECORDING — Screen capture
    # ══════════════════════════════════════════════════════
    add "record" "record" \
        "Record screen (alias)" "Rekam layar (alias)" \
        "Record full screen to ~/Videos/ with timestamp|Stop: Ctrl+C or Super+X → Stop Recording" \
        "Rekam layar penuh ke ~/Videos/ dengan timestamp|Stop: Ctrl+C atau Super+X → Stop Recording" \
        "wf-recorder -f ~/Videos/recording-\$(date +%Y%m%d-%H%M%S).mp4" "wf-recorder"
    add "record" "clip" \
        "Record region (alias)" "Rekam area (alias)" \
        "Select area with mouse, then record that region" "Pilih area dengan mouse, lalu rekam area tersebut" \
        "" "wf-recorder"
    add "record" "screenshot" \
        "Screenshot (alias)" "Screenshot (alias)" \
        "Full screen capture saved to ~/Pictures/Screenshots/" "Tangkap layar penuh disimpan ke ~/Pictures/Screenshots/" \
        "grim ~/Pictures/Screenshots/\$(date +%Y%m%d-%H%M%S).png" "grim"

    # ══════════════════════════════════════════════════════
    # ECOSYSTEM — Living Ecosystem (9 Integrated Tools)
    # ══════════════════════════════════════════════════════
    add "ecosystem" "theme-switch" \
        "Dynamic Theme Switcher" "Pengubah Tema Dinamis" \
        "Hot-swap between 7 themes: Catppuccin (Mocha/Macchiato/Frappe/Latte), Dracula, Tokyo Night, Rosé Pine|Instantly reloads: Hyprland borders, Waybar CSS, Rofi, Kitty, Dunst|Run from Nexus (Super+X) or terminal" \
        "Ganti antar 7 tema secara instan: Catppuccin (Mocha/Macchiato/Frappe/Latte), Dracula, Tokyo Night, Rosé Pine|Reload otomatis: border Hyprland, CSS Waybar, Rofi, Kitty, Dunst|Jalankan dari Nexus (Super+X) atau terminal" \
        "theme-switch" ""
    add "ecosystem" "config-rollback" \
        "Time Machine (Config Rollback)" "Mesin Waktu (Rollback Konfigurasi)" \
        "Browse timestamped backups from ~/.config-backup/ via Rofi|Restore single files (e.g., waybar/style.css) or ALL at once|Auto-reloads Waybar and Hyprland after restore" \
        "Jelajahi backup bertimestamp dari ~/.config-backup/ via Rofi|Restore file tunggal (misal waybar/style.css) atau SEMUA sekaligus|Auto-reload Waybar dan Hyprland setelah restore" \
        "config-rollback" ""
    add "ecosystem" "dotfiles-sync" \
        "Dotfiles Cloud Sync" "Sinkronisasi Cloud Dotfiles" \
        "Push ~/.config/ to a private Git repository safely|Smart .gitignore skips: Code/, Chrome, Discord, Spotify, tokens|First run: prompts for repo URL. Subsequent runs: auto-push" \
        "Push ~/.config/ ke repositori Git privat dengan aman|.gitignore pintar melewati: Code/, Chrome, Discord, Spotify, token|Jalankan pertama: minta URL repo. Selanjutnya: auto-push" \
        "dotfiles-sync" ""
    add "ecosystem" "ai-tuner" \
        "AI Auto-Tuner (System Optimizer)" "AI Auto-Tuner (Optimasi Sistem)" \
        "Gathers real-time telemetry: top, free, vmstat|Pipes data to local qwen2.5-coder:7b via Ollama|Displays 3 actionable sysctl/optimization tips via Rofi popup" \
        "Kumpulkan telemetri real-time: top, free, vmstat|Kirim data ke qwen2.5-coder:7b lokal via Ollama|Tampilkan 3 tips optimasi sysctl yang actionable via popup Rofi" \
        "ai-tuner" "ollama"
    add "ecosystem" "app-store" \
        "GUI App Store (Rofi)" "Toko Aplikasi GUI (Rofi)" \
        "Curated app browser: Browsers, Dev Tools, Gaming, Media, Utilities|Multi-tier Rofi menu: Category → App → Confirm → Install|Supports: pacman, paru (AUR), and flatpak backends" \
        "Peramban aplikasi terkurasi: Browser, Dev Tools, Gaming, Media, Utilitas|Menu Rofi multi-tingkat: Kategori → Aplikasi → Konfirmasi → Install|Mendukung: pacman, paru (AUR), dan backend flatpak" \
        "app-store" ""
    add "ecosystem" "health-check" \
        "System Health Check (Doctor)" "Pemeriksaan Kesehatan Sistem (Dokter)" \
        "Validates: GPU drivers, Hyprland/Waybar config, critical packages, kernel modules, services, backups, disk space|Auto-runs via pacman hook after kernel/Hyprland/Waybar/NVIDIA updates|Run from Nexus (Super+X → Health Check) or terminal" \
        "Validasi: driver GPU, config Hyprland/Waybar, paket kritis, modul kernel, layanan, backup, ruang disk|Otomatis jalan via hook pacman setelah update kernel/Hyprland/Waybar/NVIDIA|Jalankan dari Nexus (Super+X → Health Check) atau terminal" \
        "health-check" ""
    add "ecosystem" "wallpaper-picker" \
        "Wallpaper Picker" "Pemilih Wallpaper" \
        "Browse and apply wallpapers from ~/Pictures/Wallpapers/ via Rofi|Instantly updates Hyprpaper|Run from Nexus (Super+X → Change Wallpaper) or terminal" \
        "Jelajahi dan terapkan wallpaper dari ~/Pictures/Wallpapers/ via Rofi|Langsung update Hyprpaper|Jalankan dari Nexus (Super+X → Change Wallpaper) atau terminal" \
        "wallpaper-picker" ""
    add "ecosystem" "nexus-chat" \
        "Nexus AI Chat" "Nexus Obrolan AI" \
        "Interactive AI chat launcher — select model (qwen3, deepseek-r1, qwen2.5-coder) then chat|Accessible from Nexus (Super+X → AI Chat) or terminal" \
        "Peluncur obrolan AI interaktif — pilih model (qwen3, deepseek-r1, qwen2.5-coder) lalu chat|Akses dari Nexus (Super+X → AI Chat) atau terminal" \
        "nexus-chat" "ollama"
    add "ecosystem" "post-install" \
        "Post-Install Wizard" "Wizard Pasca-Instalasi" \
        "First-boot setup wizard: sync dotfiles, set wallpaper, verify ecosystem|Runs automatically after first install, or invoke manually" \
        "Wizard setup pertama: sinkron dotfiles, atur wallpaper, verifikasi ekosistem|Berjalan otomatis setelah install pertama, atau panggil manual" \
        "post-install" ""

    echo -e "$data"
}

# ─── Preview (for fzf pane) ──────────────────────────────
generate_preview() {
    local line="$1"
    local cmd=$(echo "$line" | cut -d'|' -f2)
    local desc=$(echo "$line" | cut -d'|' -f3)
    local detail=$(echo "$line" | cut -d'|' -f4)
    local exe=$(echo "$line" | cut -d'|' -f5)
    
    echo -e "\033[1;38;2;203;166;247m━━━ $cmd ━━━\033[0m"
    echo ""
    echo -e "\033[38;2;166;227;161m  $desc\033[0m"
    echo ""
    if [ -n "$detail" ]; then
        echo "$detail" | tr '|' '\n' | while read -r l; do
            echo -e "  \033[38;2;205;214;244m$l\033[0m"
        done; echo ""
    fi
    if [ -n "$exe" ]; then
        echo -e "\033[1;38;2;137;180;250m  ⏎ Enter = $(desc 'Execute' 'Jalankan'):\033[0m"
        echo -e "  \033[38;2;249;226;175m\$ $exe\033[0m"
    else
        echo -e "  \033[38;2;108;112;134m  ($(desc 'keyboard shortcut — not executable' 'shortcut keyboard — tidak bisa dieksekusi'))\033[0m"
    fi
}

# ─── Keyword search display ─────────────────────────────
display_results() {
    local keyword="$1"
    local data="$2"
    local results=$(echo -e "$data" | grep -i "$keyword")
    
    if [ -z "$results" ]; then
        echo -e "${C_MAUVE}$(desc "No results for" "Tidak ada hasil untuk") '${BOLD}$keyword${NC}${C_MAUVE}'.${NC}"
        echo -e "${C_DIM}$(desc "Try: guide docker, guide flutter, guide ai" "Coba: guide docker, guide flutter, guide ai")${NC}"
        echo -e "${C_TEAL}$(desc "Or web:" "Atau web:") ${BOLD}guide --web $keyword${NC}"
        return
    fi
    
    echo -e "${C_MAUVE}━━━ Guide: ${BOLD}$keyword${NC} ${C_MAUVE}━━━  [$(desc 'lang: English' 'bahasa: Indonesia')]${NC}"
    echo ""
    echo "$results" | while IFS='|' read -r cat cmd d detail exe; do
        local ri=""
        [ -n "$exe" ] && ri="${C_TEAL}▶${NC} "
        echo -e "  ${C_BLUE}[$cat]${NC} ${ri}${BOLD}$cmd${NC}"
        echo -e "         ${C_GREEN}→ $d${NC}"
        [ -n "$detail" ] && echo -e "         ${C_DIM}$(echo "$detail" | cut -d'|' -f1)${NC}"
        echo ""
    done
}

# ─── Rofi popup ──────────────────────────────────────────
popup_mode() {
    local data=$(build_guide_data)
    local entries=""
    while IFS='|' read -r cat cmd d detail exe; do
        [ -z "$cat" ] && continue
        local icon="  "
        [ -n "$exe" ] && icon="▶ "
        entries+="[$cat] ${icon}$cmd → $d\n"
    done <<< "$(echo -e "$data")"
    
    local chosen
    chosen=$(echo -e "$entries" | sed '/^$/d' | rofi -dmenu -i \
        -p " Guide" \
        -theme-str "
            * { font: \"JetBrainsMono Nerd Font 11\"; }
            window { width: 520px; border: 2px; border-color: #89b4fa; border-radius: 16px; background-color: #1e1e2e; location: center; }
            mainbox { background-color: transparent; }
            inputbar { background-color: #313244; border-radius: 12px; padding: 10px 16px; margin: 12px; }
            prompt { background-color: transparent; text-color: #89b4fa; font: \"JetBrainsMono Nerd Font Bold 13\"; }
            textbox-prompt-colon { str: \"\"; background-color: transparent; }
            entry { background-color: transparent; text-color: #cdd6f4; placeholder: \"$(desc 'Search guide...' 'Cari panduan...')\"; placeholder-color: #6c7086; }
            listview { columns: 1; lines: 14; scrollbar: false; background-color: transparent; padding: 0 8px 8px; }
            element { padding: 6px 16px; border-radius: 10px; background-color: transparent; text-color: #cdd6f4; }
            element selected { background-color: #313244; text-color: #89b4fa; }
            element-text { background-color: transparent; text-color: inherit; }
        ")
    
    if [ -n "$chosen" ]; then
        local search_cmd=$(echo "$chosen" | sed 's/^\[.*\] //' | sed 's/^[▶ ]*//' | sed 's/ →.*//')
        local match=$(echo -e "$data" | grep -F "$search_cmd" | head -1)
        local exe=$(echo "$match" | cut -d'|' -f5)
        [ -n "$exe" ] && kitty --hold -e bash -c "$exe" &
    fi
}

# ─── cheat.sh ────────────────────────────────────────────
web_query() {
    local query="$*"
    echo -e "${C_MAUVE}━━━ cheat.sh: ${BOLD}$query${NC} ${C_MAUVE}━━━${NC}"
    echo ""
    curl -s "cheat.sh/${query// /+}?style=monokai" 2>/dev/null || \
        echo -e "${C_RED}$(desc 'Failed to reach cheat.sh' 'Gagal menghubungi cheat.sh')${NC}"
}

# ─── Main ─────────────────────────────────────────────────
main() {
    # Parse language flag
    if [[ "${1:-}" == "--lang" ]]; then
        GUIDE_LANG="${2:-en}"
        mkdir -p "$(dirname "$LANG_FILE")"
        echo "$GUIDE_LANG" > "$LANG_FILE"
        echo -e "${C_GREEN}✓ $(desc "Language set to: English" "Bahasa diset ke: Indonesia")${NC}"
        shift 2
        [ -z "${1:-}" ] && return
    fi

    case "${1:-}" in
        --popup|-p)  popup_mode; return ;;
        --web|-w)    shift; web_query "$@"; return ;;
        --help|-h)
            echo -e "${C_MAUVE}${BOLD}Guide v3${NC} — $(desc 'Bilingual Interactive Reference' 'Referensi Interaktif Dwibahasa')"
            echo ""
            echo -e "  ${BOLD}guide${NC}                 $(desc 'Interactive fzf (preview + execute)' 'fzf interaktif (preview + eksekusi)')"
            echo -e "  ${BOLD}guide <keyword>${NC}       $(desc 'Filter by keyword' 'Filter berdasarkan kata kunci')"
            echo -e "  ${BOLD}guide --popup${NC}         $(desc 'Rofi popup mode' 'Mode popup Rofi')"
            echo -e "  ${BOLD}guide --web <q>${NC}       $(desc 'Query cheat.sh' 'Query cheat.sh')"
            echo -e "  ${BOLD}guide --lang id${NC}       $(desc 'Switch to Indonesian' 'Beralih ke Bahasa Indonesia')"
            echo -e "  ${BOLD}guide --lang en${NC}       $(desc 'Switch to English' 'Beralih ke Bahasa Inggris')"
            echo ""
            echo -e "  ${C_DIM}$(desc 'Current language' 'Bahasa saat ini'): ${BOLD}$([ "$GUIDE_LANG" = "id" ] && echo "Indonesia" || echo "English")${NC}"
            return ;;
    esac

    local data=$(build_guide_data)

    if [ -z "${1:-}" ]; then
        # Interactive fzf
        if command -v fzf &>/dev/null; then
            local preview_script=$(mktemp /tmp/guide-preview-XXXX.sh)
            declare -f desc > "$preview_script"
            echo "GUIDE_LANG=$GUIDE_LANG" >> "$preview_script"
            declare -f generate_preview >> "$preview_script"
            echo 'generate_preview "$1"' >> "$preview_script"
            chmod +x "$preview_script"

            local display=$(echo -e "$data" | awk -F'|' '{
                exe = ($5 != "") ? "▶ " : "  ";
                if ($1 != "") printf "[%s] %s%s → %s\n", $1, exe, $2, $3
            }')

            local chosen
            chosen=$(echo "$display" | fzf --ansi \
                --prompt="🔍 $(desc 'Guide' 'Panduan'): " \
                --header="$(desc 'Enter=Execute · Ctrl-W=cheat.sh · Esc=quit' 'Enter=Jalankan · Ctrl-W=cheat.sh · Esc=keluar')" \
                --preview="bash $preview_script \"\$(echo -e '$(echo -e "$data" | sed "s/'/'\\\\''/g")' | grep -F \"\$(echo {} | sed 's/^\[.*\] //' | sed 's/^[▶ ]*//' | sed 's/ →.*//')\" | head -1)\"" \
                --preview-window=right:50%:wrap \
                --color="bg:#1e1e2e,fg:#cdd6f4,hl:#f38ba8,bg+:#313244,fg+:#cdd6f4,hl+:#f38ba8,info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc,marker:#f5e0dc,spinner:#f5e0dc,header:#6c7086,border:#6c7086" \
                --border=rounded \
                --bind="ctrl-w:execute(echo {} | sed 's/^\[.*\] //' | sed 's/ →.*//' | xargs -I{} curl -s 'cheat.sh/{}' | less)")

            rm -f "$preview_script"

            if [ -n "$chosen" ]; then
                local search_cmd=$(echo "$chosen" | sed 's/^\[.*\] //' | sed 's/^[▶ ]*//' | sed 's/ →.*//')
                local match=$(echo -e "$data" | grep -F "$search_cmd" | head -1)
                local exe=$(echo "$match" | cut -d'|' -f5)
                if [ -n "$exe" ]; then
                    echo -e "${C_GREEN}${BOLD}$(desc 'Executing' 'Menjalankan'):${NC} $exe"
                    eval "$exe"
                else
                    echo -e "${C_DIM}($(desc 'Keyboard shortcut, not executable' 'Shortcut keyboard, tidak bisa dieksekusi'))${NC}"
                fi
            fi
        else
            echo -e "$data" | column -t -s'|' | less
        fi
    else
        display_results "$*" "$data"
    fi
}

main "$@"
