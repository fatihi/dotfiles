#!/usr/bin/env bash
# Link the dotfiles into $HOME with GNU Stow. Safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

# 1. Check dependencies
for cmd in git stow; do
  command -v "$cmd" >/dev/null || { echo "Missing $cmd: sudo zypper install $cmd" >&2; exit 1; }
done

# 2. Collect packages (every top-level folder)
packages=()
for d in */; do packages+=("${d%/}"); done

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

echo "Done."
