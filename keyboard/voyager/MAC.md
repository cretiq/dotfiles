# Voyager on the Mac

The firmware is the same on Mac and Windows (see `FLASHED.md` in the firmware repo for the build on the keyboard). Everything below is Mac-side and meant for the Voyager only. Other keyboards must not change.

## What is set, and what limits it to the Voyager

| What | Where | Limited to the Voyager by |
|---|---|---|
| Homerow A = Option, S = Control, D = Cmd | macOS Modifier Keys, Voyager entry | macOS keeps it per keyboard (vendor 12951, product 6519) |
| Cmd/Option+Backspace, Control+Backspace, Nav+Q, Nav+S/D tabs, top-right key, Option+J/K/L/Ö focus and Option+Control move, Control+Space (Spotlight), Alt+Cmd+digit screenshots, layer 7 slash commands | `voyagerKeyTap` in `hammerspoon/.hammerspoon/init.lua` | the tap runs only while the Voyager is attached and a Q10 receiver is not, and only acts on events with keyboard type 40 |
| Convey Mac keyboard view | Voyager tab reads `BINDINGS.md` | display only |

Limits: Hammerspoon cannot tell keyboards apart, only keyboard type. The Voyager and a Q10 on its 2.4 GHz receiver both report type 40, and so may another ANSI keyboard. Verified: the Voyager reports 40 and a Q10 on its cable reports 41. Not verified: the laptop's own keyboard.

Nothing is changed system-wide: Spotlight stays Cmd+Space, AeroSpace and Lund keep their own key bindings.

## Go back to a regular keyboard

```sh
~/.dotfiles/keyboard/voyager/mac-voyager.sh off      # pause the Hammerspoon keys, delete the Modifier Keys remap
~/.dotfiles/keyboard/voyager/mac-voyager.sh status
~/.dotfiles/keyboard/voyager/mac-voyager.sh on       # resume the Hammerspoon keys, prints the Modifier Keys values to set
```

If A, S or D still act swapped after `off`, open System Settings, Keyboard, Keyboard Shortcuts, Modifier Keys, pick Voyager and click Restore Defaults. Unplugging the Voyager also stops the Hammerspoon keys on its own.

## If the firmware homerow changes

The Modifier Keys remap assumes the firmware sends A = Alt, S = Win, D = Ctrl. Change the homerow in firmware and the Mac mapping has to change with it.

## If the laptop keyboard or the Q10 misbehaves

Run `mac-voyager.sh off` first. It makes the Voyager count as absent for Hammerspoon (the key tap and the JKLÖ rule both stand down) and deletes the Voyager's Modifier Keys remap. Then check the list below for what `off` does not undo. `mac-voyager.sh on` resumes the Hammerspoon part; the Modifier Keys values are set by hand (see `on`).

| Change | Who it can affect | Undo |
|---|---|---|
| `voyagerKeyTap` (Hammerspoon) | the Voyager, and any other keyboard that reports keyboard type 40 while the Voyager is attached. The laptop keyboard's type was not checked | `mac-voyager.sh off` |
| JKLÖ rule counts the Voyager as a desk keyboard (`syncVimKeymap`) | vim, Ghostty, Vimium C and Superfile follow the Voyager being plugged in, whichever keyboard is typed on | `mac-voyager.sh off`, or remove `or voyagerAttached()` in `syncVimKeymap` |
| Modifier Keys remap for the Voyager | the Voyager only | `mac-voyager.sh off`, or Restore Defaults in System Settings |
| Keyboard layout set to Swedish (it was U.S.) | every keyboard | `hs -c 'hs.keycodes.setLayout("U.S.")'`, or the input menu |
| U.S. keyboard layout removed, only Swedish - Pro is left (2026-10-20, so nothing can switch to English) | every keyboard | System Settings > Keyboard > Input Sources > Edit > + > English > U.S. |
| Q10 / Voyager picker in the Convey Mac cheat sheet | the Convey Mac keyboard view only | choose Q10 Max (it is remembered) |

Not changed: the Q10's layout or its auto-apply, the laptop's Modifier Keys, Spotlight (Cmd+Space), AeroSpace's key bindings, Lund's key bindings.

Git: `3c20f76` is the dotfiles commit before this work. `df2d008` adds the Voyager files and chords, `f13e1df` holds the Hammerspoon edits that were already uncommitted at the start, and later changes are in the working tree until committed.
