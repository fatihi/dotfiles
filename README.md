# dotfiles

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level folder is a *package* whose contents mirror `$HOME`:

| Package | Files |
|---------|-------|
| `bash`  | `.bashrc`, `.profile`, `.inputrc` |
| `git`   | `.gitconfig` |
| `awesome` | `.config/awesome/rc.lua` + `modules/` (see below), `.config/awesome/themes/theme.lua` (Dracula) |
| `wezterm` | `.config/wezterm/wezterm.lua` (font, Dracula colours, tab bar) |
| `gtk`   | `.config/gtk-3.0/settings.ini`, `.config/gtk-4.0/settings.ini`, `.config/gtk-4.0/gtk.css` (Dracula, dark mode) |
| `rofi`  | `.config/rofi/config.rasi`, `.config/rofi/themes/dracula.rasi` (app launcher) |
| `locale` | `.i18n` (English language and number format, otherwise German formats; openSUSE reads it at login) |

## Setup on a new machine

```bash
sudo zypper install git stow awesome wezterm gtk3-metatheme-dracula gtk4-metatheme-dracula \
                    brightnessctl flameshot rofi NetworkManager-applet
git clone <repo-url> ~/Projects/dotfiles
~/Projects/dotfiles/install.sh
```

`install.sh` moves any existing conflicting files to `~/.dotfiles-backup/<timestamp>/`
and then symlinks every package into `$HOME`. It also sets the dconf dark-mode
keys (`color-scheme`, `gtk-theme`) via `gsettings`, since those don't live in
files. It is safe to re-run.

Theme: Dracula everywhere (awesome, wezterm, GTK 3/4). GTK 4 / libadwaita apps
ignore theme names, so `gtk.css` imports the Dracula CSS directly.

## awesome

`rc.lua` only handles errors and loads the theme; everything else is in
`.config/awesome/modules/`:

| Module | Contents |
|--------|----------|
| `vars.lua` | terminal (wezterm), modkey, keyboard layout (`de` variant `us`), screenshot folder |
| `layouts.lua` | tile (default), tile.bottom, max, floating |
| `menu.lua` | main menu and launcher icon |
| `widgets.lua` | volume (wpctl), cpu, battery, clock with calendar popup |
| `bar.lua` | wallpaper, tags, top bar |
| `keys.lua` | all key and mouse bindings |
| `rules.lua` | rules for new windows |
| `signals.lua` | titlebars only on floating windows/dialogs, focus, borders |
| `autostart.lua` | `setxkbmap`, `nm-applet` |

Keys beyond the awesome defaults (`Mod4+F1` lists everything):

| Key | Action |
|-----|--------|
| `Mod4+p` / `Mod4+Shift+p` | rofi: apps / commands |
| Volume keys, mic mute | `wpctl` (also: click volume widget to mute, scroll to change) |
| Brightness keys | `brightnessctl` |
| `Print` | flameshot: select area |
| `Shift+Print` | flameshot: whole screen, saved to `~/Pictures/Screenshots` and clipboard |

## Day to day

- Edit files in place (`~/.bashrc` is a symlink into this repo), then commit.
- Add a new package: `mkdir foo`, move the file in at its `$HOME`-relative path,
  run `./install.sh`.
- awesome: check changes with `awesome -k` before reloading (`Mod4+Ctrl+r`);
  a broken `rc.lua` makes awesome fall back to the system default config.
- wezterm reloads its config automatically on save; check for errors with
  `wezterm show-keys >/dev/null`.
- Locale changes in `.i18n` apply after logging out and in.
- Manual stow from the repo root: `stow <pkg>` / `stow -D <pkg>` (`.stowrc` sets
  the target to `~` and disables folding).

## Machine-specific settings and secrets

Put them in `~/.bashrc.local`. It is sourced by `.bashrc` and never committed.
