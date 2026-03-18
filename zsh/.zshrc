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
alias v='nvim'
alias r='ranger'

alias obs='ranger /mnt/c/Users/FilipM/Documents/Obsidian/RCO'

alias todo='vim /mnt/c/Users/FilipM/Documents/Obsidian/RCO/TODO.md'

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# openjdk (macOS only, harmless on WSL2)
# export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# ============================================================
# WINDOWS INTEROP (appendWindowsPath=false in wsl.conf)
# Only explicitly listed paths are available from WSL
# NOTE: PowerShell path causes input lag - use alias with full path instead
# ============================================================
WIN_PATHS=(
  "/mnt/c/Users/FilipM/AppData/Local/Programs/glab"   # glab.exe
  "/mnt/c/Users/FilipM/AppData/Local/Programs/Microsoft VS Code"  # code.exe
)
export PATH="${(j.:.)WIN_PATHS}:$PATH"

# Ensure Linux-native binaries take priority (prevents WSL/Plan9 deadlocks)
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Windows tool aliases (use .exe versions for corporate network/services access)
# NOTE: git.exe removed - causes WSL kernel deadlocks via Plan9 filesystem crossings
alias dotnet='dotnet.exe'
# glab: function wrapper below handles PowerShell quoting on /mnt/c paths
alias code='code.exe &'
alias powershell='/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe'
alias powershell.exe='/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe'

alias cdev='cd /mnt/c/Dev/'
alias cown='cd /mnt/c/Dev/Own/'
alias dev='cd ~/Dev/'

# Smart git wrapper: PowerShell on /mnt/c (avoids Plan9 deadlocks), native elsewhere
# Each arg is wrapped in PS single-quotes so parens, spaces, colons are all literal
git() {
  if [[ "$PWD" != /mnt/c/* || "$PWD" == /mnt/c/Dev/Own/* ]]; then
    command git "$@"
    return
  fi
  local win_cwd ps_args=()
  win_cwd="$(wslpath -w .)"
  for arg in "$@"; do
    # Wrap each arg in PS single quotes; escape embedded ' as ''
    ps_args+=("'${arg//\'/'\''}'")
  done
  powershell -Command "\$env:PATH = 'C:\Users\FilipM\AppData\Local\MinGit\cmd;' + \$env:PATH ; cd '${win_cwd}' ; git ${ps_args[*]}"
}

# glab wrapper for phoenix worktrees
# WHY PowerShell: WSL can't reach corporate GitLab (Global Secure Access/SASE routes
#   traffic through Windows network stack only). glab.exe runs via PS to use Windows networking.
# WHY --repo: glab.exe can't resolve git worktree .git pointer files (produces mixed
#   WSL/Windows paths like /mnt/c/.../C:/Dev/...). --repo bypasses local git resolution.
# WHY phoenix* only: other repos (e.g. /mnt/c/Dev/Own) don't need this.
glab() {
  if [[ "$PWD" != /mnt/c/Dev/phoenix* ]]; then
    command glab.exe "$@"
    return
  fi
  local win_cwd ps_args=()
  win_cwd="$(wslpath -w .)"
  for arg in "$@"; do
    ps_args+=("'${arg//\'/'\''}'")
  done
  powershell -Command "cd '${win_cwd}' ; glab.exe --repo m5/phoenix ${ps_args[*]}"
}

# ============================================================
# Phoenix jcodemunch (Claude Code MCP) setup
# Sets shared index path for all Phoenix worktrees
# ============================================================
_setup_phoenix_jcodemunch() {
  if [[ "$PWD" == /mnt/c/Dev/phoenix* ]]; then
    export CODE_INDEX_PATH=~/.code-index-phoenix
  else
    unset CODE_INDEX_PATH
  fi
}

# Call on shell init and on every directory change
_setup_phoenix_jcodemunch
chpwd_functions+=(_setup_phoenix_jcodemunch)

# ============================================================

# === ==================== ===

ZSH_THEME="af-magic"

plugins=(git)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Worktree navigation: cd @<worktree>/s or /c (after OMZ so compdef is available)
source "$HOME/.dotfiles/zsh/worktree-nav.zsh"

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

# Run init script when pane opened via wt split-pane
if [[ -f /tmp/wt-init.zsh ]]; then
  source /tmp/wt-init.zsh
  rm -f /tmp/wt-init.zsh
fi

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
  c mr <iid>    review MR in phoenix
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
alias ccca='cd ~/claude-scratch && claude --model haiku /analysis:analyze-processes'
alias cccu='cd ~/claude-scratch && claude /usage'
alias cv='powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Dev\Own\Convey\dev.ps1"'
# Windows Terminal CLI wrapper (wt.exe is a UWP alias, invoke via PowerShell)
wt() {
  powershell.exe -NoProfile -Command "wt.exe $args"
}

alias tb='cargo run --manifest-path ~/Dev/treeboard-ratatui/Cargo.toml'
cmr() { cd /mnt/c/Dev/phoenix && claude --model "opus[1m]" --effort high "/mr:review $1"; }
alias w='worktree -w'
alias cdwt='cd ~/.local/src/wt'
alias cwt='cd ~/.local/src/wt && claude'

# Auto-run init script from treeboard WT pane launch (must be after PATH setup)
[[ -f /tmp/wt-init.zsh ]] && { source /tmp/wt-init.zsh; rm -f /tmp/wt-init.zsh }
