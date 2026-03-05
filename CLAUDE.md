# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles repository for macOS and WSL2. Uses bare git repository approach for dotfiles management.

```bash
# macOS
alias config='/usr/bin/git --git-dir=/Users/filipmellqvist/.dotfiles/ --work-tree=/Users/filipmellqvist'
# WSL2
alias config='/usr/bin/git --git-dir=/home/filip/.dotfiles/ --work-tree=/home/filip'
```

## Key Tools

- **Ghostty**: Terminal emulator — `ghostty/.config/ghostty/config`
- **Zsh**: Oh My Zsh — `zsh/.zshrc`, `zsh/worktree-nav.zsh`
- **Neovim**: lazy.nvim plugin manager — `nvim/.config/nvim/init.lua`
- **Vim**: vim-plug — `vim/.vimrc`
- **Ranger**: File manager with HJKL/JKLÖ keymap integration — `ranger/`
- **SPF (Superfile)**: File manager — `spf/.spf.toml`

## Vim Keymap Management

- `vimtoggle`: Toggle between HJKL and JKLÖ keymaps
- `vimkeys status|default|custom`: Query or force keymap mode
- Integrates with Vim, VSCode/Cursor, Obsidian, Ranger (scripts in `my_scripts/.script/`)
- See `vscode-keymap-rationale` skill for Visual mode fix details.

## Windows Terminal Settings

Config: `/mnt/c/Users/FilipM/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json`
- **Unbound keys** (`"id": null`): `Ctrl+A`, `Ctrl+W` — passed through to CLI apps (Claude Code needs them)
- **Ctrl+V** kept bound for speech-to-text clipboard paste
- Unbind pattern: `{ "id": null, "keys": "ctrl+x" }`

## Keyboard Remap Toggle Menu

Interactive menu: `C:\Users\FilipM\Desktop\Keys\interactive-menu-toggle-remaps.bat` — toggles ESC/CapsLock, Alt+HJKL, per-app HJKL/JKLÖ remaps.

## Worktree Navigation (@prefix)

Quick navigation to Phoenix worktrees in `/mnt/c/Dev` (WSL) or `C:\Dev` (Windows).

- `cd @phoenix` → root, `cd @phoenix/s` → server, `cd @phoenix/c` → client
- `c @phoenix` → cd + launch Claude Code, `c @phoenix --resume` → with args
- Partial match: `cd @exp/s` → `phoenix-export/server`
- `c` is a function in `worktree-nav.zsh`, not an alias

**Config files (keep in sync):**
- PowerShell 5.1: `C:\Users\FilipM\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
- PowerShell 7+: `C:\Users\FilipM\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
- Zsh: `zsh/worktree-nav.zsh`

## File Structure

```
acli/          commands/      ghostty/       git/
htop/          lazygit/       macrowhisper/  my_scripts/
nvim/          powershell/    ranger/        spf/
vim/           windows-terminal/             zsh/
```

## Phoenix Project (WSL2 + Windows Hybrid)

- Edit in WSL2 (`~/Dev/server` -> `/mnt/c/Dev/server`)
- Run dotnet/yarn in Windows PowerShell only (firewall blocks WSL2 ports)
- Frontend: `C:\Dev\server\Phoenix\client\phoenix-client`
- Backend: `C:\Dev\server\Phoenix\server\Phoenix`
- Pre-commit: `yarn format && yarn lint && yarn test` (Windows PowerShell only)

## Git Wrappers (zsh)

Shell wrappers in `zsh/.zshrc` route git/glab through PowerShell on `/mnt/c` paths to avoid WSL2 kernel deadlocks via Plan9 filesystem. Just use git/glab normally.

**Single quotes in commit messages** — use a temp file:
```bash
echo "fix: don't break on edge case" > /tmp/cm.txt && git commit -F /tmp/cm.txt
```

## Gotchas

- Use `function name {` syntax for zsh functions, NOT `name() {` — the latter expands aliases before parsing, causing errors on re-source (`sz`)
- Do NOT use `--fill` with `--title`/`--description` in `glab mr create`
- Never run git commands in parallel on `/mnt/c` paths
