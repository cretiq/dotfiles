# New Mac: window tools and Q10

One command rebuilds the setup from `~/.dotfiles` (cloned, branch `mac`):

```bash
~/.dotfiles/mac-setup/window-tools.sh
```

It is safe to run again. It installs Hammerspoon, AeroSpace, JankyBorders and stow with Homebrew, stows the `hammerspoon`, `aerospace` and `borders` packages, builds the Q10 tool into `~/.local/share/q10/q10`, runs its selftest, and restores Convey's hotkeys when Convey is installed and not running.

## By hand

1. Open Hammerspoon and AeroSpace once and grant Accessibility (System Settings, Privacy & Security). Hammerspoon's accessibility state stayed false until it was quit and relaunched, so relaunch it after granting.
2. Plug the Q10 in by cable. Hammerspoon applies the newest `keyboard/q10max/q10max-vN.json`. With the Launcher tab open the keyboard answers two programs and the apply fails, so close that tab.
3. Install the apps that are not in Homebrew: Convey (`~/CursorProjects/macapps/convey`, build with Xcode), CleanShot X (Setapp).
4. CleanShot's shortcuts live in its own preferences and are not versioned. They are ⇧⌘1 to 6 and ⇧⌘E, see `keyboard/q10max/docs/README.md`.
5. Turn off macOS's own ⇧⌘3/4/5 screenshot shortcuts so CleanShot gets them (Keyboard Shortcuts, Screenshots). On the current Mac they were already off.
6. BetterTouchTool is being retired. If it comes back, its Option+H/J/K/L triggers clash with the old bindings.

## Where each part lives

| Part | Location |
|---|---|
| Key bindings and layers | `keyboard/q10max/docs/README.md` |
| Layouts, Mac tool, Windows generator | `keyboard/q10max/` |
| Hammerspoon | `hammerspoon/.hammerspoon/init.lua` |
| AeroSpace | `aerospace/.config/aerospace/aerospace.toml` |
| Window border | `borders/.config/borders/bordersrc` |
| Convey hotkeys | `window-tools.sh` (they are Convey preferences, not files) |
