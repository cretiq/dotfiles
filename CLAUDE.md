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

## Zsh Configuration

Local secrets and machine-specific settings go in `~/.zshrc.local` (git-ignored):
- Jira credentials: `JIRA_API_TOKEN`, `JIRA_EMAIL`
- Any machine-specific exports

See template in `~/.zshrc.local` (created on first use).

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

## AutoHotkey & Keyboard Remaps

Config: `windows-keys/` (symlink to `C:\Users\FilipM\Desktop\Keys\`)

- **`hotkeys-and-remaps.ahk`** — App launcher hotkeys (Ctrl+Alt+Shift+Win combinations) and `LCtrl+LAlt+1–6` (`<^<!`, left keys only: AltGr = Ctrl+Alt would swallow `@ £ $ €` on the Swedish layout) → Edge `https://localhost:5171–5176`. Supports left/right modifier distinction via `<^<#<!<+` (left) / `>^>#>!>+` (right) prefixes.
- **`watchers.ahk`** — Background watchers, Startup shortcut `watchers.lnk`, versioned copy `ahk/watchers.ahk`: starts/stops GlazeWM by dock, blocks Win+arrows while it runs, forwards Win+Space, applies the Q10 Max Windows keymap on cable connect. Kept out of `hotkeys-and-remaps.ahk` because toggle scripts edit and reload that file.
- **`interactive-menu-toggle-remaps.bat`** — Interactive menu to toggle ESC/CapsLock, Alt+HJKL, per-app HJKL/JKLÖ remaps, and Window Switcher mode (Voyager/Standard).
- **`restart-window-switcher.ps1`** — Bound to Ctrl+Alt+Shift+Win+6. Kills and restarts the window-switcher process.
- **`toggle-scripts/`** — Bash wrappers for ESC, Alt+HJKL, and other toggles.
- **`status-scripts/`** — Display current remap status.

## Convey (hotkey app + cheat sheets)

Windows app. Registers its own global hotkeys (`hotkeys.rs`; a key already taken is rejected, message names the owner) and shows per-app shortcut cheat sheets. Settings: `%LOCALAPPDATA%\Convey\settings.json` (`/mnt/c/Users/FilipM/AppData/Local/Convey/`).

- **Global hotkeys in use:** `Ctrl+Alt+Shift+M` capture memory, `Ctrl+Alt+Shift+J` cheat sheet, `Ctrl+Alt+Shift+Win+I` Translate, `Ctrl+Alt+Shift+Win+W` What word?, macros `Ctrl+Alt+Shift+Z` (Rename) / `Ctrl+Alt+Shift+A` (Next). Main toggle, command bar, Free mode unset. Check this list before binding any new `Ctrl+Alt+Shift(+Win)` combo in AHK, GlazeWM or Terminal.
- **Cheat sheets:** one `.md` per app in `…/Convey/cheatsheets/` (43 apps; entries are `` - `keys` — description ``). Re-read each time the window opens. Only verified shortcuts go in.
- **Keep in sync:** after changing aliases, keymaps or hotkeys here (zsh, GlazeWM, AHK, Terminal, nvim…), run `/cheatsheet --changed --light` (`~/.claude/commands/cheatsheet.md`). It finds the sheets by their `source:` line and patches only the changed entries; `--changed` alone re-verifies those sheets in full. Do not hand-edit around it. A config no sheet lists (e.g. `hotkeys-and-remaps.ahk`) is reported as `unowned`; create its sheet with `/cheatsheet <app>`.
- **Currently stale:** `zsh.md` and `claude-code.md` still list removed aliases (`ch`, `csh`, `csm`, `coh`, `com`, `ccca`, `cccu`, `cwt`) and lack `cdot`; `glazewm.md` lacks `alt+h`. The AHK Edge keys (`LCtrl+LAlt+1–6`, `Ctrl+Alt+Shift+Win+C`) live in `edge.md`; the other AHK launchers are in no sheet.

## Keyboard: Keychron Q10 Max

Files in `keyboard/q10max/`; details in the `keychron-q10-max` skill. The keyboard holds one keymap and its Mac/Win switch stays on **Mac** on both machines. Mac behaviour must never change.
- `q10max-mac-restore.json` = Mac layout. `q10max-win-v2.json` = same with Windows bottom row (Ctrl | Win | Alt) and GlazeWM gestures: left space + J/K/L/Ö or 1–9 sends Alt + key, M3 holds Alt+Shift, middle key + 1–9 sends Alt+Shift + digit. GlazeWM keeps only its Alt chords, so other keyboards (Voyager) are unaffected.
- WSL: `q10` (zsh function in `zsh/.zshrc`) swaps the layout over USB via `q10.ps1`; `q10 install` copies the tool to `%LOCALAPPDATA%\q10`, where `watchers.ahk` uses it to apply the Windows layout when the keyboard is plugged in by cable.

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

## Claude Code Aliases

Defined in `zsh/.zshrc` (lines 194-217) and `zsh/worktree-nav.zsh`. Default for everything: `claude-sonnet-5-5`, `--effort high`.

**Functions:**
- `c` — Launch Claude Code (`--model claude-sonnet-5-5 --effort high`)
- `cc` — `--continue` (`--model claude-sonnet-5-5 --effort high`)

**Model shortcuts:**
- `cr` — `--resume`
- `cs` — Sonnet high
- `co` — Opus 5.5 `[1m]`

**Scratch workspace:**
- `ccc` — cd ~/claude-scratch + launch
- `cdot` — cd ~/.dotfiles + launch

## File Structure

```
acli/          commands/      ghostty/       git/
htop/          lazygit/       macrowhisper/  my_scripts/
nvim/          powershell/    ranger/        spf/
vim/           windows-keys/  windows-terminal/             zsh/
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
