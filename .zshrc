# Path configuration
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Oh My Zsh installation path (if installed)
export ZSH="$HOME/.oh-my-zsh"

# Use a basic theme that comes with Oh My Zsh by default
ZSH_THEME="robbins"

# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Basic Oh My Zsh plugins that are included by default
if [ -d "$ZSH" ]; then
  plugins=(
    git
    sudo
    history
    command-not-found
    zsh-autosuggestions
    zsh-syntax-highlighting
  )
  
  # Load Oh My Zsh if it exists
  source $ZSH/oh-my-zsh.sh
else
  # Basic zsh settings if Oh My Zsh is not installed
  autoload -Uz compinit
  compinit
  
  # Basic prompt
  PS1='%n@%m:%~$ '
  
  # Basic command completion
  zstyle ':completion:*' menu select
  zstyle ':completion:*' completer _expand _complete _ignored
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
fi

# User configuration
export LANG=en_US.UTF-8
export EDITOR='vim'
export VISUAL='vim'
export PAGER='less'

# WSL-specific configurations
if grep -q "microsoft" /proc/version &>/dev/null; then
  # Windows integration
  # Access Windows executables from WSL
  export PATH=$PATH:/mnt/c/Windows:/mnt/c/Windows/System32:/mnt/c/Windows/System32/WindowsPowerShell/v1.0/
  
  # Define functions to open Windows applications
  function explorer() {
    explorer.exe ${1:-.}
  }
  
  # Open browser from WSL
  function open() {
    if [ $# -eq 0 ]; then
      explorer.exe .
    else
      if [[ "$1" =~ ^https?:// ]]; then
        cmd.exe /c start "$1" >/dev/null 2>&1
      else
        local path=$(wslpath -w "$1")
        cmd.exe /c start "" "$path" >/dev/null 2>&1
      fi
    fi
  }
  
  # WSL-specific aliases
  alias winget="powershell.exe winget"
  alias pwsh="powershell.exe"
  alias cmd="cmd.exe /c"
fi

# Basic aliases
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias reload='source ~/.zshrc && echo "ZSH config reloaded!"'

# Git aliases (only if git is installed)
if command -v git &> /dev/null; then
  alias gs='git status'
  alias gc='git commit -m'
  alias gp='git push'
  alias gco='git checkout'
  alias gl='git log --graph --oneline --decorate'
  alias gd='git diff'
fi

# Node.js environment (only if installed)
if command -v node &> /dev/null; then
  # Node.js version management (if nvm is installed)
  if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  fi
fi

# Python environment (only if pyenv is installed)
if command -v pyenv &> /dev/null; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

# .NET Core development (only if installed)
if command -v dotnet &> /dev/null; then
  export DOTNET_CLI_TELEMETRY_OPTOUT=1
  export DOTNET_ROOT=$HOME/.dotnet
  export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
fi
