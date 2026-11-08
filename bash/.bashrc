# Sample .bashrc for SUSE Linux
# Copyright (c) SUSE Software Solutions Germany GmbH

# There are 3 different types of shells in bash: the login shell, normal shell
# and interactive shell. Login shells read ~/.profile and interactive shells
# read ~/.bashrc; in our setup, /etc/profile sources ~/.bashrc - thus all
# settings made here will also take effect in a login shell.
#
# NOTE: It is recommended to make language settings in ~/.profile rather than
# here, since multilingual X sessions would not work properly if LANG is over-
# ridden in every subshell.

# shellcheck source=/dev/null  # optional file, not in the repo
test -s ~/.alias && . ~/.alias || true

# History: keep a lot, with timestamps, and write each command right away so
# shells running side by side (wezterm panes) don't lose each other's history
HISTSIZE=50000
HISTFILESIZE=100000
HISTTIMEFORMAT='%F %T  '
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# fzf: Ctrl+r = search history, Ctrl+t = insert a file path, Alt+c = cd into a folder
if command -v fzf >/dev/null; then
  export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border \
    --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9,fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 \
    --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6,marker:#ff79c6,spinner:#ffb86c,header:#6272a4"
  eval "$(fzf --bash)"
fi

# zoxide: "z foo" jumps to the most used folder matching foo, "zi" picks one with fzf
command -v zoxide >/dev/null && eval "$(zoxide init bash)"

# mise: puts the tool versions from mise.toml (or ~/.config/mise/config.toml) on PATH
command -v mise >/dev/null && eval "$(mise activate bash)"

# wezterm shell integration: tells wezterm the current folder (new tabs/panes
# open there) and marks where each prompt and command output starts.
# Load after anything that edits PROMPT_COMMAND.
if [ "$TERM_PROGRAM" = "WezTerm" ] && [ -r /usr/etc/profile.d/wezterm.sh ]; then
  . /usr/etc/profile.d/wezterm.sh
fi

# Machine-specific settings and secrets (not tracked in dotfiles)
# shellcheck source=/dev/null  # optional file, not in the repo
test -s ~/.bashrc.local && . ~/.bashrc.local || true
