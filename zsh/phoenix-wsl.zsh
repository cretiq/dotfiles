# Phoenix WSL Override Manager
# Ensures per-worktree ports, PFX cert, connection-string fallback, vite proxy are correct for WSL2.
#
# Port scheme (N = trailing digit of worktree dir name, default 1):
#   Backend (Kestrel):  501N   (via settings.Development.json)
#   Vite proxy target:  501N   (via BACKEND_PORT in .env → vite.config.ts reads it)
#   Vite dev server:    517N   (via VITE_PORT in .env → vite.config.ts reads it)
#   gRPC:               5320   (shared, not per-worktree)
#
# Dual-mode scheme detection:
#   Post-refactor branches (commit 04ab0aad merged) track M5Settings.cs; pwsl patches
#   it with a TryLoadWslSystems() WSL fallback reading ~/.claude_phoenix/systems.json.
#   Pre-refactor branches still track ConnectionManager.cs; pwsl patches it with the
#   legacy .\SQLEXPRESS → localhost,1434 rewrite. Detection is per-worktree.
#
# Usage:
#   pwsl [path]        apply overrides + verify (idempotent, safe to run anytime)
#   pwsl-check [path]  verify only, no modifications
#   pwsl-save [path]   update golden copies from a working worktree
#   pwsl-install-hooks [path]  install git hooks for auto-restore after rebase/merge/checkout

readonly _PWSL_OVERRIDES="$HOME/.claude_phoenix/wsl-overrides"
readonly _PWSL_COMMON_FILES=(
  "server/Phoenix/settings.Development.json"
  "client/phoenix-client/vite.config.ts"
  "client/phoenix-client/playwright.config.ts"
)

# Auto-detect phoenix worktree root from cwd or given path
_pwsl_find_root() {
  local dir="${1:-$PWD}"
  [[ -d "$dir" ]] || { echo ""; return 1; }
  dir="$(realpath "$dir" 2>/dev/null || echo "$dir")"  # resolve to absolute
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/server/Phoenix" && -d "$dir/client/phoenix-client" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  echo ""
  return 1
}

# Extract worktree number from directory name (trailing digit). Default: 1
_pwsl_wt_number() {
  local root="$1"
  local dirname="$(basename "$root")"
  local last="${dirname: -1}"
  if [[ "$last" =~ [0-9] ]]; then
    echo "$last"
  else
    echo "1"
  fi
}

# Detect which connection-string file this worktree uses.
# Post-refactor (M5Settings.cs tracked) or pre-refactor (ConnectionManager.cs tracked).
_pwsl_scheme_file() {
  local root="$1"
  if git -C "$root" ls-files --error-unmatch server/Phoenix/M5Settings.cs &>/dev/null; then
    echo "server/Phoenix/M5Settings.cs"
  else
    echo "server/Phoenix/ConnectionManager.cs"
  fi
}

# Return "new" or "old" scheme label for the given worktree
_pwsl_scheme() {
  local sf="$(_pwsl_scheme_file "$1")"
  [[ "$sf" == *"M5Settings.cs" ]] && echo "new" || echo "old"
}

# Set or update a key=value in a .env file (creates file if missing)
_pwsl_set_env() {
  local envfile="$1" key="$2" value="$3"
  [[ -f "$envfile" ]] || touch "$envfile"
  if grep -q "^${key}=" "$envfile" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$envfile"
  else
    echo "${key}=${value}" >> "$envfile"
  fi
}

# Verify WSL overrides are correct. Returns number of failures.
_pwsl_verify() {
  local root="$1"
  local n="$(_pwsl_wt_number "$root")"
  local scheme="$(_pwsl_scheme "$root")"
  local fails=0

  local s="$root/server/Phoenix/settings.Development.json"
  local v="$root/client/phoenix-client/vite.config.ts"
  local c="$root/$(_pwsl_scheme_file "$root")"
  local envfile="$root/client/phoenix-client/.env"

  local files=("${_PWSL_COMMON_FILES[@]}" "$(_pwsl_scheme_file "$root")")

  echo "  worktree number: $n (backend=501$n, vite=517$n)"
  echo "  scheme: $scheme ($(basename "$c"))"
  echo ""

  # --- Backend port in settings.Development.json ---
  if grep -q "\"Url\": \"https://\*:501${n}\"" "$s" 2>/dev/null; then
    echo "  OK   backend port 501$n"
  else
    local actual=$(grep -o '"Url": "https://\*:[0-9]*"' "$s" 2>/dev/null)
    echo "  FAIL backend port is NOT 501$n (found: $actual)"
    ((fails++))
  fi

  # --- PFX cert ---
  if grep -q 'dev-cert.pfx' "$s" 2>/dev/null; then
    echo "  OK   PFX certificate"
  else
    echo "  FAIL certificate is NOT PFX in settings.Development.json"
    ((fails++))
  fi

  # --- Vite config uses loadEnv (not hardcoded ports) ---
  if grep -q 'loadEnv' "$v" 2>/dev/null; then
    echo "  OK   vite.config.ts uses loadEnv"
  else
    echo "  FAIL vite.config.ts does NOT use loadEnv (stale golden copy?)"
    ((fails++))
  fi

  # --- .env port vars ---
  if grep -q "^BACKEND_PORT=501${n}$" "$envfile" 2>/dev/null; then
    echo "  OK   .env BACKEND_PORT=501$n"
  else
    echo "  FAIL .env BACKEND_PORT is NOT 501$n"
    ((fails++))
  fi

  if grep -q "^VITE_PORT=517${n}$" "$envfile" 2>/dev/null; then
    echo "  OK   .env VITE_PORT=517$n"
  else
    echo "  FAIL .env VITE_PORT is NOT 517$n"
    ((fails++))
  fi

  # --- Playwright baseURL reads VITE_PORT ---
  local pw="$root/client/phoenix-client/playwright.config.ts"
  if grep -q 'process.env.VITE_PORT' "$pw" 2>/dev/null; then
    echo "  OK   playwright.config.ts reads VITE_PORT"
  else
    echo "  FAIL playwright.config.ts does NOT read VITE_PORT (stale golden copy?)"
    ((fails++))
  fi

  # --- Scheme-specific marker check ---
  if [[ "$scheme" == "new" ]]; then
    if grep -q 'pwsl-wsl-local' "$c" 2>/dev/null; then
      echo "  OK   M5Settings.cs has WSL fallback"
    else
      echo "  FAIL WSL fallback MISSING in M5Settings.cs"
      ((fails++))
    fi
    if [[ -f "$HOME/.claude_phoenix/systems.json" ]]; then
      echo "  OK   ~/.claude_phoenix/systems.json exists"
    else
      echo "  FAIL ~/.claude_phoenix/systems.json MISSING"
      echo "       fix: create it with {\"Systems\": {\"<name>\": \"<conn-string>\"}, \"GrpcPort\": 5320}"
      ((fails++))
    fi
  else
    if grep -q 'localhost,1434' "$c" 2>/dev/null; then
      echo "  OK   ConnectionManager.cs has SQL rewrite (localhost,1434)"
    else
      echo "  FAIL SQL rewrite MISSING in ConnectionManager.cs"
      ((fails++))
    fi
  fi

  # --- PFX cert file ---
  if [[ -f "$HOME/.aspnet/dev-cert.pfx" ]]; then
    echo "  OK   ~/.aspnet/dev-cert.pfx exists"
  else
    echo "  FAIL ~/.aspnet/dev-cert.pfx MISSING"
    echo "       fix: dotnet dev-certs https --export-path ~/.aspnet/dev-cert.pfx -p dev"
    ((fails++))
  fi

  # --- assume-unchanged flags ---
  local hidden_ok=true
  for f in "${files[@]}"; do
    local flag=$(git -C "$root" ls-files -v "$f" 2>/dev/null | cut -c1)
    if [[ "$flag" != "h" ]]; then
      echo "  FAIL assume-unchanged NOT set: $f"
      hidden_ok=false
      ((fails++))
    fi
  done
  $hidden_ok && echo "  OK   assume-unchanged on all 4 files"

  return $fails
}

# Apply overrides and verify
pwsl() {
  local root
  root="$(_pwsl_find_root "${1:-}")" || { echo "ERROR: not in a Phoenix worktree. Usage: pwsl ~/Dev/phoenix/p3"; return 1; }
  local n="$(_pwsl_wt_number "$root")"
  local scheme="$(_pwsl_scheme "$root")"
  echo "pwsl: $root"
  echo "scheme: $scheme"

  local files=("${_PWSL_COMMON_FILES[@]}" "$(_pwsl_scheme_file "$root")")

  # Check golden files exist
  for f in "${files[@]}"; do
    local base="$(basename "$f")"
    if [[ ! -f "$_PWSL_OVERRIDES/$base" ]]; then
      echo "ERROR: golden file missing: $_PWSL_OVERRIDES/$base"
      echo "       Run pwsl-save from a working worktree first."
      return 1
    fi
  done

  # Copy golden files (vite.config.ts reads ports from .env, no patching needed)
  for f in "${files[@]}"; do
    local base="$(basename "$f")"
    local target="$root/$f"
    local target_dir="$(dirname "$target")"
    if [[ ! -d "$target_dir" ]]; then
      echo "ERROR: target dir missing: $target_dir"
      return 1
    fi
    cp "$_PWSL_OVERRIDES/$base" "$target"
  done

  # Patch backend port in settings.Development.json (only file with hardcoded port)
  local s="$root/server/Phoenix/settings.Development.json"
  sed -i "s|https://\*:501[0-9]|https://*:501${n}|" "$s"

  # Write port vars to .env (creates if missing, preserves existing E2E vars)
  local envfile="$root/client/phoenix-client/.env"
  _pwsl_set_env "$envfile" "VITE_PORT" "517${n}"
  _pwsl_set_env "$envfile" "BACKEND_PORT" "501${n}"

  # Set assume-unchanged
  for f in "${files[@]}"; do
    git -C "$root" update-index --assume-unchanged "$f" 2>/dev/null
  done

  echo ""
  _pwsl_verify "$root"
  local rc=$?
  echo ""
  if (( rc == 0 )); then
    echo "All checks passed."
  else
    echo "$rc check(s) FAILED."
  fi

  # Sync personal CC assets (skills, commands, settings.local) into worktree's .claude/
  # Only if .claude/ is real (or absent) — won't run if it's still a legacy symlink.
  if [[ -x "$HOME/.claude_phoenix/bin/sync-personal-claude.sh" && ! -L "$root/.claude" ]]; then
    echo ""
    "$HOME/.claude_phoenix/bin/sync-personal-claude.sh" --worktree "$root" 2>&1 | tail -3
  fi

  return $rc
}

# Verify only — no modifications
pwsl-check() {
  local root
  root="$(_pwsl_find_root "${1:-}")" || { echo "ERROR: not in a Phoenix worktree."; return 1; }
  echo "pwsl-check: $root"
  echo ""
  _pwsl_verify "$root"
  local rc=$?
  echo ""
  if (( rc == 0 )); then
    echo "All checks passed."
  else
    echo "$rc check(s) FAILED — run pwsl to fix."
  fi
  return $rc
}

# Auto-check on cd — if port config is wrong, silently fix it
_pwsl_auto_check() {
  (( _PWSL_CHECKING )) && return
  [[ "$PWD" == "$HOME/Dev/phoenix"* ]] || return
  _PWSL_CHECKING=1
  local root
  root="$(_pwsl_find_root)" || { _PWSL_CHECKING=0; return; }
  local n="$(_pwsl_wt_number "$root")"
  local envfile="$root/client/phoenix-client/.env"
  grep -q "501${n}" "$root/server/Phoenix/settings.Development.json" 2>/dev/null \
    && grep -q "^VITE_PORT=517${n}$" "$envfile" 2>/dev/null \
    && grep -q "^BACKEND_PORT=501${n}$" "$envfile" 2>/dev/null \
    && { _PWSL_CHECKING=0; return; }
  echo "pwsl: auto-fixing WSL overrides for $(basename "$root")..."
  pwsl "$root" > /dev/null 2>&1
  _PWSL_CHECKING=0
}
chpwd_functions+=(_pwsl_auto_check)

# Install git hooks (post-checkout, post-rewrite, post-merge) into the Phoenix repo.
# All worktrees share hooks, so one install covers p1, p2, p3, etc.
pwsl-install-hooks() {
  local root
  root="$(_pwsl_find_root "${1:-}")" || { echo "ERROR: not in a Phoenix worktree."; return 1; }
  local git_dir=$(git -C "$root" rev-parse --git-common-dir 2>/dev/null)
  [[ -d "$git_dir/hooks" ]] || { echo "ERROR: hooks dir not found: $git_dir/hooks"; return 1; }
  local hook_src="$HOME/.dotfiles/git/hooks/phoenix-pwsl-post-hook"
  [[ -f "$hook_src" ]] || { echo "ERROR: hook script missing: $hook_src"; return 1; }
  for hook in post-checkout post-rewrite post-merge; do
    ln -sf "$hook_src" "$git_dir/hooks/$hook"
  done
  echo "Hooks installed in $git_dir/hooks/ (covers all worktrees)"
}

# Save current worktree files as new golden copies
# Golden copies use base port 5011 in settings.Development.json.
# vite.config.ts golden copy has NO hardcoded ports (uses loadEnv).
pwsl-save() {
  local root
  root="$(_pwsl_find_root "${1:-}")" || { echo "ERROR: not in a Phoenix worktree."; return 1; }

  local s="$root/server/Phoenix/settings.Development.json"
  if ! grep -q ':501[0-9]' "$s" 2>/dev/null; then
    echo "ERROR: settings.Development.json does NOT have WSL port (501x) — refusing to save."
    return 1
  fi

  local files=("${_PWSL_COMMON_FILES[@]}" "$(_pwsl_scheme_file "$root")")

  mkdir -p "$_PWSL_OVERRIDES"
  for f in "${files[@]}"; do
    cp "$root/$f" "$_PWSL_OVERRIDES/$(basename "$f")"
  done

  # Normalize settings.Development.json to base port 5001
  local gs="$_PWSL_OVERRIDES/settings.Development.json"
  sed -i 's|https://\*:501[0-9]|https://*:5011|' "$gs"

  echo "Golden copies saved (settings normalized to port 5011) at $_PWSL_OVERRIDES/"
  ls -la "$_PWSL_OVERRIDES/"
}
