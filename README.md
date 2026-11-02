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
| `flameshot` | `.config/flameshot/flameshot.ini` (direct X11 capture, Dracula colours) |
| `picom` | `.config/picom/picom.conf` (compositor started by awesome: vsync, shadows, fades) |
| `system` | Not stowed: files copied to `/` with sudo by `install.sh` — `etc/lightdm/lightdm-gtk-greeter.conf` (Dracula login/lock screen), `etc/X11/xorg.conf.d/60-touchpad.conf` (tap to click, two-finger tap = right click, natural scrolling) |
| `locale` | `.i18n` (English language and number format, otherwise German formats; openSUSE reads it at login) |

## Setup on a new machine

```bash
sudo zypper install git stow awesome wezterm gtk3-metatheme-dracula gtk4-metatheme-dracula \
                    brightnessctl flameshot rofi NetworkManager-applet light-locker \
                    picom polkit-gnome playerctl
git clone <repo-url> ~/Projects/dotfiles
~/Projects/dotfiles/install.sh
```

`install.sh` moves any existing conflicting files to `~/.dotfiles-backup/<timestamp>/`
and then symlinks every package into `$HOME`. It also sets the dconf dark-mode
keys (`color-scheme`, `gtk-theme`) via `gsettings`, since those don't live in
files. Finally it copies everything under `system/` to the same path under `/`
(with sudo, only files that changed; the first time, the original is kept as
`*.orig`). It is safe to re-run.

Theme: Dracula everywhere (awesome, wezterm, GTK 3/4). GTK 4 / libadwaita apps
ignore theme names, so `gtk.css` imports the Dracula CSS directly.

## awesome

`rc.lua` only handles errors and loads the theme; everything else is in
`.config/awesome/modules/`:

| Module | Contents |
|--------|----------|
| `vars.lua` | terminal (wezterm), modkey, keyboard layout (`de` variant `us`), lock command and idle times, screenshot folder |
| `layouts.lua` | tile (default), tile.bottom, max, floating |
| `menu.lua` | main menu and launcher icon |
| `widgets.lua` | volume (wpctl, updated live via `pactl subscribe`), cpu, battery (`+` = charging, warns at 10% and 5%), clock with calendar popup; on-screen popups for volume, mic and brightness |
| `bar.lua` | wallpaper, tags (only those with windows, plus the current one), top bar |
| `keys.lua` | all key and mouse bindings |
| `power.lua` | rofi power menu: lock, suspend, logout, reboot, shut down (the last three ask first) |
| `rules.lua` | rules for new windows (dialogs and floating apps open centred) |
| `signals.lua` | titlebars only on floating windows/dialogs (buttons: floating, maximize, close), focus, borders (hidden for a lone tiled window, the max layout and maximized windows) |
| `autostart.lua` | `setxkbmap`, idle timers (`xset`), `light-locker`, `picom`, polkit agent (`polkit-gnome`), `nm-applet` |

Keys beyond the awesome defaults (`Mod4+F1` lists everything):

| Key | Action |
|-----|--------|
| `Mod4+p` / `Mod4+Shift+p` | rofi: apps / commands |
| Volume keys, mic mute | `wpctl` (also: click volume widget to mute, scroll to change) |
| Play/pause, next, previous | `playerctl` (any MPRIS player: browsers, Spotify, mpv) |
| Brightness keys | `brightnessctl` |
| `Mod4+Shift+q` | power menu (replaces the instant quit) |
| `Mod4+Alt+h/l` / `Mod4+Alt+k/j` | resize window: narrower/wider, shorter/taller (tiled: changes the split and the window's share of its stack) |
| `Mod4+Shift` + left-drag | resize window with the mouse (works with touchpad tap-and-drag) |
| `Mod4+Ctrl+Escape` | lock screen |
| `Print` | flameshot: select area |
| `Shift+Print` | flameshot: whole screen, saved to `~/Pictures/Screenshots` and clipboard |

Lock screen: `light-locker` hands over to the LightDM greeter. The screen blanks
after 5 minutes idle and locks 10 seconds later; it also locks on suspend and
lid close. The monitor turns off after 10 minutes.

## Day to day

- Edit files in place (`~/.bashrc` is a symlink into this repo), then commit.
- Add a new package: `mkdir foo`, move the file in at its `$HOME`-relative path,
  run `./install.sh`.
- awesome: check changes with `awesome -k` before reloading (`Mod4+Ctrl+r`);
  a broken `rc.lua` makes awesome fall back to the system default config.
- wezterm reloads its config automatically on save; check for errors with
  `wezterm show-keys >/dev/null`.
- flameshot: settings changed in its GUI are written to the same file; check
  `git diff` afterwards. Restart it (`pkill -x flameshot`) after editing the file.
- New files in a package (e.g. a new awesome module) are only linked after
  running `./install.sh` again (stow links file by file). Do this before
  reloading awesome, or the missing `require` makes it fall back to the default config.
- picom: restart after editing (`pkill -x picom`, then `Mod4+Ctrl+r`).
- Files in `system/` only take effect after running `./install.sh` again.
- Locale changes in `.i18n` apply after logging out and in.
- Manual stow from the repo root: `stow <pkg>` / `stow -D <pkg>` (`.stowrc` sets
  the target to `~` and disables folding).

## Machine-specific settings and secrets

Put them in `~/.bashrc.local`. It is sourced by `.bashrc` and never committed.
