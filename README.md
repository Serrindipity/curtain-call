# curtain-call

Bootstrap a bare-metal Kali box toward an Exegol-like setup.

## Quickstart

```bash
git clone <repo> ~/curtain-call && cd ~/curtain-call
./install.sh      # shell + history + tools
exec zsh
```

`install.sh [--shell|--history|--tools|--all]` — idempotent.

## Features

### Shell env
- `target <ip> [names]` — set `$IP`/`$TARGET` + `/etc/hosts`
- `lhost` — set `$LHOST` from tun0
- `nmapx <name> …` — scan into `./scans/<name>.xml` (import into kiss ScanViewer)

### Always-on logging
- every tmux pane logged to `~/.curtain-call/logs/` (ANSI-stripped)
- `cc-logs [ls|tail|grep <pat>]`

### Ctrl-R history
- seeded command corpus (`shell/history.seed`), fuzzy `Ctrl-R` via fzf
- parameterized by `$IP`/`$DOMAIN`/`$LHOST`/`$SUBNET`

### Tools
- **apt:** nmap, masscan, rustscan, nuclei, whatweb, gobuster, feroxbuster, ffuf, nikto, netexec, smbclient, smbmap, ldap-utils, krb5-user, impacket-scripts, evil-winrm, responder, bloodhound, hashcat, john, hydra, exploitdb, metasploit-framework, seclists, proxychains4
- **pipx:** certipy-ad, bloodyAD, coercer, mitm6, ldapdomaindump

## offline-arsenal branch

For a competition with no internet: the `offline-arsenal` branch adds drop-on-target
binaries/scripts (linpeas, pspy, winPEAS, PrintSpoofer/GodPotato, chisel, ligolo,
kerbrute, nuclei + curated templates, vulscan, OneRule, …) that vendor into the repo
and install with `./install.sh --offline`.

```bash
git checkout offline-arsenal
```
