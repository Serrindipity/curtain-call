#!/usr/bin/env bash
# Build the OFFLINE ARSENAL, mirroring Exegol's exegol-resources plus the
# "prep-in-advance" datasets (nuclei templates, vulscan, cracking rules, ...).
# Fetch BEFORE the competition (needs internet). Three kinds of output:
#   bin/   operator binaries that run on YOUR box (nuclei, chisel, ligolo-proxy)
#   {linux,windows,webshells}/  static files you DROP on targets
#   data/  datasets operator tools read (nuclei-templates, vulscan, rules, ...)
#
# Then either serve/run in place, or snapshot with ../build-vendor.sh so the
# whole thing travels inside the git repo onto an air-gapped competition box.
# Idempotent: existing files are skipped unless you pass --force.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$ROOT/lib/common.sh"
# shellcheck source=../lib/fetch.sh
source "$ROOT/lib/fetch.sh"

FORCE=0; [ "${1:-}" = "--force" ] && FORCE=1
BIN="$HERE/bin"; LNX="$HERE/linux"; WIN="$HERE/windows"; WEB="$HERE/webshells"; DATA="$HERE/data"
mkdir -p "$BIN" "$LNX" "$WIN" "$WEB" "$DATA"

# Curated nuclei template subset — kept small on purpose (an internal estate
# rarely leaves many scriptable holes open). Edit to taste.
NUCLEI_TEMPLATE_DIRS=(
  http/exposed-panels
  http/default-logins
  http/misconfiguration
  http/exposures
  network
)

# skip if present (unless --force); else run the given fetch command ("$@").
_get() {
  local dest="$1"; shift
  if [ "$FORCE" -eq 0 ] && [ -e "$dest" ]; then ok "have $(basename "$dest")"; return 0; fi
  "$@"
}

# --- operator binaries (run on your box) -----------------------------------
step "operator binaries -> $BIN"
_get "$BIN/nuclei" fetch_gh_zip_member projectdiscovery/nuclei 'nuclei_[0-9.]+_linux_amd64\.zip$' nuclei "$BIN/nuclei"
_get "$BIN/chisel" fetch_gh_gz jpillora/chisel 'chisel_[0-9.]+_linux_amd64\.gz$' "$BIN/chisel"
_get "$BIN/ligolo-proxy" fetch_gh_tar_member nicocha30/ligolo-ng 'ligolo-ng_proxy_.*_linux_amd64\.tar\.gz$' proxy "$BIN/ligolo-proxy"
chmod +x "$BIN"/* 2>/dev/null || true

# --- linux drops -----------------------------------------------------------
step "linux drops -> $LNX"
_get "$LNX/linpeas.sh"  fetch_ghlatest peass-ng/PEASS-ng linpeas.sh "$LNX/linpeas.sh"
_get "$LNX/pspy64"      fetch_ghlatest DominicBreuker/pspy pspy64   "$LNX/pspy64"
_get "$LNX/pspy32"      fetch_ghlatest DominicBreuker/pspy pspy32   "$LNX/pspy32"
_get "$LNX/lse.sh"      fetch_url https://raw.githubusercontent.com/diego-treitos/linux-smart-enumeration/master/lse.sh "$LNX/lse.sh"
_get "$LNX/les.sh"      fetch_url https://raw.githubusercontent.com/The-Z-Labs/linux-exploit-suggester/master/linux-exploit-suggester.sh "$LNX/les.sh"
_get "$LNX/deepce.sh"   fetch_url https://raw.githubusercontent.com/stealthcopter/deepce/main/deepce.sh "$LNX/deepce.sh"
_get "$LNX/ncat"        fetch_url https://raw.githubusercontent.com/andrew-d/static-binaries/master/binaries/linux/x86_64/ncat "$LNX/ncat"
_get "$LNX/chisel"      fetch_gh_gz jpillora/chisel 'chisel_[0-9.]+_linux_amd64\.gz$' "$LNX/chisel"
_get "$LNX/ligolo-agent" fetch_gh_tar_member nicocha30/ligolo-ng 'ligolo-ng_agent_.*_linux_amd64\.tar\.gz$' 'agent' "$LNX/ligolo-agent"
chmod +x "$LNX"/* 2>/dev/null || true

# --- windows drops ---------------------------------------------------------
step "windows drops -> $WIN"
_get "$WIN/winPEASx64.exe"  fetch_ghlatest peass-ng/PEASS-ng winPEASx64.exe "$WIN/winPEASx64.exe"
_get "$WIN/PrintSpoofer64.exe" fetch_ghlatest itm4n/PrintSpoofer PrintSpoofer64.exe "$WIN/PrintSpoofer64.exe"
_get "$WIN/GodPotato-NET4.exe" fetch_ghlatest BeichenDream/GodPotato GodPotato-NET4.exe "$WIN/GodPotato-NET4.exe"
_get "$WIN/PrivescCheck.ps1" fetch_url https://raw.githubusercontent.com/itm4n/PrivescCheck/master/PrivescCheck.ps1 "$WIN/PrivescCheck.ps1"
_get "$WIN/PowerView.ps1"   fetch_url https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Recon/PowerView.ps1 "$WIN/PowerView.ps1"
_get "$WIN/PowerUp.ps1"     fetch_url https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1 "$WIN/PowerUp.ps1"
_get "$WIN/chisel.exe"      fetch_gh_gz jpillora/chisel 'chisel_[0-9.]+_windows_amd64\.gz$' "$WIN/chisel.exe"
_get "$WIN/ligolo-agent-win.zip" fetch_gh_asset_match nicocha30/ligolo-ng 'ligolo-ng_agent_.*_windows_amd64\.zip$' "$WIN/ligolo-agent-win.zip"
_get "$WIN/mimikatz.zip"    fetch_ghlatest gentilkiwi/mimikatz mimikatz_trunk.zip "$WIN/mimikatz.zip"
_get "$WIN/SharpHound.zip"  fetch_gh_asset_match BloodHoundAD/SharpHound 'SharpHound-v.*\.zip$' "$WIN/SharpHound.zip"

# --- webshells -------------------------------------------------------------
step "webshells -> $WEB"
_get "$WEB/p0wny-shell.php" fetch_url https://raw.githubusercontent.com/flozz/p0wny-shell/master/shell.php "$WEB/p0wny-shell.php"

# --- datasets (read by operator tools) -------------------------------------
step "datasets -> $DATA"

# nuclei templates: sparse-checkout the curated subset to keep it small.
if [ "$FORCE" -eq 1 ] || [ ! -d "$DATA/nuclei-templates" ]; then
  tmp="$(mktemp -d)"
  if git clone --depth 1 --filter=blob:none --sparse \
       https://github.com/projectdiscovery/nuclei-templates "$tmp" >/dev/null 2>&1 \
     && git -C "$tmp" sparse-checkout set "${NUCLEI_TEMPLATE_DIRS[@]}" >/dev/null 2>&1; then
    # copy the selected dirs, preserving their path under nuclei-templates/
    rm -rf "$DATA/nuclei-templates"; mkdir -p "$DATA/nuclei-templates"
    ( cd "$tmp" && for d in "${NUCLEI_TEMPLATE_DIRS[@]}"; do
        [ -e "$d" ] && { mkdir -p "$DATA/nuclei-templates/$(dirname "$d")"; cp -r "$d" "$DATA/nuclei-templates/$d"; }
      done )
    ok "nuclei templates (curated: ${NUCLEI_TEMPLATE_DIRS[*]})"
  else
    warn "nuclei templates: sparse clone failed (offline?)"
  fi
  rm -rf "$tmp"
else ok "have nuclei-templates"; fi

_get "$DATA/vulscan" \
  git clone --depth 1 https://github.com/scipag/vulscan "$DATA/vulscan"
_get "$DATA/rules/OneRuleToRuleThemAll.rule" \
  fetch_url https://raw.githubusercontent.com/NotSoSecure/password_cracking_rules/master/OneRuleToRuleThemAll.rule "$DATA/rules/OneRuleToRuleThemAll.rule"
_get "$DATA/bloodhound/customqueries.json" \
  fetch_url https://raw.githubusercontent.com/CompassSecurity/BloodHoundQueries/master/customqueries.json "$DATA/bloodhound/customqueries.json"
_get "$DATA/cve/kev.json" \
  fetch_url https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json "$DATA/cve/kev.json"

step "done"
info "serve drops:  www   | nuclei offline:  nuclei -duc -t \$CC_HOME/resources/data/nuclei-templates -l targets.txt"
du -sh "$HERE"/* 2>/dev/null | sed 's/^/  /'
