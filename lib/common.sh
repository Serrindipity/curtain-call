# shellcheck shell=bash
# Shared helpers for curtain-call installers. Source this; do not execute.

# --- logging ---------------------------------------------------------------
if [ -t 1 ]; then
  _CC_BOLD=$'\033[1m'; _CC_BLUE=$'\033[34m'; _CC_YEL=$'\033[33m'
  _CC_RED=$'\033[31m'; _CC_GRN=$'\033[32m'; _CC_RST=$'\033[0m'
else
  _CC_BOLD=; _CC_BLUE=; _CC_YEL=; _CC_RED=; _CC_GRN=; _CC_RST=
fi

info() { printf '%s[*]%s %s\n' "$_CC_BLUE" "$_CC_RST" "$*"; }
ok()   { printf '%s[+]%s %s\n' "$_CC_GRN"  "$_CC_RST" "$*"; }
warn() { printf '%s[!]%s %s\n' "$_CC_YEL"  "$_CC_RST" "$*" >&2; }
err()  { printf '%s[x]%s %s\n' "$_CC_RED"  "$_CC_RST" "$*" >&2; }
die()  { err "$*"; exit 1; }
step() { printf '\n%s== %s ==%s\n' "$_CC_BOLD" "$*" "$_CC_RST"; }

have() { command -v "$1" >/dev/null 2>&1; }

# --- environment sanity ----------------------------------------------------
is_debian() { [ -f /etc/debian_version ]; }

warn_if_root() {
  if [ "$(id -u)" -eq 0 ]; then
    warn "Running as root. Shell config will land in root's home."
    warn "Run as your normal user; the installer calls sudo only where needed."
  fi
}

# --- file editing (idempotent) ---------------------------------------------
# Back up a file once (keeps the first backup, never overwrites it).
backup_file() {
  local f="$1"
  [ -e "$f" ] || return 0
  [ -e "$f.curtain-call.bak" ] && return 0
  cp -p "$f" "$f.curtain-call.bak" && info "Backed up $f -> $f.curtain-call.bak"
}

# Insert or replace a guarded block in a file. Safe to re-run.
# usage: ensure_block <file> <tag> <<'EOF' ... EOF
ensure_block() {
  local file="$1" tag="$2" body start end tmp
  start="# >>> curtain-call:${tag} >>>"
  end="# <<< curtain-call:${tag} <<<"
  body="$(cat)"
  touch "$file"
  backup_file "$file"
  tmp="$(mktemp)"
  # copy everything except any existing block with this tag
  awk -v s="$start" -v e="$end" '
    $0==s {skip=1} !skip {print} $0==e {skip=0}
  ' "$file" > "$tmp"
  # drop trailing blank lines, then append a fresh block
  printf '%s\n%s\n%s\n%s\n' "$(cat "$tmp")" "$start" "$body" "$end" > "$file"
  rm -f "$tmp"
  ok "Updated ${tag} block in $file"
}

# Resolve the repo root regardless of where the caller runs from.
cc_repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}
