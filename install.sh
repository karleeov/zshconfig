#!/usr/bin/env bash
# One-time WSL Ubuntu bootstrap: apt packages + external installers.
# Run as your normal user (sudo prompts appear where needed). Idempotent.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -eq 0 ]]; then
  echo "run as your normal user, not root" >&2
  exit 1
fi

# apt packages from manifest (apt-packages.txt) — hash-guarded: skip when
# unchanged since the last successful run (delete the marker to force).
APT_LIST="$REPO_DIR/apt-packages.txt"
APT_MARK="$HOME/.cache/zsc/apt-packages.sha256"
apt_hash="$(sha256sum "$APT_LIST" | cut -d' ' -f1)"
if [[ "$(cat "$APT_MARK" 2>/dev/null || true)" == "$apt_hash" ]]; then
  echo "apt packages unchanged since last run — skipping (rm $APT_MARK to force)"
else
  sudo apt-get update
  grep -vE '^\s*(#|$)' "$APT_LIST" | xargs sudo apt-get install -y
  mkdir -p "$HOME/.cache/zsc"
  echo "$apt_hash" > "$APT_MARK"
fi

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

# delta: better git diffs (pager configured by git/config deploy)
if ! command -v delta >/dev/null 2>&1 && [[ ! -x ~/.local/bin/delta ]]; then
  ver="$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')"
  arch="$(uname -m)"; [[ $arch == x86_64 ]] || arch=aarch64
  curl -fsSL "https://github.com/dandavison/delta/releases/download/${ver}/delta-${ver}-${arch}-unknown-linux-gnu.tar.gz" \
    | tar xz -C /tmp
  install -m755 "/tmp/delta-${ver}-${arch}-unknown-linux-gnu/delta" ~/.local/bin/delta
  rm -rf "/tmp/delta-${ver}-${arch}-unknown-linux-gnu"
  echo "installed delta -> ~/.local/bin/delta"
fi

# mise: node/python/rust/go/ghq version manager (versions pinned in mise/config.toml,
# deployed by deploy.sh; activated by .zshrc)
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
