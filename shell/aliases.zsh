# curtain-call aliases + the target/lhost workflow.
#
# Ported from your own ~/.exegol my-resources `target` function and adapted for
# bare-metal Kali: /etc/hosts is a real file (needs sudo, persists across
# reboots, so we only touch it when you run `target`). State lives in
# ~/.curtain-call/target.env. The seeded Ctrl-R history uses $IP / $TARGET /
# $LHOST / $DOMAIN, so set them once and most commands are ready to run.

_CC_STATE="${CC_STATE:-$HOME/.curtain-call}"
_TARGET_STATE="$_CC_STATE/target.env"
_TARGET_TAG="# managed-by-target"
mkdir -p "$_CC_STATE" 2>/dev/null

# --- target: set $TARGET/$IP (+ optional names in /etc/hosts) --------------
#   target 10.10.10.10 dc01.corp.local corp.local   # set ip + hosts entry
#   target                                          # show current
#   target -c                                       # clear
_target_hosts_sync() {
    local keep
    keep="$(grep -v -F "$_TARGET_TAG" /etc/hosts 2>/dev/null)"
    { printf '%s\n' "$keep"
      if [ -n "$TARGET" ] && [ -n "$TARGET_NAMES" ]; then
          printf '%s\t%s\t%s\n' "$TARGET" "$TARGET_NAMES" "$_TARGET_TAG"
      fi
    } | sudo tee /etc/hosts >/dev/null 2>&1
}
target() {
    case "${1:-}" in
        ""|-s|--show)
            echo "TARGET = ${TARGET:-<unset>}"
            echo "NAMES  = ${TARGET_NAMES:-<none>}"
            grep -F "$_TARGET_TAG" /etc/hosts 2>/dev/null | sed 's/^/  /'
            return 0 ;;
        -c|--clear)
            unset TARGET IP TARGET_NAMES
            _target_hosts_sync
            : > "$_TARGET_STATE" 2>/dev/null
            rm -f "$HOME/.tmux-target-ip" 2>/dev/null
            tmux refresh-client -S 2>/dev/null
            echo "target cleared"; return 0 ;;
        -h|--help)
            echo "usage: target <ip> [hostname ...]   # set TARGET/IP + /etc/hosts"
            echo "       target                        # show current"
            echo "       target -c                     # clear"; return 0 ;;
    esac
    export TARGET="$1" IP="$1"; shift
    export TARGET_NAMES="$*"
    [ -n "$TARGET_NAMES" ] && _target_hosts_sync
    { echo "export TARGET='$TARGET'"; echo "export IP='$IP'"
      echo "export TARGET_NAMES='$TARGET_NAMES'"; } > "$_TARGET_STATE" 2>/dev/null
    printf '%s' "$TARGET" > "$HOME/.tmux-target-ip" 2>/dev/null   # tmux status bar
    tmux refresh-client -S 2>/dev/null
    target --show
}

# --- lhost: your attacker IP for listeners/reverse shells ($LHOST) ---------
#   lhost            # auto-detect from tun0 (then default route)
#   lhost 10.10.14.10 | lhost eth0   # set explicitly
_detect_lhost() {
    local iface="${1:-}"
    if [ -n "$iface" ] && [ "${iface#*.}" = "$iface" ]; then
        ip -4 -o addr show "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1
    elif [ -n "$iface" ]; then
        printf '%s' "$iface"                       # looks like an IP already
    else
        ip -4 -o addr show tun0 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1 \
          || ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}'
    fi
}
lhost() {
    local v; v="$(_detect_lhost "${1:-}")"
    [ -n "$v" ] || { echo "lhost: could not detect (no tun0?). Try: lhost <ip>"; return 1; }
    export LHOST="$v"; echo "LHOST = $LHOST"
}
# Set $LHOST from tun0 on shell start if not already set, so reverse shells work.
[ -z "${LHOST:-}" ] && LHOST="$(_detect_lhost)" && [ -n "$LHOST" ] && export LHOST
# Restore last target on shell start (does NOT rewrite /etc/hosts; that persists).
[ -f "$_TARGET_STATE" ] && . "$_TARGET_STATE"

# --- small aliases (the real recall layer is Ctrl-R history, not these) ----
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias ..='cd ..'; alias ...='cd ../..'
alias myip='ip -br -c addr'
alias ports='ss -tulpn'
alias tun='echo "LHOST=$LHOST"; ip -br -c addr show tun0 2>/dev/null'
alias serve='python3 -m http.server 80'          # run from where your loot is
alias serve8='python3 -m http.server 8000'
alias logs='cc-logs'
alias b64d='base64 -d'

# --- kiss handoff: scans as importable nmap XML ----------------------------
# nmapx <name> <nmap args...>  -> writes ./scans/<name>.{nmap,gnmap,xml}
# The .xml imports straight into the kiss dashboard (ScanViewer -> import).
nmapx() {
    [ -n "${1:-}" ] || { echo "usage: nmapx <name> <nmap args...>   (add sudo-only flags via: nmapx <name> -sS ... with sudo)"; return 1; }
    local name="$1"; shift
    mkdir -p scans
    nmap "$@" -oA "scans/$name"
    echo "-> scans/$name.xml  (kiss: ScanViewer -> import nmap XML)"
}
