# shellcheck shell=bash
# Download helpers for the tool/resource layers. Source after lib/common.sh.
# All functions are best-effort: a failure warns and returns non-zero so one
# bad URL never aborts the whole run. Do your fetching BEFORE the competition
# (needs internet); the arsenal is then served offline from your box.

# curl with retries; writes to dest, keeps a good existing file on failure.
fetch_url() {
  local url="$1" dest="$2" tmp
  tmp="$(mktemp)"
  if curl -fsSL --retry 3 --retry-delay 2 -o "$tmp" "$url"; then
    mkdir -p "$(dirname "$dest")"
    mv "$tmp" "$dest"; ok "fetched $(basename "$dest")"; return 0
  fi
  rm -f "$tmp"; warn "could not fetch $url"; return 1
}

# Latest release tag for a repo, e.g. gh_latest_tag jpillora/chisel -> v1.10.1
gh_latest_tag() {
  local repo="$1" tag
  tag="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null \
        | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
  [ -n "$tag" ] && printf '%s' "$tag"
}

# Stable "latest/download/<asset>" URL (asset name must be version-independent).
fetch_ghlatest() {
  local repo="$1" asset="$2" dest="$3"
  fetch_url "https://github.com/$repo/releases/latest/download/$asset" "$dest"
}

# Pick the first release asset matching an extended-regex, resolving the tag via
# the API (for projects whose asset names embed the version, e.g. chisel/ligolo).
fetch_gh_asset_match() {
  local repo="$1" pattern="$2" dest="$3" url
  url="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null \
        | grep -Eo '"browser_download_url": *"[^"]+"' \
        | sed -E 's/.*"(https[^"]+)".*/\1/' \
        | grep -E "$pattern" | head -1)"
  [ -n "$url" ] || { warn "no asset matching /$pattern/ in $repo latest release"; return 1; }
  fetch_url "$url" "$dest"
}

# Fetch a .gz release asset and gunzip to a plain executable.
fetch_gh_gz() {
  local repo="$1" pattern="$2" dest="$3" tmp
  tmp="$(mktemp).gz"
  if fetch_gh_asset_match "$repo" "$pattern" "$tmp"; then
    gunzip -f "$tmp" && mv "${tmp%.gz}" "$dest" && chmod +x "$dest" \
      && ok "unpacked $(basename "$dest")"; return 0
  fi
  return 1
}

# Fetch a .tar.gz release asset and extract one member to dest.
fetch_gh_tar_member() {
  local repo="$1" pattern="$2" member="$3" dest="$4" tmp dir
  tmp="$(mktemp).tgz"; dir="$(mktemp -d)"
  if fetch_gh_asset_match "$repo" "$pattern" "$tmp"; then
    tar -xzf "$tmp" -C "$dir" 2>/dev/null
    local found; found="$(find "$dir" -type f -name "$member" | head -1)"
    [ -n "$found" ] || { warn "$member not in $repo archive"; rm -rf "$tmp" "$dir"; return 1; }
    mkdir -p "$(dirname "$dest")"; cp "$found" "$dest"; chmod +x "$dest"
    ok "extracted $(basename "$dest")"; rm -rf "$tmp" "$dir"; return 0
  fi
  rm -rf "$tmp" "$dir"; return 1
}
