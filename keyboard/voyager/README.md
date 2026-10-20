# ZSA Voyager

Layout: Oryx `5L3pB` (https://configure.zsa.io/voyager/layouts/5L3pB/latest/0). Windows, Swedish.

| Path | What |
|---|---|
| `voyager.ps1` | `refresh`: saves the newest layout from Oryx to `%LOCALAPPDATA%\voyager\oryx-layout.json`, which Convey's cheat sheet reads |
| `firmware/` | Submodule `cretiq/voyager-firmware` (private): the layout's `keymap.c` and the workflow that compiles it |

## Change the layout

Oryx stays the editor for everyday changes. Edit there, then run `voyager.ps1 refresh`.
To change what Oryx can't, edit `firmware/keymap/keymap.c`. That copy then differs from Oryx until it is brought back in line by hand.

## Build the firmware

```sh
cd firmware
gh workflow run build.yml
gh run list --limit 1
gh run download <run-id> -n voyager-firmware -D <folder>
```

The build uses ZSA's QMK fork, branch `firmware25`, and takes about two minutes.

## Flash

1. Download `zapp` from https://github.com/zsa/zapp/releases (`zapp-windows-x86_64.zip`).
2. Run `zapp.exe flash <folder>\zsa_voyager_mine.bin`.
3. When it says it is waiting, press the Voyager's reset button. The keyboard is silent until it finishes.

`zapp` refuses a file built for a different bootloader. Oryx's own build of the same layout is the fallback: its source zip (`zipUrl` of the revision) holds the `.bin`.

## Related

The AutoHotkey scripts that type the slash commands live in `Desktop\Keys`. A pre-commit hook mirrors that folder into `windows-keys-mirror/`, so they are tracked here.
