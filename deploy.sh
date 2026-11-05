#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

backup_copy() {   # backup_copy SRC DST — copy, backing up DST when it differs from SRC
  local src=$1 dst=$2
  if [[ -e "$dst" ]] && ! cmp -s "$src" "$dst"; then
    cp "$dst" "$dst.bak"
    echo "backed up: $dst -> $dst.bak"
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "installed: $dst"
}

backup_link() {   # backup_link SRC DST — symlink, backing up real DST that differs from SRC
  local src=$1 dst=$2
  if [[ -e "$dst" && ! -L "$dst" ]] && ! cmp -s "$src" "$dst"; then
    mv "$dst" "$dst.bak"
    echo "backed up: $dst -> $dst.bak"
  fi
  rm -f "$dst"
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "linked:    $dst -> $src"
}

backup_copy "$REPO_DIR/.zshrc" "$HOME/.zshrc"
backup_link "$REPO_DIR/starship.toml" "$HOME/.config/starship.toml"

# zsc CLI
mkdir -p "$HOME/.local/bin"
ln -sf "$REPO_DIR/bin/zsc" "$HOME/.local/bin/zsc"
echo "linked:    $HOME/.local/bin/zsc -> $REPO_DIR/bin/zsc"

# tmux
backup_copy "$REPO_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
backup_copy "$REPO_DIR/tmux/tmux.reset.conf" "$HOME/.config/tmux/tmux.reset.conf"

# lazygit
backup_copy "$REPO_DIR/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

# git: XDG config merged with ~/.gitconfig (delta pager, aliases, ghq root)
backup_copy "$REPO_DIR/git/config" "$HOME/.config/git/config"

# mise: global tool versions (node/python/rust/go/ghq)
backup_copy "$REPO_DIR/mise/config.toml" "$HOME/.config/mise/config.toml"

# nvim: LazyVim config, copied (repo is the source of truth)
if [[ -d "$HOME/.config/nvim" ]] && ! cmp -s "$REPO_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua" 2>/dev/null; then
  echo "NOTE: ~/.config/nvim exists and differs from repo. Local edits there are overwritten below."
fi
mkdir -p "$HOME/.config/nvim"
cp -r "$REPO_DIR/nvim/." "$HOME/.config/nvim/"
echo "installed: ~/.config/nvim (LazyVim)"

# tmux plugins via TPM (needs a tmux server to register bindings)
if command -v tmux >/dev/null 2>&1 && [[ -d ~/.tmux/plugins/tpm ]]; then
  tmux new-session -d -s _deploy 2>/dev/null || true
  ~/.tmux/plugins/tpm/bin/install_plugins >/dev/null 2>&1 || echo "  (tmux plugins: start tmux and press prefix+I once)"
  tmux kill-session -t _deploy 2>/dev/null || true
fi

# wsl.conf lives at /etc — needs root, so advise instead of touching
if ! diff -q /etc/wsl.conf "$REPO_DIR/wsl.conf" > /dev/null 2>&1; then
  echo ""
  echo "NOTE: repo wsl.conf differs from /etc/wsl.conf."
  echo "Review, then apply:"
  echo "  sudo cp $REPO_DIR/wsl.conf /etc/wsl.conf"
  echo "  (then from Windows: wsl --shutdown)"
fi

# Dependency report
echo ""
echo "dependency check:"
missing=()
for cmd in eza bat rg fd btop nvim zoxide fzf starship mise fastfetch lolcat cmatrix jp2a git tmux lazygit workmux delta; do
  command -v "$cmd" > /dev/null 2>&1 || missing+=("$cmd")
done
if (( ${#missing[@]} )); then
  echo "  MISSING: ${missing[*]}"
  install_list=()
  for cmd in "${missing[@]}"; do
    case "$cmd" in
      rg) install_list+=(ripgrep) ;;
      fd) install_list+=(fd-find) ;;
    *) install_list+=("$cmd") ;;
    esac
  done
  if command -v apt-get > /dev/null 2>&1; then
    echo "  install: sudo apt install ${install_list[*]}"
  elif command -v pacman > /dev/null 2>&1; then
    echo "  install: sudo pacman -S --needed ${install_list[*]}"
  else
    echo "  install manually: no apt or pacman found"
  fi
else
  echo "  all present"
fi

echo ""
echo "done. restart your shell."
