# dotfiles

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level folder is a *package* whose contents mirror `$HOME`:

| Package | Files |
|---------|-------|
| `bash`  | `.bashrc`, `.profile`, `.inputrc` |
| `git`   | `.gitconfig` |

## Setup on a new machine

```bash
sudo zypper install git stow
git clone <repo-url> ~/Projects/dotfiles
~/Projects/dotfiles/install.sh
```

`install.sh` moves any existing conflicting files to `~/.dotfiles-backup/<timestamp>/`
and then symlinks every package into `$HOME`. It is safe to re-run.

## Day to day

- Edit files in place (`~/.bashrc` is a symlink into this repo), then commit.
- Add a new package: `mkdir foo`, move the file in at its `$HOME`-relative path,
  run `./install.sh`.
- Manual stow from the repo root: `stow <pkg>` / `stow -D <pkg>` (`.stowrc` sets
  the target to `~` and disables folding).

## Machine-specific settings and secrets

Put them in `~/.bashrc.local`. It is sourced by `.bashrc` and never committed.
