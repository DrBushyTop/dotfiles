if [[ -f "$HOME/scripts/opencode.local.zsh" ]]; then
  source "$HOME/scripts/opencode.local.zsh"
fi

export OPENCODE_CODE_ROOT="${OPENCODE_CODE_ROOT:-/Users/pasi/Code}"
export OPENCODE_TAILSCALE_URL="${OPENCODE_TAILSCALE_URL:-http://ocm1:4096}"

_opencode_resolve_dir() {
  local input="${1:-}"
  if [[ -z "$input" ]]; then
    print "$OPENCODE_CODE_ROOT"
  elif [[ "$input" == /* || "$input" == ~* ]]; then
    print -- ${~input}
  else
    print "$OPENCODE_CODE_ROOT/$input"
  fi
}

_opencode_pick_dir() {
  ~/scripts/opencode-pick-dir
}

ocstart() {
  sudo opencode-server start "$@"
}

ocstop() {
  sudo opencode-server stop "$@"
}

ocr() {
  sudo opencode-server restart "$@"
}

alias ocs='opencode-server status'
alias ocu='opencode-server url'

oclocal() {
  local dir="${1:-}"
  if [[ -z "$dir" ]]; then
    dir="$(_opencode_pick_dir)" || return $?
  else
    dir="$(_opencode_resolve_dir "$dir")"
  fi
  opencode-server attach "$dir"
}

ocremote() {
  local dir="${1:-}"
  local url="${2:-$OPENCODE_TAILSCALE_URL}"
  if [[ -z "$dir" ]]; then
    print -u2 'usage: ocremote <path-under-Code-or-absolute> [url]'
    return 1
  fi
  opencode attach "$url" --dir "$(_opencode_resolve_dir "$dir")"
}

oca() {
  opencode-server attach "$@"
}
