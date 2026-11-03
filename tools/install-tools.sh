#!/usr/bin/env bash
# Install the OPERATOR toolkit onto Kali: apt packages, pipx tools, and a few
# tunneling binaries Kali ships stale or not at all. Idempotent; re-runnable.
# Run BEFORE the competition (needs internet). This is the stuff that runs on
# YOUR box; target-droppable binaries live in ../resources (fetch-resources.sh).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$ROOT/lib/common.sh"
# shellcheck source=../lib/fetch.sh
source "$ROOT/lib/fetch.sh"

is_debian || die "This installs Kali/Debian packages; run it on your Kali box."
LOCAL_BIN="$HOME/.local/bin"; mkdir -p "$LOCAL_BIN"

# --- apt -------------------------------------------------------------------
step "apt packages"
mapfile -t PKGS < <(grep -vE '^\s*(#|$)' "$HERE/apt.list")
if [ "${#PKGS[@]}" -gt 0 ]; then
  info "updating apt index"; sudo apt-get update -qq || warn "apt update failed (offline?)"
  # Install in one transaction; missing names are reported but don't abort.
  sudo apt-get install -y --no-install-recommends "${PKGS[@]}" \
    || warn "some apt packages failed; re-run or edit tools/apt.list"
fi

# --- pipx ------------------------------------------------------------------
step "pipx tools"
if have pipx; then
  pipx ensurepath >/dev/null 2>&1 || true
  while IFS= read -r spec; do
    [ -n "$spec" ] || continue
    info "pipx install $spec"
    pipx install "$spec" >/dev/null 2>&1 || pipx upgrade "$spec" >/dev/null 2>&1 \
      || warn "pipx failed for $spec"
  done < <(grep -vE '^\s*(#|$)' "$HERE/pipx.list")
  ok "pipx tools done"
else
  warn "pipx not installed (expected from apt.list) — skipping pipx tools"
fi

# --- offline DB refresh (operator-box setup, not a plain download) ----------
step "offline exploit DB"
if have searchsploit; then
  searchsploit -u >/dev/null 2>&1 && ok "searchsploit DB updated" \
    || warn "searchsploit -u skipped (offline?)"
else
  warn "searchsploit not present (install 'exploitdb' from apt.list)"
fi

step "done"
info "operator binaries (nuclei/chisel/ligolo-proxy) + datasets: ./install.sh --resources"
info "on-box day-0 (once): systemctl start postgresql && msfdb init ; nmap --script-updatedb"
have fzf || warn "fzf missing — Ctrl-R fuzzy history will fall back to substring search"
