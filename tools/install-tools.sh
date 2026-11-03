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

# --- tunneling binaries (operator side) ------------------------------------
# Kali's chisel can lag; ligolo-ng's proxy is not packaged. Install to ~/.local/bin.
step "tunneling binaries -> $LOCAL_BIN"
if [ ! -x "$LOCAL_BIN/chisel" ]; then
  fetch_gh_gz jpillora/chisel 'chisel_[0-9.]+_linux_amd64\.gz$' "$LOCAL_BIN/chisel" \
    || warn "chisel: fetch failed"
else ok "chisel already present"; fi

if [ ! -x "$LOCAL_BIN/ligolo-proxy" ]; then
  fetch_gh_tar_member nicocha30/ligolo-ng 'ligolo-ng_proxy_.*_linux_amd64\.tar\.gz$' \
    'proxy' "$LOCAL_BIN/ligolo-proxy" || warn "ligolo-proxy: fetch failed"
else ok "ligolo-proxy already present"; fi

step "done"
info "operator tools installed. Offline drop-on-target arsenal: tools/../resources/fetch-resources.sh"
have fzf || warn "fzf missing — Ctrl-R fuzzy history will fall back to substring search"
