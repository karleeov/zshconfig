# Enable Powerlevel10k instant prompt.
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

# Add Powerlevel10k and plugins
zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

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

# History settings for better management
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups hist_find_no_dups

# Completion styling enhancements
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no

# Aliases for convenience and improved usability
alias ls='exa -al --color=always --group-directories-first'
alias vim='nvim'
alias c='clear'

# Shell integrations for fzf and zoxide
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Initialize Starship prompt if desired (comment out if using Powerlevel10k)
# eval "$(starship init zsh)"

# Update PATH for Visual Studio Code integration 
export PATH="$PATH:/mnt/c/Users/li_sz/AppData/Local/Programs/Microsoft VS Code/bin"

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


