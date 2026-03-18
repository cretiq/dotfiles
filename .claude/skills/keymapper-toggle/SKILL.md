---
name: keymapper-toggle
description: "Keymapper toggle system — Voyager/Standard mode, window-switcher hotkey, adding new toggleable apps, 3-file coordination pattern, bash toggle scripts, get-all-status.sh pipe protocol, interactive-menu-toggle-remaps.bat. Use when user mentions keymapper, toggle script, voyager mode, standard mode, interactive menu, add toggle, new toggle app, bash-toggle, get-all-status, window switcher hotkey, window-switcher toggle, keymapper convention, remap toggle."
---

# Keymapper Toggle System

All files in `C:\Users\FilipM\Desktop\Keys\` (WSL: `/mnt/c/Users/FilipM/Desktop/Keys/`).

## Conventions

**Voyager = keyboard handles it natively → disable software remap.**
**Standard = software handles it → enable software remap.**

### Adding a new toggleable app requires 3 files:

1. **New bash script** `toggle-scripts/bash-toggle-<app>.sh`
   - Takes target config file as `$1` (with hardcoded default fallback)
   - Detects current state, toggles to the other, prints result

2. **`status-scripts/get-all-status.sh`** — append a new status variable and add it as the next `|`-delimited column in the final `echo`

3. **`interactive-menu-toggle-remaps.bat`** — 5 touch points:
   - `set BASH_SCRIPT_<X>=...` variable declaration
   - Add to the validation `for %%f in (...)` loop
   - Add status display line (`echo   N. App Name  [%var%]`)
   - Add `if /i "%choice%"=="N"` handler + `:toggle_N` label
   - Add conditional in both `:set_all_voyager` and `:set_all_standard`
   - Update `get_all_statuses` subroutine: `tokens=1-N`, new `set x_result=%%X`, new `& set "%N=%x_result%"` in endlocal chain
   - Update all 3 `call :get_all_statuses` callsites to pass the new variable name

### `run_toggle` convention
Passes `(BASH_SCRIPT_PATH, TARGET_FILE_PATH)` — both converted from Windows to WSL paths via `wsl wslpath -a` before being passed to bash. Pass Windows-style path (`C:\...`) for TARGET_FILE; it gets converted automatically.

## Gotchas

**INI files with multiple `hotkey` lines** — `window-switcher.ini` has `hotkey =` in both `[switch-windows]` and `[switch-apps]`. Awk must scope to the correct section:
```bash
awk '/^\[switch-windows\]/{f=1} f && /^hotkey = win\+g$/{...; f=0} {print}'
```
Without `f=0` after the first match, it would also replace `[switch-apps]`'s hotkey.

**Window-switcher requires restart** — config changes aren't picked up live. The toggle script must kill and relaunch `window-switcher.exe` via `powershell.exe` after writing the INI.

**`tokens=1-N` must match column count** — if `get-all-status.sh` outputs 7 columns but BAT says `tokens=1-6`, the 7th value silently disappears.

**`endlocal & set` chain** — each positional param (`%1`–`%N`) maps to the caller's variable. If the caller passes 7 names but the chain only has 6 `set` clauses, the 7th is silently empty.

## Coordination

`get-all-status.sh` is the single source of truth for all statuses — called once per menu render. Output is a `|`-delimited string parsed by the BAT `get_all_statuses` subroutine. Any new status column must be added to both sides consistently.

AHK hotkey `Ctrl+Win+Alt+Shift+W` triggers `restart-window-switcher.ps1` to manually restart window-switcher without a full toggle.
