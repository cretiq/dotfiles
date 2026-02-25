---
name: tmux-config
description: "Manage tmux configuration with TPM plugins, catppuccin theming, vim-tmux-navigator, Ghostty keybind integration, and pane styling. Use when user says tmux config, tmux keybind, tmux plugin, tmux split, tmux pane, tmux window, tmux prefix, tmux theme, tmux navigator, tmux resize, tpm plugin, tmux status bar, tmux continuum."
---

# tmux Configuration

## Purpose
tmux setup with catppuccin theming, vim-tmux-navigator for seamless pane movement, Ghostty keybind passthrough, and transparent backgrounds for appearance-aware dark/light switching.

## Architecture

### Files
- **tmux config**: `tmux/.config/tmux/tmux.conf`
- **Ghostty keybinds**: `ghostty/.config/ghostty/config` (lines 105-169 send escape sequences to tmux)
- **Zsh aliases**: `zsh/.zshrc` — `t`, `ta`, `tl`, `tn`
- **Appearance watcher**: `ghostty/scripts/appearance-watcher.sh` (updates tmux theme on mode change)

### Prefix
`C-a` (rebound from default `C-b`)

### Plugins (via TPM)
| Plugin | Purpose |
|--------|---------|
| `tmux-plugins/tpm` | Plugin manager |
| `tmux-plugins/tmux-sensible` | Sensible defaults |
| `catppuccin/tmux#v2.1.3` | Catppuccin theme |
| `tmux-plugins/tmux-resurrect` | Session save/restore |
| `tmux-plugins/tmux-continuum` | Auto-save sessions (`@continuum-restore on`) |
| `tmux-plugins/tmux-yank` | Clipboard integration |
| `christoomey/vim-tmux-navigator` | Seamless C-h/j/k/l pane navigation with nvim |

### Ghostty Keybind Integration
Ghostty sends escape sequences that tmux binds to actions:

| Ghostty Shortcut | Escape Sequence | tmux Action |
|-----------------|-----------------|-------------|
| `cmd+h/j/k/l` | `C-h/j/k/l` | vim-tmux-navigator pane switch |
| `shift+opt+minus` | `M-=` | Split horizontal |
| `shift+opt+slash` | `M--` | Split vertical |
| `shift+opt+arrows` | `M-Arrow` | Resize pane (5 cols / 3 rows) |
| `cmd+opt+w` / `cmd+shift+w` | `M-w` | Kill pane |
| `cmd+shift+k` / `cmd+opt+z` | `M-K` | Clear screen + history |
| `cmd+shift+l` / `cmd+tab` | `M-L` | Next window |
| `cmd+shift+tab` | `M-H` | Previous window |
| `cmd+t` | `M-t` | New window |
| `shift+alt+k/j` | `M-k`/`M-j` | Scroll up/down (copy-mode) |
| `ctrl+tab` / `ctrl+shift+tab` | `User0`/`User1` | Next/previous window |

### Window Naming
Auto-rename format: shell shows directory name, running app shows `app [dir]`.
```
set -g automatic-rename-format '#{?#{==:#{pane_current_command},zsh},#{b:pane_current_path},#{pane_title} [#{b:pane_current_path}]}'
```

### Catppuccin Theme Setup
1. Initial flavor detected at tmux start via `defaults read -g AppleInterfaceStyle`
2. Ongoing changes handled by appearance-watcher (see `ghostty-appearance-watcher` skill)
3. Status bar: session name (left), date/time (right), centered window list
4. Window text uses `#W` (window name) so auto-rename-format works

### Pane Styling Overrides (after catppuccin)
Catppuccin sets explicit backgrounds. These are overridden to `bg=default` so Ghostty controls the terminal background (enabling transparent dark/light switching):
```
set -g window-style "bg=default,fg=#{@thm_overlay_0}"
set -g window-active-style "bg=default,fg=#{@thm_text}"
set -g pane-border-lines double
set -g pane-active-border-style "fg=#{@thm_blue}"
set -g pane-border-style "fg=#{@thm_surface_0}"
```

## Key Gotchas

### catppuccin @thm_* variables persist across reloads
Theme files use `set -o` (only-if-not-set). Must unset all `@thm_*` before re-running `catppuccin.tmux`. Both `tmux.conf` reload block and appearance-watcher do this.

### TPM must be at bottom
`run '~/.config/tmux/plugins/tpm/tpm'` must be the last plugin line. Post-TPM overrides (like `bg=default`) go after it.

### Swedish keyboard layout
`shift+opt+minus` produces `=` and `shift+opt+slash` produces `-` on Swedish keyboard. Ghostty maps these to `M-=` and `M--` for tmux splits.

### User keys for ctrl+tab
Terminal can't distinguish `ctrl+tab` natively. Ghostty sends custom escape sequences `\e[9;5u` / `\e[9;6u` which tmux maps via `set -s user-keys`.

## Zsh Aliases
```bash
alias t="tmux"
alias ta="tmux attach -t"
alias tl="tmux list-sessions"
alias tn="tmux new -s"
```

## Config Reload
`prefix + r` reloads config and displays "Config reloaded".
