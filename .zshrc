# Enable Powerlevel10k instant prompt for faster shell startup
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Performance monitoring
zmodload zsh/zprof

# Set Zinit directory
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Optimized plugin loading with turbo mode
zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit ice wait'0' lucid; zinit light zsh-users/zsh-syntax-highlighting
zinit ice wait'0' lucid; zinit light zsh-users/zsh-autosuggestions
zinit ice wait'1' lucid; zinit light Aloxaf/fzf-tab
zinit ice wait'1' lucid; zinit light MichaelAquilina/zsh-you-should-use

# Security configurations
eval "$(ssh-agent -s)" > /dev/null
export GPG_TTY=$(tty)

# Enhanced history settings
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

setopt appendhistory sharehistory inc_append_history extended_history \
       hist_ignore_space hist_ignore_dups hist_find_no_dups hist_save_no_dups \
       hist_verify hist_expire_dups_first

# Directory management
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Better completion system
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit;
else
  compinit -C;
fi

# Environment variables
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'
export MANPAGER='nvim +Man!'

# Cyberpunk color scheme for terminal
export LS_COLORS="di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=1;34:cd=1;34:su=0;41:sg=0;46:tw=0;42:ow=0;43"

# Modern CLI tool aliases
alias ls='exa --long --group-directories-first --icons --color=always'
alias cat='bat --style=plain'
alias grep='rg'
alias find='fd'
alias top='btop'
alias vim='nvim'
alias c='clear'
alias reload='source ~/.zshrc && echo "ZSH config reloaded!"'
alias matrix='cmatrix -C cyan --bold'

# Git aliases
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias gco='git checkout'
alias gl='git log --graph --oneline --decorate'
alias gd='git diff'

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Shell integrations
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(zoxide init --cmd cd zsh)"

# Terminal-specific configurations
if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
  export WEZTERM_BACKGROUND_OPACITY="0.85"
fi

if [[ $TERM_PROGRAM == "iTerm.app" ]]; then
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
fi

# Custom functions
function timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

function cyber_matrix() {
  clear && cmatrix -C cyan --bold | lolcat
}

function cyber_ascii() {
  jp2a --colors "$1" | lolcat
}

# Load Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Conditional startup effects (comment out if startup is too slow)
if [[ $TERM_PROGRAM != "vscode" ]]; then
  colorscript random | lolcat
  neofetch | lolcat
fi

# Profile ZSH startup time (comment out in production)
# zprof

    echo >> /root/.bashrc
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /root/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
