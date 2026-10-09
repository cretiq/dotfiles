#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

brew list --cask hammerspoon >/dev/null 2>&1 || brew install --cask hammerspoon
brew list --cask aerospace >/dev/null 2>&1 || brew install --cask nikitabobko/tap/aerospace
brew list borders >/dev/null 2>&1 || brew install FelixKratz/formulae/borders
brew list stow >/dev/null 2>&1 || brew install stow

for pkg in hammerspoon aerospace borders; do stow -R "$pkg"; done

mkdir -p "$HOME/.local/share/q10"
swiftc -O -swift-version 5 keyboard/q10max/q10.swift -o "$HOME/.local/share/q10/q10"
"$HOME/.local/share/q10/q10" selftest | tail -1

if [ -d /Applications/Convey.app ] && ! pgrep -x Convey >/dev/null; then
  d=com.example.Convey
  defaults write $d cheatsheet_hotkey_keyCode -int 38
  defaults write $d cheatsheet_hotkey_modifiers -int 768
  defaults write $d keyboard_hotkey_keyCode -int 10
  defaults write $d keyboard_hotkey_modifiers -int 768
  defaults write $d keyboard_hotkey_disabled -bool false
  defaults write $d hotkey_keyCode -int 17
  defaults write $d hotkey_modifiers -int 6656
  echo "Convey hotkeys restored"
else
  echo "Convey hotkeys skipped (not installed, or running: quit it and run again)"
fi

cat <<'MSG'

Manual steps left, see mac-setup/README.md:
  1. Open Hammerspoon and AeroSpace once and grant Accessibility.
  2. Plug the Q10 in by cable: Hammerspoon applies the newest Mac layout.
  3. Close the Keychron Launcher tab if it is open.
MSG
