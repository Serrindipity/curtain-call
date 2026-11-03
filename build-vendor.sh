#!/usr/bin/env bash
# Snapshot the arsenal into vendor/arsenal.tgz so it travels INSIDE the git repo
# onto a competition box with no internet and no removable media.
#
# Run this on a machine WITH internet, then commit the result:
#   ./build-vendor.sh
#   git add vendor/arsenal.tgz && git commit -m "vendor: refresh arsenal snapshot"
#
# On the competition box (after git clone):
#   ./install.sh --shell --history --offline
set -uo pipefail
CC_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CC_HOME/lib/common.sh"

FORCE=""; [ "${1:-}" = "--force" ] && FORCE="--force"

step "fetching arsenal (needs internet)"
bash "$CC_HOME/resources/fetch-resources.sh" $FORCE

step "packing vendor/arsenal.tgz"
mkdir -p "$CC_HOME/vendor"
# Pack the populated resources subtree (paths relative to repo root so it
# extracts cleanly with `tar -xzf ... -C <repo>`). Exclude the .gitkeeps.
tar -czf "$CC_HOME/vendor/arsenal.tgz" -C "$CC_HOME" \
    --exclude='resources/**/.gitkeep' \
    resources/bin resources/linux resources/windows resources/webshells resources/data \
  && ok "wrote vendor/arsenal.tgz"

size="$(du -h "$CC_HOME/vendor/arsenal.tgz" | awk '{print $1}')"
step "done — snapshot is $size"
echo "  commit it:  git add vendor/arsenal.tgz && git commit -m 'vendor: refresh arsenal'"
echo "  on box:     ./install.sh --shell --history --offline"
[ "${size%M*}" -ge 200 ] 2>/dev/null && warn "snapshot >200M — trim resources/fetch-resources.sh (e.g. nuclei template dirs)"
