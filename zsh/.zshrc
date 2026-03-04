export ZSH="$HOME/.oh-my-zsh"
export EDITOR="nvim"

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
  "/mnt/c/Users/FilipM/scoop/shims"                  # glab.exe, other scoop tools
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

# Smart glab wrapper: PowerShell only in phoenix worktrees (Windows git dir resolution)
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
  powershell -Command "cd '${win_cwd}' ; glab.exe ${ps_args[*]}"
}

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

# Quick reference for custom shortcuts
_show_help() {
  cat <<'HELP'

  NAVIGATE                          NAVIGATE + CLAUDE
  ─────────────────────────────     ─────────────────────────────
  cd @<wt>      worktree root       c @<wt>       root + claude
  cd @<wt>/s    server              c @<wt>/s     server + claude
  cd @<wt>/c    client              c @<wt>/c     client + claude

  Examples: cd @phoenix/s           c @exp --resume

  CLAUDE CODE                       APPS & TOOLS
  ─────────────────────────────     ─────────────────────────────
  c             launch claude        r        ranger
  cc            --continue           sp       superfile
  cr            --resume             lg       lazygit
  ccc           claude-scratch       vim      nvim
  ccca          scratch + analyze    code     vscode
  cccu          scratch + usage      mw       macrowhisper
                                     obs      ranger in Obsidian
  SHELL                              todo     vim Obsidian TODO
  ─────────────────────────────
  sz            source ~/.zshrc     WT DASHBOARD
  ?             this help           ─────────────────────────────
                                     w        wt -w (live dashboard)
  WINDOWS TERMINAL                   cdwt     cd into wt repo
  ─────────────────────────────      cwt      wt repo + claude
                                    C-S-Up/Down   scroll line
                                    C-S-PgUp/Dn   scroll page

HELP
}
alias '?'='_show_help'

# Claude Code aliases
# c is a function in worktree-nav.zsh: c @phoenix launches claude in worktree
# cc is a function in worktree-nav.zsh: cc @phoenix launches claude --continue in worktree
alias cr='claude --resume'
alias ccc='cd ~/claude-scratch && claude'
alias ccca='cd ~/claude-scratch && claude /analysis:analyze-processes'
alias cccu='cd ~/claude-scratch && claude /usage'
alias w='wt -w'
alias cdwt='cd ~/.local/src/wt'
alias cwt='cd ~/.local/src/wt && claude'
