#!/usr/bin/env bash
# Opt-in CLI profiles for the zsc knife roll. No curl-to-shell installers.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_DIR="$REPO_DIR/knife-roll/profiles"
ALL_PROFILES=(development security infrastructure databases work design business)
DRY_RUN=0 ASSUME_YES=0
PROFILES=()

usage() {
  cat <<'EOF'
usage: zsc knife [--dry-run] [--yes] <profile...>
       zsc knife list

Profiles: development security infrastructure databases work design business all
Business intentionally installs no global packages; see docs/knife-roll.md.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|-n) DRY_RUN=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    list) exec bash "$0" --dry-run all ;;
    all) PROFILES=("${ALL_PROFILES[@]}") ;;
    help|-h|--help) usage; exit 0 ;;
    --*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) PROFILES+=("$1") ;;
  esac
  shift
done

if [[ $EUID -eq 0 ]]; then
  echo "run as your normal user, not root" >&2
  exit 1
fi
if (( ${#PROFILES[@]} == 0 )); then
  usage >&2
  exit 2
fi
if ! command -v apt-get >/dev/null 2>&1; then
  echo "this profile installer currently supports apt-based WSL/Linux" >&2
  exit 1
fi

# Validate profiles before changing anything.
declare -A PROFILE_SEEN=()
for profile in "${PROFILES[@]}"; do
  [[ -f "$PROFILE_DIR/$profile.txt" ]] || { echo "unknown profile: $profile" >&2; exit 2; }
  PROFILE_SEEN["$profile"]=1
done

APT_PACKAGES=()
PIPX_PACKAGES=()
declare -A APT_SEEN=() PIPX_SEEN=()
for profile in "${!PROFILE_SEEN[@]}"; do
  while IFS= read -r raw || [[ -n $raw ]]; do
    line="${raw%%#*}"
    line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -z $line ]] && continue
    kind="${line%%:*}"
    value="${line#*:}"
    [[ $kind != "$line" && -n $value ]] || { echo "invalid entry in $profile: $raw" >&2; exit 2; }
    case "$kind" in
      apt)
        [[ $value =~ ^[a-zA-Z0-9][a-zA-Z0-9+.-]*$ ]] || { echo "unsafe apt package: $value" >&2; exit 2; }
        if [[ -z ${APT_SEEN[$value]+x} ]]; then APT_PACKAGES+=("$value"); APT_SEEN["$value"]=1; fi
        ;;
      pipx)
        [[ $value =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || { echo "unsupported pipx package spec: $value" >&2; exit 2; }
        if [[ -z ${PIPX_SEEN[$value]+x} ]]; then PIPX_PACKAGES+=("$value"); PIPX_SEEN["$value"]=1; fi
        ;;
      *) echo "unsupported installer '$kind' in $profile" >&2; exit 2 ;;
    esac
  done < "$PROFILE_DIR/$profile.txt"
done

printf 'Profiles: %s\n' "${!PROFILE_SEEN[*]}"
printf 'APT packages (%d): %s\n' "${#APT_PACKAGES[@]}" "${APT_PACKAGES[*]:-none}"
printf 'pipx packages (%d): %s\n' "${#PIPX_PACKAGES[@]}" "${PIPX_PACKAGES[*]:-none}"
if (( DRY_RUN )); then
  echo "dry run only; no packages installed"
  exit 0
fi

if (( ASSUME_YES == 0 )); then
  read -r -p "Install these packages? [y/N] " reply
  [[ $reply =~ ^[Yy]$ ]] || { echo "cancelled"; exit 0; }
fi

if (( ${#APT_PACKAGES[@]} )); then
  sudo apt-get update
  sudo apt-get install -y "${APT_PACKAGES[@]}"
fi

if (( ${#PIPX_PACKAGES[@]} )); then
  command -v pipx >/dev/null 2>&1 || { echo "pipx installation failed" >&2; exit 1; }
  export PATH="$HOME/.local/bin:$PATH"
  pipx ensurepath >/dev/null
  installed="$(pipx list --short 2>/dev/null || true)"
  for package in "${PIPX_PACKAGES[@]}"; do
    if printf '%s\n' "$installed" | awk '{print $1}' | grep -Fxq "$package"; then
      echo "pipx ok: $package"
    else
      echo "pipx install: $package"
      pipx install "$package"
    fi
  done
fi

if [[ -n ${PROFILE_SEEN[business]+x} ]]; then
  echo "business: no global packages; deploy only the services you need per project (docs/knife-roll.md)"
fi

echo "knife-roll profile installation complete"
