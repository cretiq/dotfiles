---
name: ghostty-appearance-watcher
description: "Manage Ghostty's appearance-aware split dimming. Watcher script updates unfocused-split-opacity and unfocused-split-fill based on macOS dark/light mode. Use when user says ghostty appearance, split dimming, ghostty dark mode, ghostty light mode, unfocused split, appearance watcher, ghostty theme switch, ghostty opacity, split fill color, launchagent ghostty."
---

# Ghostty Appearance Watcher

## Purpose
Bridges Ghostty's lack of `dark:`/`light:` support for `unfocused-split-opacity` and `unfocused-split-fill` by polling macOS appearance and updating the config file.

## Architecture

### Files
- **Watcher script**: `ghostty/scripts/appearance-watcher.sh`
- **LaunchAgent plist**: `ghostty/scripts/com.filipmellqvist.ghostty-appearance.plist`
- **Ghostty config**: `ghostty/.config/ghostty/config` (lines 36-37, managed by watcher)
- **Zsh aliases**: `zsh/.zshrc` — `ghostty-watcher-load` / `ghostty-watcher-unload`

### How It Works
1. Script polls `defaults read -g AppleInterfaceStyle` every 5 seconds
2. Tracks last known mode to skip redundant writes
3. On change, uses `sed -i ''` to update opacity + fill values in Ghostty config
4. Ghostty auto-reloads on config file change

### Current Values
| Mode  | Opacity | Fill   |
|-------|---------|--------|
| Dark  | 0.8     | 2a2a2a |
| Light | 0.8     | d0d0d0 |

### LaunchAgent
- `KeepAlive: true`, `RunAtLoad: true`
- Plist symlinked from dotfiles to `~/Library/LaunchAgents/`
- Logs to `/tmp/ghostty-appearance-watcher.log`

## Key Gotchas

### sed doesn't work on symlinks
`sed -i ''` fails with "in-place editing only works for regular files" on symlinks. The script resolves the symlink with `readlink -f` before editing.

### Restarting after value changes
Editing the script doesn't take effect until the watcher restarts. The LaunchAgent's `KeepAlive` auto-restarts it after `pkill -f appearance-watcher`.

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

## Modifying Opacity/Fill Values
Edit `ghostty/scripts/appearance-watcher.sh` — the `update_config()` function contains the dark/light values. After editing, restart the watcher (see above).
