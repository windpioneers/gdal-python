
# OH MY ZSH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="spaceship"

SPACESHIP_PROMPT_ORDER=(
  exec_time
  node
  dir
  git
  char
)

SPACESHIP_PROMPT_FIRST_PREFIX_SHOW="true"
SPACESHIP_PROMPT_ADD_NEWLINE="false"
SPACESHIP_PROMPT_SEPARATE_LINE="false"
SPACESHIP_CHAR_SYMBOL="$ "
SPACESHIP_CHAR_COLOR_SUCCESS="white"
SPACESHIP_USER_SHOW="never"
SPACESHIP_USER_PREFIX=""
SPACESHIP_USER_COLOR="green"
SPACESHIP_USER_SUFFIX=""
SPACESHIP_HOST_SHOW="never"
SPACESHIP_HOST_PREFIX="@"
SPACESHIP_HOST_SUFFIX=""
SPACESHIP_HOST_COLOR="red"
SPACESHIP_DIR_PREFIX=":"
SPACESHIP_DIR_SUFFIX=""
SPACESHIP_DIR_TRUNC="0"
SPACESHIP_DIR_TRUNC_REPO="true"
SPACESHIP_DIR_COLOR="blue"
SPACESHIP_GIT_PREFIX=" "
SPACESHIP_GIT_BRANCH_PREFIX=""
SPACESHIP_GIT_BRANCH_COLOR="green"
SPACESHIP_PYTHON_SYMBOL=""
SPACESHIP_PYTHON_PREFIX=""
SPACESHIP_PYTHON_SUFFIX=" "
SPACESHIP_PYTHON_SYMBOL="py v"
SPACESHIP_PYTHON_COLOR="magenta"
SPACESHIP_EXEC_TIME_PREFIX="Took "
SPACESHIP_EXEC_TIME_SUFFIX="\n"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  git-prompt
  history
  python
)

source $ZSH/oh-my-zsh.sh


# GIT ALIASES
echo "Spaceship symbols are at https://github.com/spaceship-prompt/spaceship-prompt"
echo "Git aliases are at https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git"
