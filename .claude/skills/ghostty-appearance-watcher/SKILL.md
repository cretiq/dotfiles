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
4. Sends `SIGUSR2` to Ghostty to force config reload (Ghostty doesn't auto-detect changes through symlinks)

### Current Values
| Mode  | Opacity | Fill   |
|-------|---------|--------|
| Dark  | 0.9     | 363636 |
| Light | 0.88    | c2c2c2 |

### LaunchAgent
- `KeepAlive: true`, `RunAtLoad: true`
- Plist symlinked from dotfiles to `~/Library/LaunchAgents/`
- Logs to `/tmp/ghostty-appearance-watcher.log`

## Key Gotchas

### sed doesn't work on symlinks
`sed -i ''` fails with "in-place editing only works for regular files" on symlinks. The script resolves the symlink with `readlink -f` before editing.

### Ghostty doesn't auto-detect config changes through symlinks
`sed -i ''` replaces the file (new inode), and Ghostty's file watcher loses track through the symlink. The watcher sends `pkill -SIGUSR2 ghostty` after each update to force a config reload. **SIGUSR2 only reloads config — it does not restart Ghostty.** Other signals will crash it.

### Restarting after value changes
Editing the script doesn't take effect until the watcher restarts. The running bash process keeps old values in memory. Use `launchctl bootout`/`bootstrap` to restart.

### LaunchAgent reload
Use `launchctl bootout gui/$(id -u)` + `launchctl bootstrap gui/$(id -u)` (modern API). The old `launchctl unload`/`load` is deprecated.

## Management

```bash
# Load (symlink plist + start)
ghostty-watcher-load

# Unload (stop + remove symlink)
ghostty-watcher-unload

# Check if running
launchctl list | grep ghostty-appearance

# Check logs
cat /tmp/ghostty-appearance-watcher.log

# Restart after editing values
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.filipmellqvist.ghostty-appearance.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.filipmellqvist.ghostty-appearance.plist
```

## Modifying Opacity/Fill Values
Edit `ghostty/scripts/appearance-watcher.sh` — the `update_config()` function contains the dark/light values. After editing, restart the watcher (see above).
