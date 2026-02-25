---
name: ghostty-appearance-watcher
description: "Manage the macOS appearance watcher that syncs Ghostty split dimming and tmux catppuccin theme with dark/light mode. Polls AppleInterfaceStyle, updates split fill colors and tmux flavor. Use when user says appearance watcher, split dimming, ghostty dark mode, ghostty light mode, unfocused split, tmux theme switch, catppuccin flavor, split fill color, launchagent ghostty, watcher script, dark light sync, tmux appearance."
---

# Appearance Watcher

## Purpose
Polls macOS `AppleInterfaceStyle` every 5s and updates two targets:
1. **Ghostty** — `unfocused-split-fill` color (catppuccin mantle values)
2. **tmux** — `@catppuccin_flavor` + unsets `@thm_*` variables so catppuccin re-applies

## Architecture

### Files
- **Watcher script**: `ghostty/scripts/appearance-watcher.sh`
- **LaunchAgent plist**: `ghostty/scripts/com.filipmellqvist.ghostty-appearance.plist`
- **Ghostty config**: `ghostty/.config/ghostty/config` (lines managed: `unfocused-split-opacity`, `unfocused-split-fill`)
- **tmux config**: `tmux/.config/tmux/tmux.conf` (initial flavor detection at line 79)
- **Zsh aliases**: `zsh/.zshrc` — `ghostty-watcher-load` / `ghostty-watcher-unload`

### How It Works
1. Polls `defaults read -g AppleInterfaceStyle` every 5 seconds
2. Tracks last known mode to skip redundant writes
3. On change:
   - **Ghostty**: `sed -i ''` updates opacity + fill in resolved config path
   - **tmux**: Sets `@catppuccin_flavor` to mocha/latte, unsets all `@thm_*` variables (theme files use `-o` flag), then re-runs `catppuccin.tmux`
4. Ghostty auto-reloads on config file change; tmux re-applies immediately

### Current Values
| Mode  | Opacity | Ghostty Fill | tmux Flavor |
|-------|---------|-------------|-------------|
| Dark  | 0.8     | `181825` (catppuccin mocha mantle) | `mocha` |
| Light | 0.8     | `e6e9ef` (catppuccin latte mantle) | `latte` |

### tmux Theme Switching Detail
The watcher unsets all `@thm_*` variables before re-running catppuccin because the theme plugin uses `set -o` (only-if-not-set). Without unsetting, stale color values persist from the previous flavor.

Variables unset: `bg fg crust mantle rosewater flamingo pink mauve red maroon peach yellow green teal sky sapphire blue lavender overlay_0 overlay_1 overlay_2 surface_0 surface_1 surface_2 subtext_0 subtext_1`

### LaunchAgent
- `KeepAlive: true`, `RunAtLoad: true`
- Plist symlinked from dotfiles to `~/Library/LaunchAgents/`
- Logs to `/tmp/ghostty-appearance-watcher.log`

## Key Gotchas

### sed doesn't work on symlinks
`sed -i ''` fails with "in-place editing only works for regular files" on symlinks. The script resolves the symlink via `python3 os.path.realpath()` (macOS `readlink` lacks `-f`).

### tmux server must be running
`update_tmux()` checks `tmux list-sessions` first — silently skips if no server is running.

### Restarting after value changes
Editing the script doesn't take effect until the watcher restarts. `KeepAlive` auto-restarts after `pkill -f appearance-watcher`.

### LaunchAgent reload
Must `launchctl unload` before `launchctl load` — loading an already-registered agent fails with I/O error.

## Management

```bash
# Load (symlink plist + start)
ghostty-watcher-load

# Unload (stop + remove symlink)
ghostty-watcher-unload

# Check if running
ps aux | grep appearance-watcher

# Check logs
cat /tmp/ghostty-appearance-watcher.log

# Restart after editing values
pkill -f appearance-watcher
# KeepAlive auto-restarts it
```

## Modifying Values
Edit `ghostty/scripts/appearance-watcher.sh` — `update_ghostty()` has fill/opacity values, `update_tmux()` has flavor mapping. Restart watcher after editing.
