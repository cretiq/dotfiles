---
name: keymapper-toggle
description: "Keymapper toggle system — Voyager/Standard mode, two-keyboard HJKL/JKLÖ problem, window-switcher hotkey, adding new toggleable apps, bash toggle scripts, get-all-status.sh pipe protocol, interactive menu, set-all-keymap, kk/kv/ks aliases, AHK dirty flag pattern, --no-reload convention, set_if_needed idempotency. Use when user mentions keymapper, toggle script, voyager mode, standard mode, interactive menu, add toggle, new toggle app, bash-toggle, get-all-status, window switcher hotkey, window-switcher toggle, keymapper convention, remap toggle, kk, kv, ks, set-all-keymap."
---

# Keymapper Toggle System

## What This Is

The user has two keyboards: a ZSA Voyager (columnar layout where JKLÖ occupies the physical position of HJKL) and a standard keyboard. Many apps (Vim, Obsidian, Ranger, window-switcher) use HJKL for navigation. When switching keyboards, all these apps need their keybindings flipped simultaneously — doing it one-by-one is error-prone and tedious. This system provides a single command to switch all apps at once, plus per-app toggles for fine-grained control.

## User Experience

Three zsh aliases are the primary entry points:
- `kk` — opens an interactive TUI menu showing all 6 toggleable items with current status. Supports bare number to toggle, `Nv`/`Ns` to force a specific state, `V`/`S` to set everything at once.
- `kv` — non-interactively sets all apps to Voyager mode (one-liner, shows results)
- `ks` — non-interactively sets all apps to Standard mode

The 6 toggleable items: ESC/CapsLock, Alt+HJKL navigation, Vim/Neovim keymap, Obsidian keymap, Ranger keymap, Window Switcher hotkey.

## Domain Concepts

**Voyager = keyboard handles it natively → disable software remap.** The Voyager's physical layout already puts directional keys where HJKL would be, so software must NOT remap — it would double-remap.

**Standard = software handles it → enable software remap.** A standard keyboard needs software to remap HJKL to JKLÖ positions.

**AHK-managed vs. app-config toggles** — ESC and Alt+HJKL toggles work by commenting/uncommenting lines in `hotkeys-and-remaps.ahk`. All other toggles edit their app's own config file (vimrc, rc.conf, .ini). This distinction drives the `--no-reload` and `ahk_dirty` patterns.

**`keymap_state` file** — shared state file at `vim/.vim/keymap_state` (values: `custom` or `default`). Both Vim and Neovim read it. `vim-keymap-toggle.sh` writes it and also cascades to VSCode, Ghostty, and other keymap managers.

## Conventions

### Adding a new toggleable app

Two files must change, plus the new toggle script itself:

1. **New bash script** `toggle-scripts/bash-toggle-<app>.sh` — takes target config file as `$1` (with hardcoded default fallback), detects current state, toggles to the other, prints result. If the app's config is managed by AHK, support `--no-reload` flag.

2. **`status-scripts/get-all-status.sh`** — add a new status check and append the variable as the next `|`-delimited column in the final `echo`. Column order matters — consumers destructure positionally.

3. **`interactive-menu-toggle-remaps.sh`** — add the toggle path, add to validation loop, add display line, add case handlers (bare toggle + `Nv` + `Ns`), add to both `v)` and `s)` bulk-set blocks.

4. **`set-all-keymap.sh`** — add the toggle to the bulk conditional block.

The `.bat` version still exists but is secondary — update it too if maintaining parity, but the bash menu (`interactive-menu-toggle-remaps.sh`) is the primary entry point from WSL.

### `--no-reload` flag

AHK-managed toggles (ESC, Alt+HJKL) accept `--no-reload` to skip relaunching `AutoHotkey.exe` after editing the AHK file. This exists because the interactive menu may toggle multiple AHK items in sequence — launching AHK twice simultaneously from WSL causes a race condition (duplicate AHK instances). Callers track an `ahk_dirty` flag and do a single `reload_ahk` call after all AHK toggles complete.

### `set_if_needed` idempotency

Both the interactive menu and `set-all-keymap.sh` compare current state to target before toggling. This prevents unnecessary file writes and AHK reloads. The function returns exit code 0 (changed) or 1 (already correct), which callers use to conditionally set `ahk_dirty`.

## Gotchas

**INI files with multiple `hotkey` lines** — `window-switcher.ini` has `hotkey =` in both `[switch-windows]` and `[switch-apps]`. The awk command in the toggle script must scope to `[switch-windows]` and stop after the first match, otherwise it replaces both sections' hotkeys.

**Window-switcher requires restart** — config changes aren't picked up live. The toggle script must kill and relaunch `window-switcher.exe` via `powershell.exe` after writing the INI.

**Ranger sed ordering** — the four copymap substitutions must run in the correct order to avoid intermediate states where two keys map to the same direction. The current script handles this correctly but reordering the sed calls would break it.

**Vim toggle cascades** — `vim-keymap-toggle.sh` doesn't just toggle Vim. It also calls VSCode, Ghostty, and other keymap managers. Adding it to the interactive menu's bulk-set means all those apps get toggled too, which is the intended behavior but non-obvious when reading the code.

## Coordination

**`get-all-status.sh`** is the single source of truth for all statuses. It outputs a 7-column `|`-delimited string (ESC, HJKL, Vim, Neovim, Obsidian, Ranger, Window Switcher). Both the bash menu and the bat menu parse this same output. Any new column must be added to both consumers.

**`vim-keymap-toggle.sh`** (in `my_scripts/.script/`) is the Vim/Neovim coordinator. The keymapper system calls it rather than directly editing Vim config, because it manages the `keymap_state` file and cascades to multiple apps.

**AHK hotkey** `Ctrl+Win+Alt+Shift+W` triggers `restart-window-switcher.ps1` to manually restart window-switcher without a full toggle — useful when window-switcher crashes or needs a config reload outside the toggle flow.
