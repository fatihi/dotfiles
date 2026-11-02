#!/usr/bin/env bash
# Link the dotfiles into $HOME with GNU Stow. Safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

# 1. Check dependencies
for cmd in git stow; do
  command -v "$cmd" >/dev/null || { echo "Missing $cmd: sudo zypper install $cmd" >&2; exit 1; }
done

# Packages the configs use. Missing ones are only reported (the links still work,
# but e.g. awesome falls back to its default config without vicious/freedesktop).
required_pkgs=(
  awesome awesome-vicious awesome-freedesktop   # window manager + bar widgets + menu
  wezterm rofi flameshot picom                  # terminal, launcher, screenshots, compositor
  light-locker polkit-gnome NetworkManager-applet autorandr arandr
  brightnessctl playerctl wireplumber pulseaudio-utils   # brightness, media, wpctl, pactl
  gtk3-metatheme-dracula gtk4-metatheme-dracula
)
missing_pkgs=()
for p in "${required_pkgs[@]}"; do
  rpm -q "$p" >/dev/null 2>&1 || missing_pkgs+=("$p")
done
if (( ${#missing_pkgs[@]} )); then
  echo "Missing packages, install with:" >&2
  echo "  sudo zypper install ${missing_pkgs[*]}" >&2
fi

# 2. Collect packages (every top-level folder except system/, see step 7)
packages=()
for d in */; do
  [[ "$d" == "system/" ]] && continue
  packages+=("${d%/}")
done

# 3. Back up real files that would conflict, so stow doesn't abort
backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
for pkg in "${packages[@]}"; do
  while IFS= read -r -d '' f; do
    rel="${f#"$pkg"/}"
    target="$HOME/$rel"
    if [[ -e "$target" && ! -L "$target" ]]; then
      mkdir -p "$backup/$(dirname "$rel")"
      mv "$target" "$backup/$rel"
      echo "Backed up ~/$rel -> $backup/$rel"
    fi
  done < <(find "$pkg" -type f -print0)
done

# 4. Link (restow = clean up stale links, then relink)
stow --restow --no-folding --target="$HOME" "${packages[@]}"

# 5. Create local, untracked override files
[[ -e "$HOME/.bashrc.local" ]] || touch "$HOME/.bashrc.local"

# 6. Dark mode for apps that read dconf instead of files (libadwaita, Firefox)
if command -v gsettings >/dev/null; then
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  gsettings set org.gnome.desktop.interface gtk-theme 'dracula-gtk-theme'
fi

# 7. System files outside $HOME: system/etc/foo is copied to /etc/foo.
#    Uses sudo, and only for files that differ. The original is kept as *.orig.
if [[ -d system ]]; then
  while IFS= read -r -d '' f; do
    dst="/${f#system/}"
    cmp -s "$f" "$dst" && continue
    echo "Installing $dst (needs sudo)"
    if [[ -e "$dst" && ! -e "$dst.orig" ]]; then
      sudo cp -p "$dst" "$dst.orig"
    fi
    sudo install -D -m 644 "$f" "$dst"
  done < <(find system -type f -print0)
fi

echo "Done."
