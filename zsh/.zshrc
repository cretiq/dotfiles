export ZSH="$HOME/.oh-my-zsh"
export EDITOR="nvim"

# Load local secrets/credentials (git-ignored) — JIRA_API_TOKEN, JIRA_EMAIL, etc.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Skip compaudit checks (safe for personal systems, saves ~300ms on startup)
skip_global_compinit=1
# Disable OMZ auto-update prompt
DISABLE_AUTO_UPDATE=true
# Disable magic functions (slow on WSL2)
DISABLE_MAGIC_FUNCTIONS=true
# Ignore EOF (ctrl+d) so it doesn't close shell - allows ctrl+d in vim for page down
setopt IGNORE_EOF
# Disable flow control (ctrl+s/ctrl+q) so ctrl+s can be used in nvim
stty -ixon

alias sp="spf -c ~/.spf.toml"
alias mw="macrowhisper"
alias vim='nvim'
alias vim='nvim'
alias r='ranger'

alias obs='ranger ~/Documents/Obsidian/RCO'

alias todo='vim ~/Documents/Obsidian/RCO/TODO.md'

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# openjdk (macOS only, harmless on WSL2)
# export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# VS Code (Windows GUI app — needs .exe)
alias code='code.exe &'
alias dev='cd ~/Dev/'
alias kk='~/.dotfiles/windows-keys/interactive-menu-toggle-remaps.sh'
alias kv='~/.dotfiles/windows-keys/set-all-keymap.sh voyager'
alias ks='~/.dotfiles/windows-keys/set-all-keymap.sh standard'

# glab wrapper for phoenix worktrees
# --repo needed because worktree .git pointer files confuse repo detection.
glab() {
  if [[ "$PWD" == "$HOME/Dev/phoenix"* ]]; then
    command glab --repo m5/phoenix "$@"
    return
  fi
  command glab "$@"
}

# Fix stale netsh portproxy when gitlab.rco.local IP changes.
# Symptom: glab/git fails with "connection reset by peer" on 127.0.0.1:8888.
fix-gitlab() {
  local PWSH="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
  local ip=$($PWSH -Command "[System.Net.Dns]::GetHostAddresses('gitlab.rco.local') | Where-Object { \$_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1 -ExpandProperty IPAddressToString" 2>/dev/null | tr -d '\r')
  if [[ -z "$ip" ]]; then
    echo "DNS resolution failed for gitlab.rco.local"
    return 1
  fi
  echo "Updating port proxy: 127.0.0.1:8888 → ${ip}:80"
  $PWSH -Command "Start-Process powershell -Verb RunAs -ArgumentList '-Command netsh interface portproxy set v4tov4 listenport=8888 listenaddress=127.0.0.1 connectport=80 connectaddress=$ip'"
  echo "Done (UAC prompt may have appeared on Windows)"
}

# ============================================================
# Phoenix jcodemunch (Claude Code MCP) setup
# Sets shared index path for all Phoenix worktrees
# ============================================================
setup_phoenix_jcodemunch() {
  if [[ "$PWD" == "$HOME/Dev/phoenix"* ]]; then
    export CODE_INDEX_PATH=~/.code-index-phoenix
  else
    unset CODE_INDEX_PATH
  fi
}

# Call on shell init and on every directory change
setup_phoenix_jcodemunch
chpwd_functions+=(setup_phoenix_jcodemunch)

# ============================================================

# === ==================== ===

ZSH_THEME="af-magic"

plugins=(git)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Worktree navigation: cd @<worktree>/s or /c (after OMZ so compdef is available)
source "$HOME/.dotfiles/zsh/worktree-nav.zsh"
source "$HOME/.dotfiles/zsh/phoenix-wsl.zsh"

alias lg='lazygit'
# alias config='/usr/bin/git --git-dir=/Users/filipmellqvist/.dotfiles/ --work-tree=/Users/filipmellqvist' # Disabled on WSL2

bindkey '^[[1;5D' backward-word     # Ctrl+Left
bindkey '^[[1;5C' forward-word      # Ctrl+Right
bindkey '^W' backward-kill-word     # Ctrl+W (usually default)
bindkey '^[d' kill-word             # Alt+d (delete word forward)

spf() {
    command spf "$@"
    # Handle lastdir on macOS
    local lastdir="$HOME/Library/Application Support/superfile/lastdir"
    [[ -f "$lastdir" ]] && { . "$lastdir"; rm -f -- "$lastdir"; }
}


# dotnet (native Linux SDK — used on ~/Dev/* paths)
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"

# fnm (Fast Node Manager)
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd --log-level quiet --shell zsh)"


# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Homebrew
if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null)" || true
fi

# Local bin takes priority (must be after brew)
export PATH="$HOME/.local/bin:$PATH"

alias sz='source ~/.zshrc'


# Quick reference for custom shortcuts
_show_help() {
  cat <<'HELP'

  NAVIGATE                          NAVIGATE + CLAUDE
  ─────────────────────────────     ─────────────────────────────
  cd @<wt>      worktree root       c @<wt>       root + claude
  cd @<wt>/s    server              c @<wt>/s     server + claude
  cd @<wt>/c    client              c @<wt>/c     client + claude
  Examples: cd @phoenix/s           c @exp --resume

  CLAUDE QUICK ACTIONS
  ─────────────────────────────
  c mr <iid>   review MR in p1
  c jira <key>  analyze ticket in oldest wt

  CLAUDE CODE                       APPS & TOOLS
  ─────────────────────────────     ─────────────────────────────
  c             launch claude        r        ranger
  cc            --continue           sp       superfile
  cr            --resume             lg       lazygit
  ch            haiku model          vim      nvim
  cs            sonnet               code     vscode
  csh           sonnet high          mw       macrowhisper
  csm           sonnet max           obs      ranger in Obsidian
  co            opus                 todo     vim Obsidian TODO
  coh           opus high
  com           opus max
  ccc           claude-scratch
  ccca          scratch + analyze
  cccu          scratch + usage
  SHELL                              WORKTREE DASHBOARD
  ─────────────────────────────      ─────────────────────────────
  sz            source ~/.zshrc      w        worktree -w (live dashboard)
  ?             this help            cdwt     cd into wt repo
                                     cwt      wt repo + claude

  PHOENIX WSL
  ─────────────────────────────
  pwsl            apply WSL overrides + verify
  pwsl-check      verify only
  pwsl-save       save golden copies from current wt

  SYSTEM MAINTAINANCE
  ─────────────────────────────
  disable-alt-shift   disable Alt+Shift language switch

  WINDOWS TERMINAL
  ─────────────────────────────
                                    C-S-Up/Down   scroll line
                                    C-S-PgUp/Dn   scroll page

HELP
}
alias '?'='_show_help'

# Claude Code aliases
# c is a function in worktree-nav.zsh: c @phoenix launches claude in worktree (always opus --effort max)
# cc is a function in worktree-nav.zsh: cc @phoenix launches claude --continue in worktree (always opus --effort max)
alias cr='claude --resume'
alias ch='claude --model haiku'
alias cs='claude --model sonnet'
alias csh='claude --model sonnet --effort high'
alias csm='claude --model sonnet --effort max'
alias co='claude --model "opus[1m]"'
alias coh='claude --model "opus[1m]" --effort high'
alias com='claude --model "opus[1m]" --effort max'
alias ccc='cd ~/claude-scratch && claude'
alias ccca='cd ~/claude-scratch && claude --model haiku /analysis:processes'
alias cccu='cd ~/claude-scratch && claude /usage'
# Windows Terminal CLI wrapper (wt.exe is a UWP alias, invoke via PowerShell)
wt() {
  powershell.exe -NoProfile -Command "wt.exe $args"
}

alias cco='node ~/Dev/cco-tui/bin/cli.mjs'
alias tb='cargo run --manifest-path ~/Dev/treeboard-ratatui/Cargo.toml'
alias w='worktree -w'
alias cdwt='cd ~/.local/src/wt'
alias cwt='cd ~/.local/src/wt && claude'

# System utilities
disable-alt-shift() {
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'C:\Dev\Own\scripts\disable-alt-shift-lang.ps1'
}

# Auto-run init script from treeboard WT pane launch (must be after PATH setup)
[[ -f /tmp/wt-init.zsh ]] && { source /tmp/wt-init.zsh; rm -f /tmp/wt-init.zsh }

# fnm
FNM_PATH="/home/filip/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi
