#!/usr/bin/env bash
# Passive-by-default recon. Active HTTP/Nuclei work requires an explicit scope file.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCOPE_CHECK="$REPO_DIR/skills/chef-knife-roll/scripts/scope_check.py"
TARGET="" SCOPE="" ACTIVE=0

usage() {
  cat <<'EOF'
usage: recon <domain> [--scope FILE] [--active]

Default: passive subdomain discovery only; no HTTP probing or vulnerability scan.
Active:  requires documented authorization plus --active --scope FILE.
         Candidates are scope-filtered before DNS/HTTP/Nuclei steps.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --active) ACTIVE=1 ;;
    --scope) [[ $# -ge 2 ]] || { echo "--scope needs a file" >&2; exit 2; }; SCOPE=$2; shift ;;
    -h|--help) usage; exit 0 ;;
    --*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) [[ -z $TARGET ]] || { echo "only one target is supported" >&2; exit 2; }; TARGET=$1 ;;
  esac
  shift
done

[[ -n $TARGET ]] || { usage >&2; exit 2; }
TARGET="${TARGET%.}"
TARGET="${TARGET,,}"
[[ $TARGET =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$ ]] || { echo "target must be one bare hostname, without scheme/path" >&2; exit 2; }
[[ $TARGET =~ [a-z] ]] || { echo "recon expects a hostname; use IP-specific tooling only within your authorized scope" >&2; exit 2; }
if (( ACTIVE )) && [[ -z $SCOPE ]]; then
  echo "active mode requires --scope FILE; passive mode is the default" >&2
  exit 2
fi
if [[ -n $SCOPE && ! -r $SCOPE ]]; then
  echo "scope file is not readable: $SCOPE" >&2
  exit 2
fi
command -v python3 >/dev/null 2>&1 || { echo "python3 is required for scope validation" >&2; exit 1; }

required=(subfinder)
if (( ACTIVE )); then required+=(dnsx httpx nuclei); fi
missing=()
for cmd in "${required[@]}"; do command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd"); done
if (( ${#missing[@]} )); then
  echo "missing tools: ${missing[*]} — run: zsc pentest" >&2
  exit 1
fi

if [[ -n $SCOPE ]]; then
  python3 "$SCOPE_CHECK" "$TARGET" --scope "$SCOPE" || {
    echo "target is outside the declared scope" >&2
    exit 1
  }
fi

safe_target="${TARGET//[^a-z0-9._-]/_}"
out="$HOME/hacks/${safe_target}-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$out"
printf '%s\n' "$TARGET" > "$out/target.txt"
[[ -z $SCOPE ]] || cp "$SCOPE" "$out/scope.txt"

echo "[1] subfinder (passive public sources)"
subfinder -d "$TARGET" -silent > "$out/subs-passive.txt"
printf '%s\n' "$TARGET" | cat - "$out/subs-passive.txt" | sort -u > "$out/candidates.txt"

if (( ! ACTIVE )); then
  cat <<EOF
passive recon complete: $out
Candidates: $(wc -l < "$out/candidates.txt")
No DNS brute force, HTTP probing, port scanning, or vulnerability scanning was performed.
Review the targets and your authorization before using --active --scope FILE.
EOF
  exit 0
fi

echo "[2] scope filter candidates"
python3 "$SCOPE_CHECK" --filter --scope "$SCOPE" < "$out/candidates.txt" > "$out/subs-in-scope.txt"
if [[ ! -s $out/subs-in-scope.txt ]]; then
  echo "no in-scope hosts remain; stopping before network probes" >&2
  exit 1
fi

echo "[3] dnsx (in-scope candidates only)"
dnsx -l "$out/subs-in-scope.txt" -silent -a -resp > "$out/dns.txt"

echo "[4] httpx (conservative rate; output filtered again)"
httpx -l "$out/subs-in-scope.txt" -silent -title -tech-detect -status-code \
  -rate-limit 20 -timeout 5 > "$out/live-unfiltered.txt"
python3 "$SCOPE_CHECK" --filter --scope "$SCOPE" < "$out/live-unfiltered.txt" > "$out/live.txt"
awk '{print $1}' "$out/live.txt" > "$out/urls.txt"

if [[ -s $out/urls.txt ]]; then
  echo "[5] nuclei (medium+; conservative concurrency/rate)"
  nuclei -l "$out/urls.txt" -severity medium,high,critical \
    -rl 20 -c 5 -timeout 5 -silent -o "$out/nuclei.txt"
else
  echo "[5] no live in-scope HTTP targets; nuclei skipped"
fi

cat <<EOF
active recon complete: $out
Live in-scope HTTP targets: $(wc -l < "$out/live.txt")
Scanner output is not proof of vulnerability; validate findings manually and honor the engagement rules.
EOF
