# curtain-call

Bootstrap a bare-metal Kali box toward an Exegol-like setup.

## Quickstart — internet

```bash
git clone <repo> ~/curtain-call && cd ~/curtain-call
./install.sh               # shell + history + tools
./install.sh --resources   # fetch the arsenal
exec zsh
```

## Quickstart — no internet

```bash
# on a machine WITH internet:
./build-vendor.sh                                      # -> vendor/arsenal.tgz
git add vendor/arsenal.tgz && git commit -m vendor && git push

# on the box:
git clone <repo> ~/curtain-call && cd ~/curtain-call
./install.sh --shell --history --offline              # extracts vendor/arsenal.tgz
exec zsh
# day-0, once:
sudo systemctl start postgresql && sudo msfdb init
sudo cp -r resources/data/vulscan /usr/share/nmap/scripts/ && sudo nmap --script-updatedb
```

`install.sh [--shell|--history|--tools|--resources|--offline|--all]` — idempotent.

## Features

### Shell env
- `target <ip> [names]` — set `$IP`/`$TARGET` + `/etc/hosts`
- `lhost` — set `$LHOST` from tun0
- `nmapx <name> …` — scan into `./scans/<name>.xml` (import into kiss ScanViewer)
- `www` — serve `resources/` over HTTP; `nuclei-int`, `onerule`, `kev` aliases

### Always-on logging
- every tmux pane logged to `~/.curtain-call/logs/` (ANSI-stripped)
- `cc-logs [ls|tail|grep <pat>]`

### Ctrl-R history
- seeded command corpus (`shell/history.seed`), fuzzy `Ctrl-R` via fzf
- parameterized by `$IP`/`$DOMAIN`/`$LHOST`/`$SUBNET`

### Tools

- **apt:** nmap, masscan, rustscan, whatweb, gobuster, feroxbuster, ffuf, nikto, netexec, smbclient, smbmap, ldap-utils, krb5-user, impacket-scripts, evil-winrm, responder, bloodhound, hashcat, john, hydra, exploitdb, metasploit-framework, seclists, proxychains4
- **pipx:** certipy-ad, bloodyAD, coercer, mitm6, ldapdomaindump
- **binaries:** nuclei, kerbrute, chisel, ligolo-proxy
- **drops** (`resources/`, served via `www`): linpeas, pspy, lse, les, deepce, ncat, ligolo-agent, winPEAS, PrintSpoofer, GodPotato, PrivescCheck, PowerView, PowerUp, mimikatz, SharpHound, p0wny-shell
- **datasets:** nuclei-templates (curated), vulscan, OneRuleToRuleThemAll, bloodhound customqueries, CISA KEV
