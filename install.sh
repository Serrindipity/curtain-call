#!/usr/bin/env bash
# curtain-call — bootstrap a bare-metal Kali box toward the Exegol feel.
# Three layers: shell env + always-on logging, seeded Ctrl-R history, tools.
# Idempotent and safe to re-run. Configs are sourced from this repo in place,
# so you can edit files here and just re-run the relevant step.
#
#   ./install.sh                 # shell + history + tools (the usual)
#   ./install.sh --shell         # zsh/tmux config + logging only
#   ./install.sh --history       # (re)seed the Ctrl-R history corpus
#   ./install.sh --tools         # apt + pipx + tunneling binaries
#   ./install.sh --resources     # download the offline drop-on-target arsenal
#   ./install.sh --all           # everything, including --resources
set -uo pipefail
CC_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$CC_HOME/lib/common.sh"

CC_STATE="$HOME/.curtain-call"
CC_LOGDIR="$CC_STATE/logs"
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"

do_shell=0 do_hist=0 do_tools=0 do_res=0
if [ "$#" -eq 0 ]; then do_shell=1 do_hist=1 do_tools=1; fi
for a in "$@"; do case "$a" in
  --shell) do_shell=1 ;;
  --history) do_hist=1 ;;
  --tools) do_tools=1 ;;
  --resources) do_res=1 ;;
  --all) do_shell=1 do_hist=1 do_tools=1 do_res=1 ;;
  -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) die "unknown option: $a (try --help)" ;;
esac; done

warn_if_root
mkdir -p "$CC_LOGDIR"
chmod +x "$CC_HOME"/bin/* "$CC_HOME"/tools/*.sh "$CC_HOME"/resources/*.sh 2>/dev/null || true

# --- shell env + logging ---------------------------------------------------
if [ "$do_shell" -eq 1 ]; then
  step "shell env + always-on logging"

  # Render the tmux template with absolute paths (tmux hooks can't read env).
  sed -e "s#@CC_HOME@#$CC_HOME#g" -e "s#@CC_LOGDIR@#$CC_LOGDIR#g" \
      "$CC_HOME/shell/tmux.conf.in" > "$CC_STATE/tmux.conf"
  ok "rendered $CC_STATE/tmux.conf"

  ensure_block "$HOME/.zshrc" shell <<EOF
export CC_HOME="$CC_HOME"
export CC_STATE="$CC_STATE"
export CC_LOGDIR="$CC_LOGDIR"
[ -r "\$CC_HOME/shell/curtain-call.zsh" ] && source "\$CC_HOME/shell/curtain-call.zsh"
EOF

  ensure_block "$HOME/.tmux.conf" shell <<EOF
source-file "$CC_STATE/tmux.conf"
EOF
  info "open a new shell (or: source ~/.zshrc). In tmux: tmux source ~/.tmux.conf"
fi

# --- seed Ctrl-R history ---------------------------------------------------
if [ "$do_hist" -eq 1 ]; then
  step "seed Ctrl-R history -> $HISTFILE"
  seed="$CC_HOME/shell/history.seed"
  if have sha256sum; then sha="$(sha256sum "$seed" | awk '{print $1}')"
  else sha="$(shasum -a 256 "$seed" | awk '{print $1}')"; fi
  marker="$CC_STATE/.history-seed.sha"
  if [ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$sha" ]; then
    ok "history already seeded from current history.seed (unchanged)"
  else
    backup_file "$HISTFILE"; touch "$HISTFILE"
    base=1577836800; i=0; added=0      # 2020-01-01: sorts before your real history
    while IFS= read -r cmd; do
      case "$cmd" in ''|\#*) continue ;; esac
      # skip if this exact command is already in history (avoid duplicates)
      grep -qF -- ";$cmd" "$HISTFILE" 2>/dev/null && continue
      printf ': %d:0;%s\n' "$((base+i))" "$cmd" >> "$HISTFILE"
      i=$((i+1)); added=$((added+1))
    done < "$seed"
    printf '%s' "$sha" > "$marker"
    ok "seeded $added commands (press Ctrl-R in a new shell to search them)"
  fi
fi

# --- tools -----------------------------------------------------------------
if [ "$do_tools" -eq 1 ]; then
  step "operator tools"
  bash "$CC_HOME/tools/install-tools.sh"
fi

# --- offline arsenal -------------------------------------------------------
if [ "$do_res" -eq 1 ]; then
  step "offline drop-on-target arsenal"
  bash "$CC_HOME/resources/fetch-resources.sh"
fi

step "curtain-call ready"
echo "  new shell  -> Ctrl-R (fuzzy history), 'target <ip> [names]', 'lhost'"
echo "  logs       -> every tmux pane auto-logs to $CC_LOGDIR  (cc-logs tail)"
echo "  arsenal    -> ./install.sh --resources, then 'www' to serve it"
