#!/bin/zsh

# ..Install dependencies here if required...


# Install precommit hooks
pre-commit install && pre-commit install -t commit-msg
