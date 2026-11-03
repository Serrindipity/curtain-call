# curtain-call

Bootstrap a bare-metal Kali box toward an Exegol-like working environment: a tuned
zsh/tmux setup with always-on session logging, a seeded fuzzy-searchable command
history, and the operator toolkit. Run it on your own Kali box; it edits your shell
config in place and installs packages.

```bash
git clone <repo> ~/curtain-call && cd ~/curtain-call
./install.sh            # shell + history + tools
exec zsh
```

`install.sh` is idempotent and re-runnable. Pass `--shell`, `--history`, or `--tools`
to run one layer; with no arguments it runs all three. It backs up `~/.zshrc` and
`~/.tmux.conf` once and only rewrites its own guarded block, so it will not clobber
existing configuration.

## Shell environment

`target <ip> [hostname ...]` sets `$TARGET`/`$IP` and syncs `/etc/hosts`; `lhost`
sets `$LHOST` from your tun0 address. The seeded history is written in terms of these
variables, so once they are set most commands are ready to run. `nmapx <name> <nmap
args>` writes `scans/<name>.xml`, which imports directly into the kiss dashboard
(ScanViewer → import nmap XML).

## Logging

Every tmux pane is piped to a per-day, per-pane file under `~/.curtain-call/logs/`,
with ANSI sequences stripped so the files read as plain evidence. `cc-logs tail`
follows the most recent, `cc-logs grep <pattern>` searches them all, and
`tmux-prefix + P` toggles logging for a pane.

## Command history

`shell/history.seed` is a curated corpus of commands across the usual phases — recon,
SMB/AD, Kerberos, lateral movement, pivoting, privilege escalation — parameterized by
`$IP`/`$DOMAIN`/`$LHOST`/`$SUBNET`. It is loaded into zsh history on install; press
`Ctrl-R`, type a keyword, and edit the result. Edit the file and re-run
`./install.sh --history` to add your own.

## Tools

`tools/apt.list` and `tools/pipx.list` install the operator toolkit: nmap, rustscan,
nuclei, the web fuzzers, netexec, impacket, evil-winrm, responder, bloodhound,
hashcat, john, hydra, exploitdb, metasploit, certipy and others. Edit either list to
taste.

The drop-on-target arsenal (linpeas, winPEAS, chisel, ligolo, kerbrute, nuclei
templates, and the rest) and an offline installer for a competition without internet
live on the `offline-arsenal` branch.
