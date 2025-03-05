# My dotfiles

These are my dotfiles managed with gnu stow

## Add new applications

Create a folder with the application name, for example

> ~/dotfiles/nvim

Inside there, create the directory structure for where the config files should be relative to the home directory, for example

> ~/dotfiles/nvim/.config/nvim

Back in the dotfiles directory, just run

> stow nvim

and the config will be copied into the directory.
