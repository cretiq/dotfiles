# Keychron Q10 Max cheat sheet

Current keymap: `q10max-v6.json` (import in https://launcher.keychron.com, USB cable).
The original export `Keymap-Q10 Max ISO knob-8-17-26.json` is never overwritten. Older intermediates live in `history/`.

## Layer keys

| Key | Does |
|---|---|
| Left space | hold = L1 |
| Middle key | tap = Space, hold = L2 |
| Right big key, M1 | hold = L3 |
| PgUp | sends ⌃⌥⌘ (modifier only) |
| M3 | sends ⌃⇧⌘ (modifier only) |

## Modifier namespace per layer

Hammerspoon matches modifiers exactly, so each combo is its own namespace.

| Source | Sends | Used for |
|---|---|---|
| L1 (left space) + key | Meh (⌃⌥⇧) | Windows |
| L2 (middle key) number row, F-row | ⌥⇧⌘ | Free slots |
| L3 (right big key) + key | Hyper (⌃⌥⇧⌘) | Scripts and text |
| PgUp + key | ⌃⌥⌘ | App launchers |
| M3 + key | ⌃⇧⌘ | App launchers (same as PgUp) |

Covered keys on L1 and L3: letters, digits, `; , . /` and similar punctuation. L3 keeps the media F-row, and digits `1`–`4` keep their Keychron codes.

## Hammerspoon bindings (`hammerspoon/.hammerspoon/init.lua`)

| Press | Action |
|---|---|
| Left space + `J` / `K` / `L` / `Ö` | Focus window left / down / up / right |
| Right big key + `N` | Type `/next ` then Enter |
| Right big key + `T` | Convey translator (Hyper+T, set in Convey) |
| PgUp or M3 + `Q F A H C Z J E X B S` | Obsidian, Finder, Spotify, Claude, Edge, Bitwarden, ChatGPT, X Pro, Xcode, BetterTouchTool, Simulator |
| PgUp or M3 + `T` | Forwards Hyper+T to Convey |
| F1 | Minimize window |
| F2 | Mission Control |
| F7 / F8 / F9 / F10 | Previous / play-pause / next / mute |
| F11 / F12 | Volume down / up |
| Scroll down over a Dock icon | Minimize that app's windows |

## L2 (hold middle key)

- Left hand: Cmd+letter. Exceptions below.
- `T` Cmd+Shift+T, `F` Cmd+T, `G` and `W` Cmd+W, `Q` Cmd+Q (quits the app)
- `S` / `D`: previous / next tab (Ctrl+Shift+Tab / Ctrl+Tab)
- `U` / `P`: Cmd+Up / Cmd+Down
- `I` / `O`: Opt+Left / Opt+Right (word jump)
- `H` / `'`: Cmd+Left / Cmd+Right (line start / end)
- `J` / `K` / `L` / `Ö`: Left / Down / Up / Right
- Right big key: Cmd+Space. Middle key: back to L0.
- `Y`, Backspace, M-keys run Launcher macros (not in the export).

## L0 and knob

- Esc and Caps are swapped. F1–F12 are plain F-keys.
- Knob: volume on L0 and L2, backlight on L1, brightness on L3.

## Notes

- v5 and later overwrite Keychron's L1 RGB, Bluetooth and battery keys. v4 still has them.
- ⌃⇧⌘ + `3` / `4` is macOS's screenshot-to-clipboard shortcut, so M3 + `3` / `4` takes a screenshot.
- Keyboard firmware V1.1.0 is available but not applied.
- Receiver (Keychron Link Type A, V0.3.1) shows only as "Bootloader device" after a failed flash. Contact Keychron support before re-flashing.
