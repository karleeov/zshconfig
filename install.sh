#!/usr/bin/env bash
# One-time WSL Ubuntu bootstrap: apt packages + external installers.
# Run as your normal user (sudo prompts appear where needed). Idempotent.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "run as your normal user, not root" >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y \
  zsh git tmux neovim fzf zoxide eza bat ripgrep fd-find btop \
  fastfetch lolcat cmatrix jp2a unzip curl

if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
  read -rp "make zsh your login shell? [Y/n] " reply
  if [[ ! ${reply:-y} =~ ^[Nn] ]]; then
    sudo chsh -s "$(command -v zsh)" "$USER"
  fi
fi

# Ubuntu binary names differ: bat -> batcat, fd-find -> fdfind
mkdir -p ~/.local/bin
[[ -x "$(command -v batcat)" ]] && ln -sf "$(command -v batcat)" ~/.local/bin/bat
[[ -x "$(command -v fdfind)" ]] && ln -sf "$(command -v fdfind)" ~/.local/bin/fd
grep -q 'HOME/.local/bin' ~/.profile 2>/dev/null || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile

# starship: no recent apt package
if ! command -v starship >/dev/null 2>&1; then
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

# mise: node/python/rust version manager (activated by .zshrc)
if ! command -v mise >/dev/null 2>&1 && [[ ! -x ~/.local/bin/mise ]]; then
  curl https://mise.run | sh
fi

# TPM: tmux plugin manager (tmux.conf plugins install on first tmux start, or prefix+I)
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# workmux: git worktrees + tmux windows (https://workmux.dev)
if ! command -v workmux >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/raine/workmux/main/scripts/install.sh | bash
fi

echo ""
echo "done. run ./deploy.sh to push configs, then start tmux and press prefix+I once."
