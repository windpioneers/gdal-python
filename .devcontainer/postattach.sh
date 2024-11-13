#!/bin/zsh

# ..Install dependencies here if required...

# Auto set up remote when pushing new branches
git config --global --add push.autoSetupRemote 1

# Allow precommit to install properly
git config --global --add safe.directory /workspace

# Install precommit hooks
pre-commit install && pre-commit install -t commit-msg
pre-commit install-hooks

# Set zsh history location
#     This is done in postAttach so it's not overridden by the oh-my-zsh devcontainer feature
#
#     We leave you to decide, but if you put this into a folder that's been mapped
#     into the container, then history will persist over container rebuilds :)
#
#     !!!IMPORTANT!!!
#     Make sure your .zsh_history file is NOT committed into your repository or docker builds,
#     as it can contain sensitive information. So in this case, you should add
#         .devcontainer/.zsh_history
#     to your .gitignore and .dockerignore files.
export HISTFILE="/workspace/.devcontainer/.zsh_history"

