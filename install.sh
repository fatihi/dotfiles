#!/usr/bin/env bash
# Link the dotfiles into $HOME with GNU Stow. Safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

# 1. Check dependencies
for cmd in git stow; do
  command -v "$cmd" >/dev/null || {
    echo "Missing $cmd: sudo zypper install $cmd" >&2
    exit 1
  }
done

# Packages the configs use (checked by what they provide, so "npm" is met by
# e.g. npm26). Missing ones are only reported (the links still work,
# but e.g. awesome falls back to its default config without vicious/freedesktop).
required_pkgs=(
  awesome awesome-vicious awesome-freedesktop                      # window manager + bar widgets + menu
  wezterm rofi flameshot picom                                     # terminal, launcher, screenshots, compositor
  nerdfonts-symbolsonly-fonts                                      # current Nerd Font icons for wezterm/Neovim
  light-locker polkit-gnome NetworkManager-applet autorandr arandr # screen lock, polkit agent, network tray, monitor setup
  brightnessctl playerctl wireplumber pulseaudio-utils             # brightness, media, wpctl, pactl
  gtk3-metatheme-dracula gtk4-metatheme-dracula                    # GTK themes
  fzf zoxide                                                       # fuzzy finder, smart cd (bash)
  neovim ripgrep fd gcc tree-sitter xclip                          # editor, its search tools, treesitter parser builds, clipboard
  lazygit                                                          # git UI (also inside neovim)
  npm                                                              # Node.js, for the JSON/YAML language servers mason installs
  rustup                                                           # Rust toolchain (cargo, rustfmt, clippy, rust-analyzer for Neovim)
  clang                                                            # Odin links with clang (Odin itself comes from mise, step 5c)
  docker docker-compose docker-buildx                              # containers (daemon enabled and user added to the docker group in step 5d)
)
missing_pkgs=()
for p in "${required_pkgs[@]}"; do
  rpm -q --whatprovides "$p" >/dev/null 2>&1 || missing_pkgs+=("$p")
done
if ((${#missing_pkgs[@]})); then
  echo "Missing packages: ${missing_pkgs[*]}" >&2
  # Ask before installing (only when run from a terminal); otherwise just report
  answer=n
  if [[ -t 0 ]]; then
    read -rp "Install them now with sudo zypper install? [Y/n] " answer
    answer="${answer:-y}"
  fi
  if [[ "$answer" == [Yy]* ]]; then
    sudo zypper install "${missing_pkgs[@]}" || echo "zypper failed; continuing without them" >&2
  else
    echo "Install later with:" >&2
    echo "  sudo zypper install ${missing_pkgs[*]}" >&2
  fi
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

# 5b. German spell dictionary for Neovim (spelllang = en,de), from the
#     server Neovim itself downloads missing ones from
spell_dir="$HOME/.local/share/nvim/site/spell"
if [[ ! -e "$spell_dir/de.utf-8.spl" ]] && command -v curl >/dev/null; then
  mkdir -p "$spell_dir"
  for f in de.utf-8.spl de.utf-8.sug; do
    curl -fsSL -o "$spell_dir/$f" "https://ftp.nluug.nl/pub/vim/runtime/spell/$f" ||
      echo "Could not download the Neovim spell file $f" >&2
  done
fi

# 5b2. rust-analyzer for Neovim (rustaceanvim), from rustup so it matches the toolchain
if command -v rustup >/dev/null && ! rustup component list --installed 2>/dev/null | grep -q '^rust-analyzer'; then
  echo "Installing rust-analyzer with rustup"
  rustup component add rust-analyzer clippy rustfmt || echo "Could not install rust-analyzer" >&2
fi

# 5c. mise (tool version manager; not in the openSUSE repos), installed to
#     ~/.local/bin/mise with the official installer. Update with "mise self-update".
if ! command -v mise >/dev/null && [[ ! -x "$HOME/.local/bin/mise" ]] && command -v curl >/dev/null; then
  echo "Installing mise to ~/.local/bin/mise"
  curl -fsSL https://mise.run | sh || echo "Could not install mise" >&2
fi
# Install the global tools from ~/.config/mise/config.toml (Odin; not in the openSUSE repos)
mise_bin="$(command -v mise || echo "$HOME/.local/bin/mise")"
if [[ -x "$mise_bin" ]]; then
  "$mise_bin" install --yes || echo "Could not install the mise tools" >&2
fi

# 5d. Docker: start the daemon at boot and let the user run docker without sudo.
#     Membership in the docker group is root-equivalent; it applies after logging in again.
if rpm -q docker >/dev/null 2>&1; then
  if ! systemctl is-enabled --quiet docker; then
    echo "Enabling the Docker daemon (needs sudo)"
    sudo systemctl enable --now docker
  fi
  if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    echo "Adding $USER to the docker group (needs sudo; log out and back in afterwards)"
    sudo usermod -aG docker "$USER"
  fi
fi

# 6. Dark mode and cursor for apps that read dconf instead of files (libadwaita, Firefox)
if command -v gsettings >/dev/null; then
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  gsettings set org.gnome.desktop.interface gtk-theme 'dracula-gtk-theme'
  gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
  gsettings set org.gnome.desktop.interface cursor-size 24
fi

# 6b. Cursor theme for the running X session (normally loaded at login)
if [[ -n "${DISPLAY:-}" ]] && command -v xrdb >/dev/null; then
  xrdb -merge "$HOME/.Xresources"
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
