# Enable Powerlevel10k instant prompt for faster shell startup
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Homebrew setup for Linux (if installed)
if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Set Zinit directory
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add Powerlevel10k and essential plugins
zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light MichaelAquilina/zsh-you-should-use
zinit light danysk/zsh-bat
zinit light paulirish/git-open

# Snippets for common commands
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions and initialize fzf-tab
autoload -Uz compinit && compinit

# Configure fzf-tab previews
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Keybindings for easier navigation in history
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Enhanced history settings for better management and searchability
HISTSIZE=10000          # Increase history size
SAVEHIST=10000          # Save more commands in history file
HISTFILE=~/.zsh_history # History file location

setopt appendhistory sharehistory inc_append_history extended_history \
        hist_ignore_space hist_ignore_dups hist_find_no_dups hist_save_no_dups

# Interactive search in history using fzf (Ctrl+R)
bindkey '^R' fzf-history-widget

fzf-history-widget() {
  local selected=$(fc -rl 1 | fzf --height=40% --reverse --tac)
  if [ -n "$selected" ]; then
    BUFFER=${selected#* }
    CURSOR=${#BUFFER}
    zle accept-line
  fi
}

# Completion styling enhancements
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select

# Aliases for convenience and improved usability
alias ls='exa --long --group-directories-first --icons --color=always'
alias vim='nvim'
alias c='clear'
alias reload='source ~/.zshrc && echo "ZSH config reloaded!"'

# Developer-specific aliases for Git, Docker, Node.js, Java, etc.
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias gco='git checkout'
alias k='kubectl'
alias dc='docker-compose'
alias dotnet-test='dotnet test'
alias dotnet-build='dotnet build'
alias node='node'
alias nextjs='npm run dev'
alias javac='javac'
alias java-run='java Main'

# Developer-specific functions for automation and workflows
function run-node() {
  nvm use $1 && node $2 # Switch Node.js version and run a script.
}

function backup() {
  cp -r ~/Documents "/backup/Documents_$(date +%Y%m%d)" # Backup documents with timestamp.
}

# Shell integrations for fzf and zoxide (navigation and file search)
eval "$(fzf --completion=zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Initialize Starship prompt if desired (comment out if using Powerlevel10k)
# eval "$(starship init zsh)"

# Update PATH for Visual Studio Code integration 
export PATH="$PATH:/mnt/c/Users/li_sz/AppData/Local/Programs/Microsoft VS Code/bin"

# Add .NET tools to PATH (if applicable)
export PATH="$PATH:$HOME/.dotnet/tools"

# Java environment setup (adjust version as needed)
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
export PATH="$JAVA_HOME/bin:$PATH"

# Powerlevel10k configuration (ensure it's loaded)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# NVM setup for Node.js version management 
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Optional: Add a colorful output on startup (remove if not needed)
colorscript random | lolcat

# Display system information with neofetch (remove if not needed)
neofetch | lolcat

eval "$(zoxide init zsh)"

# Lazy-load plugins to improve startup time (optional)
zinit ice wait'0'; zinit light zsh-users/zsh-syntax-highlighting
zinit ice wait'1'; zinit light zsh-users/zsh-autosuggestions

# Profile ZSH startup time (optional, remove after optimizing)
zmodload zsh/zprof # Enable profiling at the start of .zshrc.
