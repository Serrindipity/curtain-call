# curtain-call zsh environment. Sourced from ~/.zshrc by install.sh.
# CC_HOME is exported by the ~/.zshrc block before this file is sourced.
: "${CC_HOME:=${${(%):-%x}:A:h:h}}"   # fall back to repo root if run standalone
export CC_HOME
export CC_LOGDIR="${CC_LOGDIR:-$HOME/.curtain-call/logs}"

# curtain-call's own bin (cc-logs, cc-log-filter, installed tool symlinks).
case ":$PATH:" in *":$CC_HOME/bin:"*) ;; *) export PATH="$CC_HOME/bin:$PATH";; esac
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH";; esac

# --- history: large, shared, seeded (the fzf Ctrl-R corpus) ----------------
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=200000
export SAVEHIST=400000
setopt EXTENDED_HISTORY        # store timestamps; lets seeded cmds sort first
setopt INC_APPEND_HISTORY      # write as you go, not only on exit
setopt SHARE_HISTORY           # share across panes/windows live
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE       # leading space keeps a command out of history
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

# --- fzf: fuzzy Ctrl-R over that seeded history ----------------------------
# This is the "easiest under pressure" path: Ctrl-R, type a keyword, Enter.
for f in \
  /usr/share/doc/fzf/examples/key-bindings.zsh \
  /usr/share/fzf/key-bindings.zsh \
  "$HOME/.fzf/shell/key-bindings.zsh"; do
  [ -r "$f" ] && source "$f" && break
done
for f in \
  /usr/share/doc/fzf/examples/completion.zsh \
  /usr/share/fzf/completion.zsh; do
  [ -r "$f" ] && source "$f" && break
done
# Show plenty of context and keep input order so recent edits surface.
export FZF_CTRL_R_OPTS="--height 60% --reverse --no-sort --border --prompt 'history> '"
export FZF_DEFAULT_OPTS="--height 40% --reverse --border"

# Fallback if fzf is missing: substring search on the arrow keys.
if ! command -v fzf >/dev/null 2>&1; then
  autoload -U up-line-or-beginning-search down-line-or-beginning-search
  zle -N up-line-or-beginning-search; zle -N down-line-or-beginning-search
  bindkey '^[[A' up-line-or-beginning-search
  bindkey '^[[B' down-line-or-beginning-search
fi

# --- aliases ---------------------------------------------------------------
[ -r "$CC_HOME/shell/aliases.zsh" ] && source "$CC_HOME/shell/aliases.zsh"
