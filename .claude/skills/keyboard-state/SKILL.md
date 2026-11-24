---
name: keyboard-state
description: Read the keys the user latched down in Convey's cheat sheet press mode, and the key-naming grid (r1c1, t3). Use when the user says "bind this", "the keys I pressed", "the state", "cs", names a key like r4c12 or t3, or asks what they hold down in the cheat sheet.
---

# Keyboard press state

Convey's cheat sheet has a "Press keys" toggle (`Ctrl+K`). In it, a click latches a key down and a second click releases it. `Esc` releases all, a second `Esc` leaves the mode. Every change rewrites the state file.

## Read it
`/mnt/c/Users/FilipM/AppData/Local/Convey/keyboard-state.json` (Windows: `%LOCALAPPDATA%\Convey\keyboard-state.json`). Read it with the Read tool each time: it is the live state and the file is large (80+ shortcut entries).

Fields:
- `keyboard`: `Voyager` or Q10. `layer`: the layer shown. `pressMode`: false means nothing is latched. `updated`: UTC time of the last change, check it is recent.
- `held[]`: each held key as `id`, `label`, `bindings` (tap/hold per layer) and `combos` (partners, `output`).
- `shortcuts[]`: listed shortcuts matching the held keys, `match` is `exact` or `longer`. `shortcutScope` is the app filter.

Empty `held` or old `updated` → say so, do not guess keys.

## Key names (counted from 1)
Voyager: rows `r1` (top) to `r4`, columns `c1`–`c12` left to right (left half `c1`–`c6`, right half `c7`–`c12`), thumbs `t1`–`t4`.

| Name | Key on Main |
|---|---|
| `r4c1` | `A / hold L6` |
| `r4c12` | `TAB` (bottom-right) |
| `r2c1` | `TAB` (second row left) |
| `t1` | hold L1 (left outer) |
| `t2` | `SPACE / hold L2` (left inner) |
| `t3` | `ENTER / hold Ctrl` (right inner) |
| `t4` | `BSPC / hold Shift` (right outer) |

`BINDINGS.md` still prints rows `r0`–`r3`: add 1 to its row numbers. Q10: matrix `r<row>c<col>`, counted from 1.

## Binding a state
"Bind {state} to X": read the file, name the held keys in this grid, then change the firmware through the `voyager` skill (knock-on check first: combos match by keycode, so a `TAB` combo fires from both Tab keys). Convey's `patches.ts` must mirror every `patch_layout.py` rule, with `PATCH_VERSION` equal to the script's.

Convey code: `convey-tauri/frontend/src/components/cheatsheet/{CheatSheetApp,KeyboardPanel}.tsx`, `lib/board.ts`; the file is written by `src-tauri/src/commands/cheatsheet_cmd.rs`. New Convey code needs `/rebuild` to go live.
