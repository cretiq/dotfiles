---
name: catppuccin-theming
description: "Unified catppuccin theming across Ghostty, tmux, and nvim. Dark mode uses mocha, light mode uses latte. Each tool has its own appearance-switching mechanism. Use when user says catppuccin, theme, color scheme, dark mode, light mode, mocha, latte, unified theme, theme consistency, colors, appearance switching, dark light toggle, terminal colors, nvim theme."
---

# Catppuccin Theming

## Purpose
All terminal tools use catppuccin with mocha (dark) and latte (light). Each tool handles appearance switching differently.

## Theme Mapping

| Mode  | Flavor | Ghostty Theme | tmux Flavor | nvim Background |
|-------|--------|--------------|-------------|-----------------|
| Dark  | mocha  | `Catppuccin Mocha` | `mocha` | `dark` |
| Light | latte  | `Catppuccin Latte` | `latte` | `light` |

## Per-Tool Mechanism

### Ghostty
- **Config**: `ghostty/.config/ghostty/config`
- **Method**: Native `dark:`/`light:` theme syntax
  ```
  theme = "dark:Catppuccin Mocha,light:Catppuccin Latte"
  ```
- **Switching**: Automatic via Ghostty's built-in macOS appearance detection
- **Extra**: Split fill colors managed by appearance-watcher (catppuccin mantle values: dark=`181825`, light=`e6e9ef`)

### tmux
- **Config**: `tmux/.config/tmux/tmux.conf`
- **Plugin**: `catppuccin/tmux#v2.1.3` (via TPM)
- **Initial detection**: `run-shell` at config load checks `AppleInterfaceStyle`
- **Ongoing switching**: Appearance-watcher sets `@catppuccin_flavor`, unsets `@thm_*`, re-runs `catppuccin.tmux`
- **Override**: `window-style` and `window-active-style` reset `bg=default` so Ghostty controls terminal background
- **Lualine integration**: nvim lualine also uses `theme = "catppuccin"`

### nvim
- **Config**: `nvim/.config/nvim/lua/plugins/init.lua`
- **Plugin**: `catppuccin/nvim` with `flavour = "auto"`, `background = { light = "latte", dark = "mocha" }`
- **Switching**: `f-person/auto-dark-mode.nvim` polls macOS appearance and sets `vim.o.background`
- **Integrations enabled**: cmp, gitsigns, nvimtree, treesitter, mason

## Key Color Values (for manual reference)

| Color | Mocha (dark) | Latte (light) |
|-------|-------------|---------------|
| Mantle (split fill) | `181825` | `e6e9ef` |
| Text | via `@thm_text` | via `@thm_text` |
| Blue (active border) | via `@thm_blue` | via `@thm_blue` |
| Surface 0 (inactive border) | via `@thm_surface_0` | via `@thm_surface_0` |

## Key Gotchas

### tmux @thm_* variables use -o flag
Catppuccin theme files set variables with `set -o` (only-if-not-set). When switching flavors at runtime, all `@thm_*` must be unset first or old colors persist.

### nvim is independent
nvim uses its own `auto-dark-mode.nvim` plugin to detect appearance changes. It does not depend on the appearance-watcher script.

### Ghostty theme vs split fill
`theme = "dark:...,light:..."` handles the main terminal colors natively. But `unfocused-split-fill` doesn't support `dark:`/`light:` syntax, so the appearance-watcher handles it via sed.

## Adding a New Tool
To add catppuccin to another tool:
1. Install the catppuccin theme/plugin for that tool
2. Configure mocha for dark, latte for light
3. If the tool can't auto-detect macOS appearance, add a handler in `appearance-watcher.sh`
