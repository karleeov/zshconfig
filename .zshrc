# ~/.zshrc — managed by zshconfig repo. Re-deploy after editing: ./deploy.sh

# ── Zinit ────────────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# ── Plugins (turbo mode) ─────────────────────────────────────────────
# zsh-syntax-highlighting LAST: wraps widgets defined by earlier plugins
zinit ice depth=1 wait'0' lucid; zinit light zsh-users/zsh-autosuggestions
zinit ice depth=1 wait'0' lucid; zinit light zsh-users/zsh-history-substring-search
zinit ice depth=1 wait'1' lucid; zinit light Aloxaf/fzf-tab
zinit ice depth=1 wait'1' lucid; zinit light MichaelAquilina/zsh-you-should-use
zinit ice depth=1 wait'2' lucid; zinit light zsh-users/zsh-syntax-highlighting

# ── History ──────────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt appendhistory sharehistory inc_append_history extended_history \
       hist_ignore_space hist_ignore_dups hist_find_no_dups hist_save_no_dups \
       hist_verify hist_expire_dups_first

# ── Directories ──────────────────────────────────────────────────────
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

# ── Completion ───────────────────────────────────────────────────────
autoload -Uz compinit
_zdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n ${~_zdump}(#qN.mh+24) ]]; then
  compinit          # dump older than 24h: full security-checked rebuild
else
  compinit -C       # fresh dump: fast path
fi

# ── Environment ──────────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'
export MANPAGER='nvim +Man!'
export LS_COLORS="di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=1;34:cd=1;34:su=0;41:sg=0;46:tw=0;42:ow=0;43"

# Homebrew (guarded — never writes to other rc files)
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
fi

# ── ssh-agent: reuse one instance across shells ──────────────────────
SSH_ENV="$HOME/.cache/ssh-agent.env"
mkdir -p "$HOME/.cache"
if [[ -r "$SSH_ENV" ]]; then
  source "$SSH_ENV" > /dev/null
fi
ssh-add -l &> /dev/null
if (( $? == 2 )); then   # 2 = no agent reachable
  ssh-agent -s > "$SSH_ENV"
  source "$SSH_ENV" > /dev/null
fi
export GPG_TTY="$(tty)"

# ── Aliases ──────────────────────────────────────────────────────────
alias ls='eza --long --group-directories-first --icons --color=always'
alias cat='bat --style=plain'
alias grep='rg'
alias find='fd'
alias top='btop'
alias vim='nvim'
alias c='clear'
alias reload='source ~/.zshrc && echo "ZSH config reloaded!"'
alias matrix='cmatrix -C cyan --bold'
alias fetch='fastfetch | lolcat'

# Git
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias gco='git checkout'
alias gl='git log --graph --oneline --decorate'
alias gd='git diff'

# ── Keybindings ──────────────────────────────────────────────────────
bindkey -e
autoload -Uz history-substring-search-up history-substring-search-down
zle -N history-substring-search-up
zle -N history-substring-search-down
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ── Pentest toolkit (installed by: zsc pentest) ─────────────────────
[[ -d "$HOME/go/bin" ]] && export PATH="$HOME/go/bin:$PATH"
[[ -d "$HOME/.local/go/bin" ]] && export PATH="$HOME/.local/go/bin:$PATH"
export HACKTOOLS_DIR="${HOME}/tools"   # resolvers + wordlists from pentest.sh

# One-shot external recon pipeline: passive+brute subs -> resolve -> probe
function recon() {
  [[ -z ${1:-} ]] && { echo "usage: recon example.com"; return 1; }
  local d=$1 res="$HACKTOOLS_DIR/lists/resolvers-trickest.txt"
  local out="$HOME/hacks/$d-$(date +%Y%m%d-%H%M%S)"
  [[ -r $res ]] || { echo "missing $res — run: zsc pentest"; return 1; }
  mkdir -p "$out"
  echo "[1/4] subfinder (passive)"
  subfinder -d "$d" -silent > "$out/subs-passive.txt"
  echo "[2/4] shuffledns (brute + resolve)"
  local md="$(command -v massdns)"
  if [[ -n $md ]]; then
    shuffledns -d "$d" -r "$res" -w "$HACKTOOLS_DIR/wordlists/subdomains.txt" \
      -silent -massdns "$md" > "$out/subs-brute.txt" 2>/dev/null || true
  else
    : > "$out/subs-brute.txt"
    echo "  (massdns missing — brute step skipped; run: zsc pentest)"
  fi
  sort -u "$out"/subs-*.txt | dnsx -silent -a -resp > "$out/dns.txt"
  echo "[3/4] httpx (probe live hosts)"
  sort -u "$out"/subs-*.txt | httpx -silent -title -tech-detect -status-code > "$out/live.txt"
  awk '{print $1}' "$out/live.txt" > "$out/urls.txt"
  echo "[4/4] nuclei (quick wins — templates update on first run)"
  nuclei -l "$out/urls.txt" -severity medium,high,critical -silent -o "$out/nuclei.txt" 2>/dev/null || true
  echo "done -> $out  (live hosts: $(wc -l < "$out/live.txt"))"
}

# ── Tool integrations (each guarded) ─────────────────────────────────
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
command -v zoxide  > /dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v starship > /dev/null 2>&1 && eval "$(starship init zsh)"
command -v mise    > /dev/null 2>&1 && eval "$(mise activate zsh)"

# ── Functions ────────────────────────────────────────────────────────
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

function cpwd() {  # copy cwd (~ for $HOME) to clipboard — clip.exe on WSL
  local p="${PWD/#$HOME/~}"
  if   command -v clip.exe >/dev/null 2>&1; then printf %s "$p" | clip.exe
  elif command -v pbcopy  >/dev/null 2>&1; then printf %s "$p" | pbcopy
  elif command -v wl-copy >/dev/null 2>&1; then printf %s "$p" | wl-copy
  elif command -v xclip   >/dev/null 2>&1; then printf %s "$p" | xclip -selection clipboard
  else echo "no clipboard tool found"; return 1; fi
  echo "copied: $p"
}

function envsource() {  # envsource .env — export KEY=VALUE lines into the shell
  local f="${1:-.env}"
  [[ -r $f ]] || { echo "usage: envsource <env-file>"; return 1; }
  set -a; source "$f"; set +a
  echo "loaded: $f"
}
