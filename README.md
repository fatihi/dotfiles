# dotfiles

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level folder is a *package* whose contents mirror `$HOME`:

| Package | Files |
|---------|-------|
| `bash`  | `.bashrc`, `.profile`, `.inputrc` |
| `git`   | `.gitconfig` |
| `awesome` | `.config/awesome/rc.lua` (based on the awesome 4.3 default; terminal: wezterm), `.config/awesome/themes/theme.lua` (Dracula) |
| `wezterm` | `.config/wezterm/wezterm.lua` (font, Dracula colours, tab bar) |
| `gtk`   | `.config/gtk-3.0/settings.ini`, `.config/gtk-4.0/settings.ini`, `.config/gtk-4.0/gtk.css` (Dracula, dark mode) |

## Setup on a new machine

```bash
sudo zypper install git stow awesome wezterm gtk3-metatheme-dracula gtk4-metatheme-dracula
git clone <repo-url> ~/Projects/dotfiles
~/Projects/dotfiles/install.sh
```

`install.sh` moves any existing conflicting files to `~/.dotfiles-backup/<timestamp>/`
and then symlinks every package into `$HOME`. It also sets the dconf dark-mode
keys (`color-scheme`, `gtk-theme`) via `gsettings`, since those don't live in
files. It is safe to re-run.

Theme: Dracula everywhere (awesome, wezterm, GTK 3/4). GTK 4 / libadwaita apps
ignore theme names, so `gtk.css` imports the Dracula CSS directly.

## Day to day

- Edit files in place (`~/.bashrc` is a symlink into this repo), then commit.
- Add a new package: `mkdir foo`, move the file in at its `$HOME`-relative path,
  run `./install.sh`.
- awesome: check changes with `awesome -k` before reloading (`Mod4+Ctrl+r`);
  a broken `rc.lua` makes awesome fall back to the system default config.
- wezterm reloads its config automatically on save; check for errors with
  `wezterm show-keys >/dev/null`.
- Manual stow from the repo root: `stow <pkg>` / `stow -D <pkg>` (`.stowrc` sets
  the target to `~` and disables folding).

## Machine-specific settings and secrets

Put them in `~/.bashrc.local`. It is sourced by `.bashrc` and never committed.
