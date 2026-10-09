# Keychron Q10 Max cheat sheet

Current keymap: `q10max-v17.json` (import in https://launcher.keychron.com, USB cable).
The original export `Keymap-Q10 Max ISO knob-8-17-26.json` is never overwritten. Older intermediates live in `history/`.

## Layer keys

| Key | Does |
|---|---|
| Left space | tap = Space, hold = L1 |
| Middle key | hold = L2 (no tap) |
| Right big key | hold = L3 |
| M1 | sends ⇧⌘ (modifier only) |
| M2 | sends Hyper+F14, nothing bound |
| M3 | sends ⌃⇧⌘ (modifier only), nothing bound |
| M4, PgUp | no-op, free |
| M5 | sends ⇧⌘ + the key above Tab, opens the Convey keyboard cheat sheet |

All Launcher macros were removed in v7.

## Modifier namespace per layer

Hammerspoon and AeroSpace match modifiers exactly, so each combo is its own namespace. Only chords with 3 or 4 modifiers are used, which apps almost never claim. Left space + Shift is a different chord from left space alone, because the layer base has no Shift.

| Source | Sends | Used for |
|---|---|---|
| Left space (L1) + key | ⌃⌥⌘ | AeroSpace: focus, workspaces, layout |
| Left space + physical Shift + key | Hyper (⌃⌥⇧⌘) | AeroSpace: move, send to workspace, join, fullscreen |
| Right big key (L3) + key | Meh (⌃⌥⇧) | Hammerspoon: app launchers, text. Convey: Meh+`T` |
| Middle key (L2) number row, F-row | ⌥⇧⌘ | Free slots |
| M1 + key | ⇧⌘ | CleanShot: capture shortcuts |
| M3 + key | ⌃⇧⌘ | Free (avoid `3` / `4`, macOS screenshot) |

Covered keys on L1 and L3: letters, digits, `; , . /` and similar punctuation. L3 keeps the media F-row.

## AeroSpace (`aerospace/.config/aerospace/aerospace.toml`)

| Press | Action |
|---|---|
| Left space + `J` / `K` / `L` / `Ö` | Focus left / down / up / right |
| Left space + Shift + `J` / `K` / `L` / `Ö` | Move window left / down / up / right |
| Left space + `1`–`9` | Go to workspace |
| Left space + Shift + `1`–`9` | Send window to workspace |
| Left space + Shift + `U` / `I` / `O` / `P` | Join with left / down / up / right neighbor (stack over/under) |
| Left space + `T` | Tidy: reset layout, balance sizes |
| Left space + `/` and `,` | Tiles layout, accordion layout |
| Left space + `F` | Toggle floating |
| Left space + Shift + `F` | Fullscreen |
| Left space + `-` and `=` | Shrink and grow window |
| Left space + right big key | Spotlight (Cmd+Space) |

New windows go into the layout you are looking at. Messages and Calendar open floating instead (`on-window-detected` rules in `aerospace.toml`), so they do not reshuffle it. System Settings, Bitwarden and Convey float too.

## Window border (JankyBorders)

AeroSpace has no border of its own. JankyBorders draws it. AeroSpace starts it (`after-startup-command` in `aerospace.toml`), and it reads its settings from `borders/.config/borders/bordersrc`, stowed to `~/.config/borders` (`stow borders`).

- Install: `brew install FelixKratz/formulae/borders` (the plain name `borders` is not in Homebrew core).
- Current look: sunset gradient (orange to pink) on the focused window, dim grey on the others, 3 px, rounded, `hidpi=on`, `order=above`.
- `order=above` draws the border over the window, which looked right. It is missing from the v1.9.0 man page, so it was found by trying it.
- Try a value live with `borders width=5.0`, then put it in `bordersrc` so it survives a restart. Quote gradients, the shell reads the parentheses.
- Apply `bordersrc` after editing: `pkill -x borders; borders &`.

## Hammerspoon (`hammerspoon/.hammerspoon/init.lua`)

| Press | Action |
|---|---|
| Right big key + `Q F A H C Z J E X B S` | Obsidian, Finder, Spotify, Claude, Edge, Bitwarden, ChatGPT, X Pro, Xcode, BetterTouchTool, Simulator |
| Right big key + `T` | Convey translator (Meh+`T`, set in Convey's settings) |
| Right big key + `N` | Type `/next ` then Enter |
| F1 | Minimize window |
| F2 | Mission Control |
| F7 / F8 / F9 / F10 | Previous / play-pause / next / mute |
| F11 / F12 | Volume down / up |
| Scroll down over a Dock icon | Minimize that app's windows |

## Convey (hold M1)

| Press | Action |
|---|---|
| M1 + `J` | Cheat sheet (searchable) |
| M1 + the key above Tab, or M5 | Cheat sheet in keyboard view, with the Q10 drawn |
| Right space + `T` | Translator (Meh+`T`) |
| Left space + Shift + `M` | Free mode (Hyper+`M`) |

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

## Mac automation

The Mac layout is the master: the newest `q10max-vN.json`. Plugging the Q10 in by cable applies it, and the Windows layout is derived from it.

| Piece | Does |
|---|---|
| `q10.swift` | Mac tool, same safety rules as `q10.ps1`. Build: `swiftc -O -swift-version 5 q10.swift -o ~/.local/share/q10/q10`. Commands: `probe`, `selftest`, `dump -f x.json`, `apply -f x.json [--yes]` |
| Hammerspoon (`init.lua`) | On cable connect (PID `0x08A1`) runs `apply` with the newest Mac layout, retries 3 times, up to 150 changed keys per apply. The 2.4 GHz receiver is never written |
| `make-win.py` | Writes `q10max-win-v2.json` from the newest Mac layout. `--check` reports drift |
| Pause | Create `~/.local/share/q10/auto-off` |

Close the Keychron Launcher tab before using `q10`: with the Launcher open the keyboard answers both programs and reads become unreliable.

## Dongle (2.4 GHz) quirks on the Mac

macOS keeps its own settings per keyboard connection, and the dongle (Keychron Link) is a different keyboard from the cable.

- **Modifier keys:** the dongle had Control and Command swapped and Caps Lock turned into Escape, left over from an earlier setup. That turned Ctrl+Tab into Cmd+Tab and broke the Meh and ⇧⌘ chords. Fix: System Settings, Keyboard, Keyboard Shortcuts, Modifier Keys, pick Keychron Link, Restore Defaults.
- **Key above Tab (`§`):** over the dongle macOS reports keycode 50 instead of 10, so `§` and `<` come out swapped when typing. Changing the keyboard type in System Settings and a `hidutil` swap for the dongle both had no effect. Hammerspoon forwards ⇧⌘ + keycode 50 as ⇧⌘ + keycode 10, so M5 and M1 + `§` open Convey's keyboard cheat sheet on both connections. Side effect: on the cable ⇧⌘ + `<>` opens it too.
- Typing `§` and `<` over the dongle stays swapped. Not fixed.
- The keymap cannot be written over the dongle, only over the cable.

## Notes

- v5 and later overwrite Keychron's L1 RGB, Bluetooth and battery keys, and v13 does the same to the L3 digits `1`–`4` (Bluetooth / 2.4G switching, `0x7e0b`–`0x7e0e`, which I never verified). v4 still has them.
- ⌃⇧⌘ + `3` / `4` is macOS's screenshot-to-clipboard shortcut, so M3 + `3` / `4` takes a screenshot.
- Keyboard firmware V1.1.0 is available but not applied.
- Receiver (Keychron Link Type A, V0.3.1) shows only as "Bootloader device" after a failed flash. Contact Keychron support before re-flashing.

## On Windows

The switch stays on Mac. The Windows layout (`q10max-win-v2.json`) is the Mac layout with these changes, so GlazeWM gets the same gestures AeroSpace has on the Mac. GlazeWM and other keyboards (Voyager) are untouched: the Q10 sends the plain Alt chords GlazeWM already uses.

| Key | Mac | Windows |
|---|---|---|
| Bottom-left three keys | Cmd, Ctrl, Opt | Ctrl, Win, Alt |
| Left space + `J` / `K` / `L` / `Ö` | ⌃⌥⌘ + key (AeroSpace focus) | Alt + key (GlazeWM focus) |
| Left space + `1`–`9` | ⌃⌥⌘ + digit (go to workspace) | Alt + digit (go to workspace) |
| Left space + Shift + `J` / `K` / `L` / `Ö` | Hyper + key (AeroSpace move) | Alt+Shift + key (GlazeWM move) |
| Left space + Shift + `1`–`9` | Hyper + digit (send window) | Alt+Shift + digit (send window) |
| Left space, other keys | ⌃⌥⌘ + key | Meh (⌃⌥⇧) + key, as before |
| Right big key + key | Meh + key | Hyper + key, as before |
| M3 (hold) | ⌃⇧⌘, nothing bound | Alt+Shift: M3 + `J` / `K` / `L` / `Ö` moves the window |
| Middle key + `1`–`9` | ⌥⇧⌘ + digit, nothing bound | Alt+Shift + digit (send window) |

| Command (WSL zsh) | Does |
|---|---|
| `q10` / `q10 win` | Write the Windows layout (USB cable) |
| `q10 restore` | Write the Mac layout back (`q10max-mac-restore.json`) |
| `q10 status` | Compare the keyboard with the Windows file |
| `q10 install` | Copy the tool for `watchers.ahk`, which applies the Windows layout whenever the keyboard is plugged in by cable |

The Mac side applies its own layout automatically, see "Mac automation" above.
