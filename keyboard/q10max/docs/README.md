# Keychron Q10 Max cheat sheet

Current keymap: `q10max-v13.json` (import in https://launcher.keychron.com, USB cable).
The original export `Keymap-Q10 Max ISO knob-8-17-26.json` is never overwritten. Older intermediates live in `history/`.

## Layer keys

| Key | Does |
|---|---|
| Left space | hold = L1 |
| Middle key | tap = Space, hold = L2 |
| Right big key | hold = L3 |
| M1 | sends ⇧⌘ (modifier only) |
| M2 | tap = Ghostty show/hide (Hyper+F14) |
| M3 | sends ⌃⇧⌘ (modifier only) |
| M4, M5, PgUp | no-op, free |

All Launcher macros were removed in v7.

## Modifier namespace per layer

Hammerspoon and AeroSpace match modifiers exactly, so each combo is its own namespace.

| Source | Sends | Used for |
|---|---|---|
| L1 (left space) + key | Meh (⌃⌥⇧) | AeroSpace: focus, workspaces, layout |
| L2 (middle key) number row, F-row | ⌥⇧⌘ | AeroSpace: send window to workspace |
| L3 (right big key) + key | Hyper (⌃⌥⇧⌘) | Hammerspoon: app launchers, text |
| M1 + key | ⇧⌘ | CleanShot: capture shortcuts |
| M3 + key | ⌃⇧⌘ | AeroSpace: move, join, fullscreen |

Covered keys on L1 and L3: letters, digits, `; , . /` and similar punctuation. L3 keeps the media F-row.

## AeroSpace (`aerospace/.config/aerospace/aerospace.toml`)

| Press | Action |
|---|---|
| Left space + `J` / `K` / `L` / `Ö` | Focus left / down / up / right |
| Left space + `1`–`9` | Go to workspace |
| Left space + `T` | Tidy: reset layout, balance sizes |
| Left space + `/` and `,` | Tiles layout, accordion layout |
| Left space + `F` | Toggle floating |
| Left space + `-` and `=` | Shrink and grow window |
| M3 + `J` / `K` / `L` / `Ö` | Move window left / down / up / right |
| M3 + `U` / `I` / `O` / `P` | Join with left / down / up / right neighbor (stack over/under) |
| M3 + `F` | Fullscreen |
| Middle key + `1`–`9` | Send window to workspace |
| Left space + right big key | Spotlight (Cmd+Space) |

## Hammerspoon (`hammerspoon/.hammerspoon/init.lua`)

| Press | Action |
|---|---|
| Right big key + `Q F A H C Z J E X B S` | Obsidian, Finder, Spotify, Claude, Edge, Bitwarden, ChatGPT, X Pro, Xcode, BetterTouchTool, Simulator |
| Right big key + `T` | Convey translator (Hyper+T, set in Convey) |
| Right big key + `N` | Type `/next ` then Enter |
| M2 | Show/hide Ghostty |
| F1 | Minimize window |
| F2 | Mission Control |
| F7 / F8 / F9 / F10 | Previous / play-pause / next / mute |
| F11 / F12 | Volume down / up |
| Scroll down over a Dock icon | Minimize that app's windows |

## CleanShot (hold M1)

| Press | Action |
|---|---|
| M1 + `2` / `3` / `4` / `5` | Capture window / OCR / area / all-in-one |
| M1 + `E` | Pin last screenshot |
| M1 + `1` / `6` | Close / restore overlays |

## L2 (hold middle key)

- Left hand: Cmd+letter. Exceptions below.
- `T` Cmd+Shift+T, `F` Cmd+T, `G` and `W` Cmd+W, `Q` Cmd+Q (quits the app)
- `S` / `D`: previous / next tab (Ctrl+Shift+Tab / Ctrl+Tab)
- `U` / `P`: Cmd+Up / Cmd+Down
- `I` / `O`: Opt+Left / Opt+Right (word jump)
- `H` / `'`: Cmd+Left / Cmd+Right (line start / end)
- `J` / `K` / `L` / `Ö`: Left / Down / Up / Right
- Enter: Cmd+Enter. Backspace: Cmd+Backspace.
- Right big key: Cmd+Space. Middle key: back to L0.

## L0 and knob

- Esc and Caps are swapped. F1–F12 are plain F-keys.
- Knob: volume on L0 and L2, backlight on L1, brightness on L3.

## Notes

- v5 and later overwrite Keychron's L1 RGB, Bluetooth and battery keys, and v13 does the same to the L3 digits `1`–`4` (Bluetooth / 2.4G switching, `0x7e0b`–`0x7e0e`, which I never verified). v4 still has them.
- ⌃⇧⌘ + `3` / `4` is macOS's screenshot-to-clipboard shortcut, so M3 + `3` / `4` takes a screenshot.
- Keyboard firmware V1.1.0 is available but not applied.
- Receiver (Keychron Link Type A, V0.3.1) shows only as "Bootloader device" after a failed flash. Contact Keychron support before re-flashing.
