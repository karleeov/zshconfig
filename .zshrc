# Enable Powerlevel10k instant prompt for faster shell startup
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
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

# Add Cyberpunk-inspired plugins and themes
zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light MichaelAquilina/zsh-you-should-use

# Cyberpunk color scheme for terminal (LS_COLORS)
export LS_COLORS="di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=1;34:cd=1;34:su=0;41:sg=0;46:tw=0;42:ow=0;43"

# Keybindings for easier navigation in history
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History settings for better management and searchability
HISTSIZE=10000          
SAVEHIST=$HISTSIZE      
HISTFILE=~/.zsh_history 

setopt appendhistory sharehistory inc_append_history extended_history \
        hist_ignore_space hist_ignore_dups hist_find_no_dups hist_save_no_dups

# Aliases for convenience and cyberpunk flair
alias ls='exa --long --group-directories-first --icons --color=always'
alias vim='nvim'
alias c='clear'
alias reload='source ~/.zshrc && echo "ZSH config reloaded!"'
alias matrix='cmatrix -C cyan --bold'

# Add Git aliases for faster workflows
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias gco='git checkout'

# Shell integrations for fzf and zoxide (navigation and file search)
eval "$(fzf --completion=zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Add Powerlevel10k configuration (cyberpunk style)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Optional: Add a colorful output on startup (cyberpunk vibes)
colorscript random | lolcat

# Display system information with neon colors using neofetch
neofetch | lolcat

# Lazy-load plugins to improve startup time (optional)
zinit ice wait'0'; zinit light zsh-users/zsh-syntax-highlighting
zinit ice wait'1'; zinit light zsh-users/zsh-autosuggestions

# Profile ZSH startup time (optional, remove after optimizing)
zmodload zsh/zprof # Enable profiling at the start of .zshrc.

# Add transparency support for terminal background (WezTerm-specific)
if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
  export WEZTERM_BACKGROUND_OPACITY="0.85"
fi

# Custom function: Run matrix effect with neon colors in the background
function cyber_matrix() {
  clear && cmatrix -C cyan --bold | lolcat
}

# Custom function: Show ASCII art with neon effects (requires jp2a)
function cyber_ascii() {
  jp2a --colors "$1" | lolcat
}
