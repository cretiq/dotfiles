# Worktree navigation with @ prefix
# Usage: cd @<worktree> (root) or cd @<worktree>/s (server) or cd @<worktree>/c (client)
# Performance: No scanning on load - only scans when Tab pressed or cd @ executed

DEV_ROOT="/mnt/c/Dev"

# Get worktrees - only called on demand
_wt_list() {
  for dir in "$DEV_ROOT"/*/; do
    [[ -d "$dir" ]] || continue
    local name=${dir%/}; name=${name##*/}
    # Must have .git AND Phoenix server path (flat or nested)
    [[ -e "$dir/.git" ]] || continue
    [[ -d "$dir/server/Phoenix" || -d "$dir/Phoenix/server/Phoenix" ]] && echo "$name"
  done
}

# Resolve path - called on cd execution
# $2: s=server, c=client, empty=root
_wt_path() {
  local base="$DEV_ROOT/$1"

  if [[ -d "$base/server/Phoenix" ]]; then
    case "$2" in
      s) echo "$base/server/Phoenix" ;;
      c) echo "$base/client/phoenix-client" ;;
      *) echo "$base" ;;
    esac
  else
    case "$2" in
      s) echo "$base/Phoenix/server/Phoenix" ;;
      c) echo "$base/Phoenix/client/phoenix-client" ;;
      *) echo "$base/Phoenix" ;;
    esac
  fi
}

# Override cd - minimal overhead for non-@ paths
cd() {
  if [[ "$1" == @* ]]; then
    local input="${1#@}"
    input="${input%/}"  # strip trailing slash
    local wt_filter="${input%%/*}"
    local suffix="${input#*/}"
    [[ "$input" == "$suffix" ]] && suffix=""  # no / in input

    # Try exact match first, then partial
    local wt=$(_wt_list | grep -ix "$wt_filter" | head -1)
    [[ -z "$wt" ]] && wt=$(_wt_list | grep -i "$wt_filter" | head -1)
    [[ -z "$wt" ]] && { echo "No match: $wt_filter" >&2; return 1; }

    case "$suffix" in
      s|c|"") builtin cd "$(_wt_path "$wt" "$suffix")" ;;
      *) echo "Usage: cd @<worktree>[/s|/c]" >&2; return 1 ;;
    esac
  else
    builtin cd "$@"
  fi
}

# Tab completion - lazy, only scans on Tab
_cd_wt() {
  local cur="${words[CURRENT]}"
  if [[ "$cur" == @*/* ]]; then
    local wt_part="${cur#@}"; wt_part="${wt_part%%/*}"
    local wt=$(_wt_list | grep -i "$wt_part" | head -1)
    wt=${wt:-$wt_part}
    compadd -Q -S '' "@$wt" "@$wt/s" "@$wt/c"
  elif [[ "$cur" == @* ]]; then
    local filter="${cur#@}"
    for wt in $(_wt_list); do
      [[ -z "$filter" || "$wt" == *"$filter"* ]] && compadd -Q -S '/' "@$wt"
    done
  else
    _cd
  fi
}

# Launch Claude in a worktree
# Usage: c (plain claude) or c @<worktree>[/s|/c] (cd + claude)
c() {
  if [[ "$1" == @* ]]; then
    local input="${1#@}"
    input="${input%/}"
    local wt_filter="${input%%/*}"
    local suffix="${input#*/}"
    [[ "$input" == "$suffix" ]] && suffix=""

    local wt=$(_wt_list | grep -ix "$wt_filter" | head -1)
    [[ -z "$wt" ]] && wt=$(_wt_list | grep -i "$wt_filter" | head -1)
    [[ -z "$wt" ]] && { echo "No match: $wt_filter" >&2; return 1; }

    local target=$(_wt_path "$wt" "$suffix")
    builtin cd "$target" && claude "${@:2}"
  else
    claude "$@"
  fi
}

# Continue Claude in a worktree
# Usage: cc (plain claude --continue) or cc @<worktree>[/s|/c] (cd + claude --continue)
cc() {
  if [[ "$1" == @* ]]; then
    local input="${1#@}"
    input="${input%/}"
    local wt_filter="${input%%/*}"
    local suffix="${input#*/}"
    [[ "$input" == "$suffix" ]] && suffix=""

    local wt=$(_wt_list | grep -ix "$wt_filter" | head -1)
    [[ -z "$wt" ]] && wt=$(_wt_list | grep -i "$wt_filter" | head -1)
    [[ -z "$wt" ]] && { echo "No match: $wt_filter" >&2; return 1; }

    local target=$(_wt_path "$wt" "$suffix")
    builtin cd "$target" && claude --continue "${@:2}"
  else
    claude --continue "$@"
  fi
}

# Tab completion for c - worktree names or fall through to files
_c_wt() {
  local cur="${words[CURRENT]}"
  if [[ "$cur" == @*/* ]]; then
    local wt_part="${cur#@}"; wt_part="${wt_part%%/*}"
    local wt=$(_wt_list | grep -i "$wt_part" | head -1)
    wt=${wt:-$wt_part}
    compadd -Q -S '' "@$wt" "@$wt/s" "@$wt/c"
  elif [[ "$cur" == @* || -z "$cur" ]]; then
    local filter="${cur#@}"
    for wt in $(_wt_list); do
      [[ -z "$filter" || "$wt" == *"$filter"* ]] && compadd -Q -S '/' "@$wt"
    done
  else
    _files
  fi
}

# Register completions
_wt_setup_completion() {
  compdef _cd_wt cd
  compdef _c_wt c
  compdef _c_wt cc
  unfunction _wt_setup_completion
}
compdef _wt_setup_completion
_wt_setup_completion
