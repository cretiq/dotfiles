#!/bin/bash
# Treeboard reads keymap_state every 2s automatically.
# On Windows, the Tauri app reads from ~/.config/treeboard/keymap_state (Windows home).
# The toggle script dual-writes to both WSL dotfiles and Windows config dir.
echo "🎯 Treeboard: keymap change will apply within 2s."
