---
name: vscode-keymap-rationale
description: "VSCode HJKL/JKLÖ keymap toggle rationale — Visual Line mode fix, mode-scoped bindings, Python JSON merging. Use when user mentions vscode keymap, visual line bug, movement keys, keymap toggle vscode, jklö vscode, keybinding modes, vscode vim modes, visual mode broken, linewise selection."
---

# VSCode HJKL/JKLÖ Mapping Approach

## Problem

VSCode keybindings were binding movement keys in ALL Vim modes (Normal, Visual, VisualLine, VisualBlock, Replace), which caused a critical bug in Visual Line mode where:
- Selection would only select characters to the column where cursor landed
- Delete would only delete the original line, not all selected lines
- Linewise selection semantics were completely broken

## Root Cause

VSCode keybindings were intercepting movement keys BEFORE VSCodeVim could process them with proper mode-specific behavior. In Visual Line mode, `cursorDownSelect` (character-level) was firing instead of VSCodeVim's linewise selection logic.

## Solution

Movement key bindings (h/j/k/l and j/k/l/ö) are now ONLY bound in:
- **Normal mode** (standard navigation)
- **Replace mode** (character replacement)

Movement keys are NOT bound in Visual, VisualLine, or VisualBlock modes — these are handled by VSCodeVim natively.

## Technical Details

The VSCode keybinding script (`vscode-keymap-manager.sh`) uses Python-based JSON merging to:
1. Preserve all custom keybindings (ctrl+p, ctrl+tab, etc.)
2. Filter out movement keys from existing file
3. Add only Normal and Replace mode movement key bindings
4. Merge everything together maintaining valid JSON structure

**Key Implementation:**
- Only 8 movement key bindings per mode (4 keys × 2 modes)
- Custom keybindings are automatically preserved across toggles
- No interference with VSCodeVim's native Visual mode handling
- All custom keybindings persist whether added to PERSISTENT_KEYBINDINGS or directly to VSCode
