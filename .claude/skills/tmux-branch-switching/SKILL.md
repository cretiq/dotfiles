---
name: tmux-branch-switching
description: "Switch between tmux and non-tmux dotfiles setups. Branch mac is clean (no tmux), branch mac-tmux has full tmux config with rose-pine/catppuccin, Ghostty keybind migration, and appearance watcher integration. Use when user says switch to tmux, go back to tmux, disable tmux, remove tmux, tmux branch, mac-tmux, switch branch, toggle tmux setup, restore tmux config, clean tmux."
---

# tmux Branch Switching

## Purpose
The dotfiles repo has two branches for switching between tmux and non-tmux terminal workflows.

## Branches

| Branch | Description |
|---|---|
| `mac` | Clean setup — Ghostty splits, no tmux |
| `mac-tmux` | Full tmux setup — rose-pine/catppuccin theme, TPM plugins, Ghostty keybinds migrated to send tmux escape sequences |

## Switching to tmux (mac -> mac-tmux)

```bash
git checkout mac-tmux
```

After checkout:
1. Symlink tmux config: `ln -sf ~/.dotfiles/tmux/.config/tmux/tmux.conf ~/.config/tmux/tmux.conf`
2. Install TPM if missing: `git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm`
3. Launch tmux, press `C-a, Shift+I` to install plugins
4. Restart appearance watcher to pick up tmux-aware version:
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.filipmellqvist.ghostty-appearance.plist
   launchctl load ~/Library/LaunchAgents/com.filipmellqvist.ghostty-appearance.plist
   ```
5. Disable macOS Cmd+H hide (needed for tmux pane nav):
   ```bash
   defaults write com.mitchellh.ghostty NSUserKeyEquivalents -dict-add "Hide Ghostty" '@~^$h'
   ```
6. Quit and relaunch Ghostty to pick up migrated keybindings

## Switching away from tmux (mac-tmux -> mac)

```bash
git checkout mac
```

After checkout:
1. Kill tmux server: `tmux kill-server`
2. Restart appearance watcher (reverts to Ghostty-only version):
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.filipmellqvist.ghostty-appearance.plist
   launchctl load ~/Library/LaunchAgents/com.filipmellqvist.ghostty-appearance.plist
   ```
3. Re-enable macOS Cmd+H hide:
   ```bash
   defaults delete com.mitchellh.ghostty NSUserKeyEquivalents
   ```
4. Quit and relaunch Ghostty to restore original keybindings

## What changes between branches

### Ghostty config (`ghostty/.config/ghostty/config`)
- **mac**: Ghostty-native splits, `goto_split` keybinds, `new_split` keybinds, Apple System Colors theme
- **mac-tmux**: Splits/nav/resize keybinds send escape sequences to tmux, Catppuccin Mocha/Latte theme

### Appearance watcher (`ghostty/scripts/appearance-watcher.sh`)
- **mac**: Updates Ghostty split fill only
- **mac-tmux**: Also updates tmux catppuccin flavor, unsets `@thm_*` vars, re-runs `catppuccin.tmux`

### nvim plugins (`nvim/.config/nvim/lua/plugins/init.lua`)
- **mac-tmux** adds `christoomey/vim-tmux-navigator` for seamless `C-h/j/k/l` pane navigation

### zsh aliases (`zsh/.zshrc`)
- **mac-tmux** adds `t`, `ta`, `tl`, `tn` tmux aliases

### tmux config (`tmux/.config/tmux/tmux.conf`)
- Only exists on **mac-tmux**
- C-a prefix, TPM plugins, rose-pine theme (with catppuccin available), vim-tmux-navigator

## Artifacts outside git
These live at runtime paths, not tracked by git:
- `~/.config/tmux/plugins/` — TPM and installed plugins (persists across branch switches)
- `~/.config/tmux/tmux.conf` — symlink to dotfiles repo
- `defaults write` for Cmd+H — macOS user defaults
