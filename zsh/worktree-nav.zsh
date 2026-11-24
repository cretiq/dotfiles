# Worktree navigation with @ prefix
# Usage: cd @<worktree> (root), @<worktree>/s (server), @<worktree>/c (client)
#        cd @<worktree>/ss (server + start), @<worktree>/cc (client + start)
# Performance: No scanning on load - only scans when Tab pressed or cd @ executed

PHOENIX_ROOT="$HOME/Dev/phoenix"

# Get worktrees - only called on demand (p1, p2, ...)
_wt_list() {
  # Native worktrees only (p1, p2, ...)
  for dir in "$PHOENIX_ROOT"/*/; do
    [[ -d "$dir" ]] || continue
    local name=${dir%/}; name=${name##*/}
    [[ -e "$dir/.git" && -d "$dir/server/Phoenix" ]] && echo "$name"
  done
}

# Resolve path
_wt_path() {
  local name="$1" sub="$2"
  case "$sub" in
    s) echo "$PHOENIX_ROOT/$name/server/Phoenix" ;;
    c) echo "$PHOENIX_ROOT/$name/client/phoenix-client" ;;
    *) echo "$PHOENIX_ROOT/$name" ;;
  esac
}

# Override cd - minimal overhead for non-@ paths
function cd {
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
      ss) builtin cd "$(_wt_path "$wt" s)" && dotnet run ;;
      cc) builtin cd "$(_wt_path "$wt" c)" && CAROOT=~/.vite-plugin-mkcert TRUST_STORES=none npx vite --host ;;
      *) echo "Usage: cd @<worktree>[/s|/c|/ss|/cc]" >&2; return 1 ;;
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
    compadd -Q -S '' "@$wt" "@$wt/s" "@$wt/c" "@$wt/ss" "@$wt/cc"
  elif [[ "$cur" == @* ]]; then
    local filter="${cur#@}"
    for wt in $(_wt_list); do
      [[ -z "$filter" || "$wt" == *"$filter"* ]] && compadd -Q -S '/' "@$wt"
    done
  else
    _cd
  fi
}

# Least recently active phoenix worktree (from treeboard cache)
_wt_least_recent() {
  local cache="$HOME/.cache/treeboard/worktrees.json"
  [[ -f "$cache" ]] || { echo "$PHOENIX_ROOT/p1"; return; }
  local result
  result=$(jq -r '.all.data | map(select(.name != "phoenix")) | sort_by(.session.last_activity // "") | .[0].path // empty' "$cache" 2>/dev/null)
  echo "${result:-$PHOENIX_ROOT/p1}"
}

# Launch Claude in a worktree
# Usage: c (plain claude) or c @<worktree>[/s|/c] (cd + claude)
#        c mr <iid>        — review MR in p1
#        c jira <key>      — analyze Jira ticket in least recently used worktree
function c {
  if [[ "$1" == "mr" && -n "$2" ]]; then
    builtin cd "$PHOENIX_ROOT/p1" && claude --model claude-sonnet-5-5 --effort high "/mr:review $2"
    return
  fi
  if [[ "$1" == "jira" && -n "$2" ]]; then
    local target=$(_wt_least_recent)
    if [[ -n "$(git -C "$target" status --porcelain)" ]]; then
      git -C "$target" stash push -u -m "auto-stash before jira $2" >/dev/null \
        && echo "Stashed uncommitted changes in $target (auto-stash before jira $2)"
    fi
    builtin cd "$target" && claude --model claude-sonnet-5-5 --effort high "/jira-analyze $2"
    return
  fi
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
    builtin cd "$target" && claude --model claude-sonnet-5-5 --effort high "${@:2}"
  else
    claude --model claude-sonnet-5-5 --effort high "$@"
  fi
}

# Continue Claude in a worktree
function cc {
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
    builtin cd "$target" && claude --continue --model claude-sonnet-5-5 --effort high "${@:2}"
  else
    claude --continue --model claude-sonnet-5-5 --effort high "$@"
  fi
}

# Launch nvim in a worktree
# Usage: v (plain nvim) or v @<worktree>[/s|/c] [files...] (cd + nvim)
function v {
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
    builtin cd "$target" && nvim "${@:2}"
  else
    nvim "$@"
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
  compdef _c_wt v
  unfunction _wt_setup_completion
}
compdef _wt_setup_completion
_wt_setup_completion

# Claude Code refuses to save settings through a symlink, so each worktree keeps
# a real .claude/settings.local.json and the shared layer loads read-only here.
# The sync runs first so links, memory and permission rules are current when the session starts.
function claude {
  local shared="$HOME/.claude_phoenix/settings.local.json"
  local role="$HOME/.claude_phoenix/orchestrator.md"
  if [[ "$PWD" == "$PHOENIX_ROOT" && -f "$shared" && -f "$role" ]]; then
    # The root is a bare container, so the all-worktrees sync skips it; CLAUDE.local.md is removed because every worktree session would also load it from this ancestor folder.
    "$HOME/.claude_phoenix/bin/sync-personal-claude.sh" --worktree "$PHOENIX_ROOT" >/dev/null 2>&1
    rm -f "$PHOENIX_ROOT/CLAUDE.local.md"
    # Model and effort come after "$@" because the c helper passes --model sonnet and the last flag wins.
    command claude --settings "$shared" --name Orchestrator \
      --strict-mcp-config --mcp-config "$HOME/.claude_phoenix/orchestrator-mcp.json" \
      --disallowedTools Edit Write NotebookEdit Agent Workflow \
        mcp__mssql_schema__execute_query mcp__claude_ai_Gmail mcp__claude_ai_Claude_Docs \
        "Bash(git push:*)" "Bash(git commit:*)" "Bash(git merge:*)" "Bash(git rebase:*)" "Bash(git reset:*)" \
        "Bash(glab mr create:*)" "Bash(glab mr merge:*)" "Bash(glab mr note:*)" \
      --append-system-prompt "$(<"$role")"$'\n\n'"$(<"$HOME/.claude_phoenix/CLAUDE.md")" \
      "$@" --model claude-opus-5-5 --effort high
  elif [[ "$PWD/" == "$PHOENIX_ROOT"/* && -f "$shared" ]]; then
    "$HOME/.claude_phoenix/bin/phoenix-claude-sync" --quiet 2>/dev/null
    command claude --settings "$shared" "$@"
  else
    command claude "$@"
  fi
}
