---
name: voyager
description: "ZSA Voyager (V) keyboard — how its layout is made, built, flashed and tracked; where the bindings live; changing a key, adding a chord, the Ctrl+Alt+Win layer 7, slash-command hotkeys in AutoHotkey, Oryx, zapp, voyager.ps1, patch_layout.py, BINDINGS.md. Use when the user mentions the Voyager, V, a layer, a key on it, flashing, or its chords."
---

# ZSA Voyager

The current bindings are in `keyboard/voyager/BINDINGS.md` (generated at every commit, already loaded by `CLAUDE.md`). Never type bindings by hand: they come from the files below.

## Where things live
- **Oryx** (https://configure.zsa.io/voyager/layouts/5L3pB/latest/0) is the editor for everyday changes. Claude cannot edit it. Ask the user to change a key there, then run `voyager.ps1 refresh`.
- `keyboard/voyager/voyager.ps1 refresh` saves the Oryx layout to `%LOCALAPPDATA%\voyager\oryx-layout.json`, which Convey's cheat sheet reads.
- `keyboard/voyager/firmware/` (submodule of the private `cretiq/voyager-firmware`): Oryx's `keymap.c` snapshot, `scripts/patch_layout.py` and the GitHub workflow that compiles it.
- `windows-keys/hotkeys-and-remaps.ahk` (link to `Desktop\Keys`, mirrored into `windows-keys-mirror/` at commit): what the chords do. Slash commands are typed by `SlashCommand`.

## What the build changes after Oryx
`patch_layout.py` rewrites, at build time: layer 7 (every letter and digit is `Ctrl+Alt+Win` + the Main key), the Nav top-left key (`QK_BOOT`), Nav W (`Ctrl+G`) and the top-right key (`Ctrl+Alt+Shift+K`, opens Convey's cheat sheet). Convey's `lib/voyager/patches.ts` must mirror every such rule, or the cheat sheet shows the wrong keys. Oryx and Keymapp still show the unpatched layout.

## Knock-on check before every key change
Combos match by keycode, not by position. Replacing a key silently kills every combo that used its old keycode (2026-11-11: Left Ctrl → Tab left `SPACE + Ctrl → L3` dead until a second flash). Before editing:
1. `grep` `keymap/keymap.c` for the OLD keycode: `combo*[]` arrays, mod-taps, other layers, `patch_layout.py` asserts, `scripts/bindings.py`.
2. Each hit gets fixed in the same patch (e.g. retarget the combo to the new keycode, with an `assert count == 1`), so one flash carries it. Never ship the key change alone.
3. `grep` for the NEW keycode: a combo on a keycode that already sits elsewhere also fires from that other key. Tell the user in one line.
4. Report what was retargeted. Tell the user instead of fixing only when the fix needs a choice (two keys share the keycode and the combo must stay on one).

## Change, build, flash
1. Edit `scripts/patch_layout.py` (or ask for an Oryx edit and refresh). Test it on a copy of `keymap.c` first. Raise `PATCH_VERSION` there and in Convey's `lib/voyager/patches.ts` with every rule change, and mirror the rule in `patches.ts`: Convey warns when the repo's number is higher than its own.
2. Commit and push the firmware repo, `gh workflow run build.yml`, wait about two minutes, `gh run download <id> -n voyager-firmware -D <folder>`.
3. Flash with `zapp` (`zapp.exe flash <bin>`, from https://github.com/zsa/zapp/releases). On the Windows PC it is at `%LOCALAPPDATA%\voyager\zapp.exe` (not on PATH; WSL cannot execute it directly, call it through `powershell.exe`). `zapp flash` waits for bootloader mode, so start it first (background), then the user resets: Nav + top-left key, or the reset button. Without a TTY it prints no progress bar, only `exit=0`; confirm by typing on the key.
4. Keep `oryx-original-5L3pB.bin` as the way back. Never run `zapp update`: it would flash Oryx's unpatched build.
5. Update the dotfiles submodule pointer and commit. The hook regenerates `BINDINGS.md`.

The user limits testing, compiles and rebuilds: change as little as possible per flash.
