---
description: Refresh the Convey Mac cheat sheets from the config files they describe
allowed-tools: Read, Edit, Glob, Grep, Bash(ls:*), Bash(date:*), Bash(defaults read:*)
argument-hint: [sheet name, e.g. hammerspoon | empty = all sheets]
---

# /update-convey-cheatsheets — bring Convey Mac cheat sheets up to date

Scope: $ARGUMENTS

Sheets live in `~/Library/Application Support/Convey/cheatsheets/*.md`. Empty scope → every sheet. A name → only that sheet.

## Per sheet

1. Read the sheet. Its `source:` line names what it describes.
2. Read every source for real. A `~/.config/...` path is a stow link into `~/.dotfiles`, so read it through the link. Source not readable → skip that sheet and say which source was missing. Never write from memory.
3. For `defaults` sources read single keys only (`defaults read <domain> <key>`). Never run a bare `defaults read <domain>`: Convey's own domain holds API keys in plain text.
4. Rebuild the content between `<!-- generated:start -->` and `<!-- generated:end -->` so it matches the sources: same headings, one bullet per shortcut, `` `Ctrl+Alt+Shift+Cmd+K` — what it does ``. Modifier order Ctrl, Alt, Shift, Cmd. Keep existing wording for shortcuts that did not change.
5. Changed anything → set `verified:` to today's date (`date +%F`). Unchanged → leave the file alone, `verified:` included.

Edit only inside the markers and the `verified:` line. Touch no file outside the cheatsheets folder. Do not commit.

## Report

One line per sheet: `updated`, `already current`, or `skipped (reason)`. For updated sheets, list what was added, removed or changed. Nothing else.
