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
for cmd in eza bat rg fd btop nvim zoxide fzf starship mise fastfetch lolcat cmatrix jp2a git; do
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
