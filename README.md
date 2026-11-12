# dotfiles

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level folder is a *package* whose contents mirror `$HOME`:

| Package | Files |
|---------|-------|
| `bash`  | `.bashrc` (big shared history, fzf, zoxide, mise, wezterm shell integration), `.profile` (`EDITOR=nvim`), `.inputrc` (case-insensitive completion, Up/Down prefix history search) |
| `git`   | `.gitconfig` (user, `main` default branch, ff-only pull, auto upstream on push, zdiff3 conflicts, rerere) |
| `awesome` | `.config/awesome/rc.lua` + `modules/` (see below), `.config/awesome/themes/theme.lua` (Dracula) |
| `wezterm` | `.config/wezterm/wezterm.lua` (font with current Nerd Font icons, Dracula colours, tab bar with leader/copy/search/resize mode indicator, visual bell, dimmed inactive panes, pane/tab keys on `Ctrl+a` leader incl. resize mode (`Ctrl+a r`, then `h/j/k/l` or arrows, Shift = bigger steps, Esc/Enter/q leaves), copy mode, search, quick select, pane picker/swap, tab moving; `Ctrl+h/j/k/l` / `Alt+h/j/k/l` move between / resize panes, handed to Neovim when it runs in the pane; links open on Ctrl+click) |
| `nvim` | `.config/nvim/` (see [Neovim](#neovim) below) |
| `mise` | `.config/mise/config.toml` (global tool versions, empty for now; projects pin their own in `mise.toml`) |
| `lazygit` | `.config/lazygit/config.yml` (Dracula colours; `e` opens the file in the surrounding Neovim) |
| `gtk`   | `.config/gtk-3.0/settings.ini`, `.config/gtk-4.0/settings.ini`, `.config/gtk-4.0/gtk.css` (Dracula, dark mode) |
| `rofi`  | `.config/rofi/config.rasi`, `.config/rofi/themes/dracula.rasi` (app launcher) |
| `flameshot` | `.config/flameshot/flameshot.ini` (direct X11 capture, Dracula colours) |
| `picom` | `.config/picom/picom.conf` (compositor started by awesome: vsync, shadows, fades) |
| `system` | Not stowed: files copied to `/` with sudo by `install.sh` — `etc/lightdm/lightdm-gtk-greeter.conf` (Dracula login/lock screen), `etc/X11/xorg.conf.d/60-touchpad.conf` (tap to click, two-finger tap = right click, natural scrolling) |
| `locale` | `.i18n` (English language and number format, otherwise German formats; openSUSE reads it at login) |

## Setup on a new machine

```bash
sudo zypper install git stow awesome awesome-vicious awesome-freedesktop \
                    wezterm rofi flameshot picom light-locker polkit-gnome NetworkManager-applet autorandr arandr \
                    brightnessctl playerctl wireplumber pulseaudio-utils \
                    gtk3-metatheme-dracula gtk4-metatheme-dracula fzf zoxide \
                    neovim ripgrep fd gcc tree-sitter xclip lazygit nerdfonts-symbolsonly-fonts npm
git clone <repo-url> ~/Projects/dotfiles
~/Projects/dotfiles/install.sh
```

`install.sh` first lists any of these packages that are missing (the list is
`required_pkgs` in the script; keep it in sync with the command above). It then moves any existing conflicting files to `~/.dotfiles-backup/<timestamp>/`
and then symlinks every package into `$HOME`. It also sets the dconf dark-mode
keys (`color-scheme`, `gtk-theme`) via `gsettings`, since those don't live in
files. Finally it copies everything under `system/` to the same path under `/`
(with sudo, only files that changed; the first time, the original is kept as
`*.orig`). If `mise` is missing it installs it to `~/.local/bin/mise` with the
official installer (`curl https://mise.run | sh`; it isn't in the openSUSE repos),
and it downloads Neovim's German spell files. It is safe to re-run.

Theme: Dracula everywhere (awesome, wezterm, Neovim, lazygit, GTK 3/4). GTK 4 / libadwaita apps
ignore theme names, so `gtk.css` imports the Dracula CSS directly.

## awesome

`rc.lua` only handles errors and loads the theme; everything else is in
`.config/awesome/modules/`:

| Module | Contents |
|--------|----------|
| `vars.lua` | terminal (wezterm), modkey, keyboard layout (`de` variant `us`), lock command and idle times, screenshot folder |
| `scaling.lua` | size of awesome's own UI per screen: measures each monitor's real DPI and uses 96/120/144 (the 14" 1920x1200 panel gets 1.25x); the bar, gaps and borders follow each screen (rescaled when a monitor changes resolution), menus/notifications/titlebars use the highest; apps are not affected |
| `layouts.lua` | tile (default), tile.bottom, max, floating |
| `menu.lua` | main menu and launcher icon |
| `widgets.lua` | volume (wpctl, updated live via `pactl subscribe`), cpu, battery (`+` = charging, warns at 10% and 5%; hidden on machines without one), clock with calendar popup; on-screen popups for volume, mic and brightness; do-not-disturb indicator |
| `bar.lua` | wallpaper, tags (only those with windows, plus the current one), top bar sized per screen (systray on the primary screen) |
| `keys.lua` | all key and mouse bindings |
| `keyhelp.lua` | `Mod4+F1`: searchable list of all key bindings in rofi (fuzzy search over key, description and group, best matches first; Enter runs the binding) |
| `power.lua` | rofi power menu: lock, suspend, logout, reboot, shut down (the last three ask first) |
| `rules.lua` | rules for new windows (dialogs and floating apps open centred; class/name values are Lua patterns, so escape `-` and `.` as `%-` and `%.`) |
| `signals.lua` | titlebars only on floating windows/dialogs (buttons: floating, maximize, close), focus follows the mouse (only when it actually moves, so switching tags or closing a window doesn't steal focus), windows of an unplugged monitor go to the same tag number, borders (hidden for a lone tiled window, the max layout and maximized windows) |
| `autostart.lua` | `setxkbmap`, idle timers (`xset`), `light-locker`, `autorandr --change`, `picom`, polkit agent (`polkit-gnome`), `nm-applet` |

Keys beyond the awesome defaults (`Mod4+F1` lists everything):

| Key | Action |
|-----|--------|
| `Mod4+F1` / `Mod4+Shift+F1` | search all key bindings (rofi, Enter runs one) / awesome's classic help popup |
| `Mod4+p` / `Mod4+Shift+p` | rofi: apps / commands (awesome passes `-dpi`, so rofi matches the bar's size on each screen) |
| `Mod4+h/j/k/l` | focus the window to the left / below / above / to the right (continues onto the other monitor at the edge) |
| `Mod4+Shift+h/j/k/l` | swap with the window in that direction |
| `Mod4+Shift+Tab` | rofi: switch to any window by title |
| `Mod4+Ctrl+Shift+h/l` | more / fewer master windows (master width: `Mod4+Alt+h/l`) |
| `Mod4+Shift+d` | do not disturb: hold back notifications until turned off (`dnd` in the bar; battery warnings and volume/brightness popups still show) |
| Volume keys, mic mute | `wpctl` (also: click volume widget to mute, scroll to change) |
| Play/pause, next, previous | `playerctl` (any MPRIS player: browsers, Spotify, mpv) |
| Brightness keys | `brightnessctl` |
| `Mod4+Shift+q` | power menu (replaces the instant quit) |
| `XF86Display` (Fn key) / `Mod4+Shift+o` | autorandr: next monitor profile / re-apply the matching one |
| `Mod4+Alt+h/l` / `Mod4+Alt+k/j` | resize window: narrower/wider, shorter/taller (tiled: changes the split and the window's share of its stack) |
| `Mod4+Shift+Left/Right` | move window to the previous/next tag and follow it |
| `Mod4+Shift` + left-drag | resize window with the mouse (works with touchpad tap-and-drag) |
| `Mod4+Ctrl+Escape` | lock screen |
| `Print` | flameshot: select area |
| `Shift+Print` | flameshot: whole screen, saved to `~/Pictures/Screenshots` and clipboard |

Monitors: `autorandr` profiles live in `~/.config/autorandr/` and are not in
this repo (they contain the monitors' EDID fingerprints). Create them once per machine:
`autorandr --save laptop` with only the built-in screen, then plug in the monitor,
arrange it with `arandr` and run `autorandr --save <name>`. autorandr's udev rule
switches profiles automatically on hotplug; awesome applies the matching one at startup.

Lock screen: `light-locker` hands over to the LightDM greeter. The screen blanks
after 5 minutes idle and locks 10 seconds later; it also locks on suspend and
lid close. The monitor turns off after 10 minutes.

## Neovim

Needs Neovim 0.12+. Plugins are managed by the built-in `vim.pack`: they are
cloned on the first start, and their versions are pinned in
`nvim-pack-lock.json` (committed). Update with `:lua vim.pack.update()`, then
commit the changed lockfile. Language servers, formatters and the Python debugger are installed by
mason (`:Mason`) on the first start, also in the background (the JSON/YAML servers
need `npm`, the Python ones and debugpy `python3`).

| File | Contents |
|------|----------|
| `init.lua` | loads the modules below in order |
| `lua/config/options.lua` | leader = Space, relative numbers, `scrolloff=8`, persistent undo, system clipboard, smart-case search, 4-space indent, treesitter folds, `splitkeep=screen`, block selections past line ends, smooth scrolling of wrapped lines, sessions without empty/terminal windows, Ctrl+o/Ctrl+i keep the scroll position (`jumpoptions=view`), spell checking in English and German (`de` dictionary downloaded by `install.sh`; camelCase words checked by part), new message/command-line UI (`ui2`: no "Press ENTER" prompts, `g<` shows earlier messages) |
| `lua/config/keymaps.lua` | general keys and toggles, built-in undo tree, `j`/`k` by screen line in wrapped text, `n`/`N` always down/up, undo steps at `,` `.` `;` in insert mode, `gco`/`gcO`, splits, restart, spell check toggle |
| `lua/config/autocmds.lua` | highlight on yank, reopen at last position, reload files changed outside, equal splits on resize (in every tab), `q` closes help/quickfix/man/checkhealth, wrap + spell check in git commits and markdown, `o`/`O` on a comment line don't continue the comment |
| `lua/config/terminal.lua` | shell split toggled with `Space t`, floating terminals (lazygit; they follow terminal resizes), `Esc Esc` and `Ctrl+h/j/k/l` inside the shell split / `:terminal` |
| `lua/config/pack.lua` | `vim.pack` helpers and post-update build steps |
| `lua/plugins/ui.lua` | snacks.picker setup (fuzzy finder, also for `vim.ui.select`; hidden files included), Dracula, lualine, which-key, indent guides, hex colour previews (mini.hipatterns), lualine shows the attached language servers, sessions (persistence; not saved when Neovim was started with files, unless a session is restored), start screen (mini.starter) |
| `lua/plugins/editor.lua` | treesitter (parsers compiled locally with gcc; a language without a parser gets one the first time such a file is opened), big-file guard (over 1 MB or minified, i.e. very long lines: filetype `bigfile`, so no treesitter, language servers, linters, indent guides or colour previews, only regex highlighting), sticky context (treesitter-context), text objects (mini.ai: function, class, if/loop, argument, function call, tag, whole buffer, number, word part), function jumps (treesitter-textobjects), surround, autopairs, buffer delete that keeps the layout (mini.bufremove), flash, smart-splits (pinned to v2, which has the WezTerm integration built in), todo-comments, search and replace in all files (grug-far), render-markdown |
| `lua/plugins/finder.lua` | picker keys (`Space f ...`), oil (in a popup on `-`), neo-tree (closed before a session is saved) |
| `lua/plugins/lsp.lua` | mason + nvim-lspconfig, `]d` / `[d` show the diagnostic in a popup, other uses of the symbol under the cursor highlighted (`]]` / `[[` jump between them), blink.cmp completion, conform (format on save with the formatters listed; language servers only format on `Space c f`, so JSON/YAML/TOML files aren't rewritten just by saving them), nvim-lint, trouble. Lua: lua_ls + stylua, lazydev (Neovim API, wezterm types). Shell: bashls (runs shellcheck) + shfmt. JSON/YAML: jsonls/yamlls with SchemaStore schemas. TOML: taplo. Python: basedpyright + ruff (lint, format, sort imports). JSON/YAML/TOML are formatted by their server (`Space c f`). **Adding a language:** add it to `servers` / `tools` / `formatters_by_ft` / `linters_by_ft` at the top |
| `lua/plugins/git.lua` | gitsigns, git pickers (changed files, commits), lazygit in a floating window |
| `lua/plugins/debug.lua` | debugger: nvim-dap, nvim-dap-view (panel with variables, watches, call stack, breakpoints, REPL; opens while debugging, values shown next to the code), nvim-dap-python (debugpy from mason; runs with the project's `venv`/`.venv`; debug the test under the cursor with pytest or unittest). Set up on the first debug key, so it costs nothing at startup. **Other languages:** add their adapter to `require("dap").adapters` |
| `.stylua.toml` | Lua formatting style. stylua only formats projects that have one, so awesome/wezterm stay as they are |

Outside `nvim/`: `awesome/.config/awesome/.luarc.json` tells lua_ls about awesome's globals and library, and the repo's `.editorconfig` sets 2-space indent for the shell scripts (Neovim and shfmt both read it).

Press `Space` and wait to see all leader keys, or `Space f k` to search every key.
The main ones:

| Key | Action |
|-----|--------|
| `Space Space` / `Space f g` / `Space f b` / `Space f r` | find files / grep / buffers / recent files |
| in a picker | type to filter, `Ctrl+j/k` move; `Esc` = browse with `j`/`k`, `gg`/`G` (`i` types again, `Esc`/`q` close); `Ctrl+s`/`Ctrl+v` open in a split, `Ctrl+q` to quickfix, `?` all keys |
| `-` / `Space e` | oil in a popup (parent folder as a buffer, `:w` applies edits, `-` goes up, `q` closes) / neo-tree sidebar |
| `s` / `S` | flash jump / select a treesitter node |
| `]f` / `[f` | next / previous function |
| `gsa` / `gsd` / `gsr` | add / delete / replace surrounding (e.g. `gsaiw"`) |
| `af` `if` / `ac` `ic` / `ao` `io` | function / class / if-or-loop text objects |
| `au` `iu` / `at` `it` / `ag` `ig` / `id` / `ie` | function call / HTML tag / whole buffer (`yag`) / number / part of a camelCase or snake_case word |
| `Ctrl+h/j/k/l` / `Alt+h/j/k/l` | move between / resize splits, continuing into wezterm panes |
| `gd` / `grr` / `grn` / `gra` / `K` | definition / references / rename / code action / hover |
| `]]` / `[[` | next / previous use of the symbol under the cursor |
| `]d` / `[d` | next / previous diagnostic (message in a popup) |
| `Space r` | search and replace in all files (grug-far; `\r` replaces all, `g?` help) |
| `Ctrl+Space` / `Ctrl+y` | open completion / accept |
| `Space c f` / `Space u f` | format / toggle format on save |
| `Space x x` / `Space x t` | diagnostics / TODOs in trouble |
| `]h` `[h` / `Space g s` / `Space g p` / `Space g b` | next/prev git hunk / stage / preview / blame |
| `Space g g` / `Space t` | lazygit / terminal split (`Esc Esc` = normal mode) |
| `Space q s` / `Space q l` / `Space q r` | restore this folder's session / the last session / restart Neovim (same windows and files) |
| `gco` / `gcO` | new comment line below / above (`o` on a comment line starts a plain line) |
| `Space -` / `Space \|` | split below / right |
| `n` / `N` | next match down / up, also after `?` |
| `Space u u` / `Space u m` / `Space u t` / `Space u s` | undo tree / toggle markdown rendering / toggle sticky context / toggle spell check |
| `Space b d` / `Space b o` | delete buffer (keeps the split) / delete all other buffers |
| `Space d b` / `Space d c` / `Space d m` | breakpoint / start debugging or continue / debug the test under the cursor (Python) |
| `F5` / `F9` / `F10` / `F11` / `Shift+F11` | continue / breakpoint / step over / into / out |
| `Space d e` / `Space d w` / `Space d u` / `Space d t` | value of the expression under the cursor / watch it / toggle the debug panel / stop |

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
- mise: `mise use -g node@lts` writes the global default into the symlinked
  `config.toml` (commit it); `mise use node@22` in a project writes its own
  `mise.toml` there. Update mise itself with `mise self-update`.
- Locale changes in `.i18n` apply after logging out and in.
- Manual stow from the repo root: `stow <pkg>` / `stow -D <pkg>` (`.stowrc` sets
  the target to `~` and disables folding).

## Machine-specific settings and secrets

Put them in `~/.bashrc.local`. It is sourced by `.bashrc` and never committed.
