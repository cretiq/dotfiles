# Prompt: build my own vim-style Safari extension

You are building a personal macOS Safari Web Extension that gives vim-style keyboard navigation, plus a native settings app. I am an experienced developer, I write native Swift/SwiftUI macOS apps, and I want you to make the technical decisions and report them. Ask a question only if you are blocked on something only I can answer.

## Why this exists

I use Safari with vim extensions (Vimari, Vimlike). Both fail me in the same two ways:

1. **They cannot be automated.** Their settings live in the extension's own protected container, which my scripts cannot read or write. I switch between keyboards (laptop, a Keychron Q10 and a ZSA Voyager) and want the scroll keys to follow the keyboard automatically: HJKL on the laptop, JKLÖ on the others. A script (Hammerspoon) has to be able to change the keymap, and the change must apply without reloading pages.
2. **The look and the settings UI are weak.** Vimari's link hints are a fixed yellow. I want a modern look and a good settings interface.

## What to build

A Safari Web Extension plus a container macOS app, in `~/CursorProjects/macapps/<name>` (pick a short name). Git repo, conventional commits (`type(scope): description`, lowercase, max 72 chars, a body grouped by concern), no `Co-Authored-By` trailer, no AI attribution anywhere.

### 1. The config file is the single source of truth

- One JSON file at `~/.config/<name>/config.json`. The settings app, scripts and the extension all use it.
- It holds: `activePreset`, `presets` (named keymaps), `hints` (characters, theme, colors, font, size), `excludedSites`, `timeouts`, `options`.
- Ship two presets: `hjkl` (default) and `jklo` (j = scroll left, k = down, l = up, ö = right; everything else as in `hjkl`).
- A script must be able to switch preset with one command, for example `<name>ctl preset jklo`, which edits the file atomically. Hammerspoon will call it when a keyboard is plugged in.
- The extension must pick up a changed file **without** a page reload (watch the file, push the change to open tabs).
- The Safari extension is sandboxed and cannot read `~/.config` by itself. Research with current Apple docs (use Context7 or the Apple developer docs, do not rely on memory) how to bridge this on a **personal, non-App-Store** build: for example the unsandboxed container app watching the file and copying it into an App Group container, or an entitlement such as a home-relative read exception. Pick the approach that works on current macOS, verify it by running it, and tell me which one and why.
- Note: macOS blocks other processes from reading another app's container. Make sure my scripts only need to touch `~/.config/<name>/config.json`, never a container.

### 2. The extension

- Modes: normal, insert (while a text field has focus; Esc leaves), hint, find.
- Commands to support (all remappable): scroll left/down/up/right, half page up/down, page up/down, top (`g g`), bottom (`G`), link hints (`f`), link hints in a new tab (`F`), next/previous link, history back/forward, reload, copy URL, duplicate tab, new tab, close tab, restore tab, previous/next tab, go to tab 1 to 9 and last, focus first input, find in page, help overlay, go up one URL level, go to the URL root, zoom, a command bar (optional later).
- Key sequences (`g g`, `y y`) with a configurable timeout, modifiers, `shift+` variants.
- **Swedish keyboard:** I type on a Swedish layout. Keys like `ö`, `ä`, `å` must be mappable. Support both the typed character and the physical key (for example `ö` and `semicolon` are the same key) and show which one the config uses.
- Link hints: home-row labels, filter as you type, hint overlay that does not break layout, works in iframes and shadow DOM, avoids hidden elements, handles single-page apps. Hint look comes from the config and has several themes. Make the default a modern one (dark translucent pill, soft border, rounded, subtle shadow, readable font), not yellow.
- Do nothing in text fields and on excluded sites, but keep Cmd shortcuts untouched.
- Do not rely on browser APIs Safari lacks. Check each API against current Safari docs.

### 3. The settings app (SwiftUI, macOS)

A good, modern settings interface, not a text box:

- Pick the active preset, create and duplicate presets.
- A searchable list of every command with its key(s). Click a key to record a new one (press the keys, it captures them, handles sequences and the Swedish keys), warn about conflicts, reset one or all.
- Hint appearance with a **live preview**: theme picker, characters, colors, font, size, corner radius, shadow.
- Excluded sites list.
- Import and export of the JSON.
- A status area: is the extension enabled in Safari, config path, last change, and an "Open Safari extension settings" button.
- It reads and writes the same `config.json` (atomic writes, reacts to outside edits such as the script switching preset). Light and dark mode.

### 4. Also deliver

- `<name>ctl`, a small command-line tool (or script) to read and switch preset.
- A short README with build, signing (my personal Apple team, Safari's "Allow unsigned extensions" for development), install, and the Hammerspoon snippet that switches preset when a keyboard attaches.
- Unit tests for the key parser and sequence matcher at least.

## How to work

1. First read current Apple documentation for Safari Web Extensions and App Groups, and write down the bridge decision before coding.
2. Build in milestones and test each one in Safari: (a) extension loads, scrolls, config file read and live reload; (b) link hints with themes; (c) tabs and the rest of the commands; (d) settings app; (e) CLI and README.
3. Verify things by running them. Say what you verified and what you could not.
4. Do not touch any other app or my dotfiles. Put anything you want me to add to my dotfiles in the README.
5. Keep the code simple and readable. No unneeded abstractions, comments only for a non-obvious why.
6. When done, list the decisions you made so I can change them.
