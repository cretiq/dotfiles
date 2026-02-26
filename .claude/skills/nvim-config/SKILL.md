---
name: nvim-config
description: "Neovim configuration for dotfiles repo. Catppuccin auto light/dark theming, lazy.nvim plugins, nvim-cmp completion, LuaSnip slash command/skill snippets, dynamic HJKL/JKLÖ keymaps, LSP setup, git integrations. Use when user says nvim, neovim, vim config, nvim plugins, completion menu, snippets, nvim theme, colorscheme, nvim keymaps, lsp config, nvim-cmp, luasnip, treesitter, nvim border, float border."
---

# Neovim Configuration

## Purpose
Personal Neovim setup: catppuccin theming with auto dark/light, lazy.nvim plugin management, LSP + completion, Claude Code snippet integration, and dynamic keymap switching.

## File Structure

```
nvim/.config/nvim/
├── init.lua              # Bootstrap, vim options, LSP borders
├── lazy-lock.json        # Plugin version lock
└── lua/
    ├── snippets.lua      # Claude Code command/skill snippet scanning
    ├── keymaps.lua       # Dynamic HJKL ↔ JKLÖ switching
    └── plugins/
        └── init.lua      # All plugin specs (362 lines)
```

## Architecture

### Theming
- **Catppuccin** with `flavour = "auto"` (latte for light, mocha for dark)
- **auto-dark-mode.nvim** syncs `vim.o.background` with macOS appearance
- Custom highlight: `FloatBorder = { bg = colors.base }` — prevents border bg mismatch
- Global `vim.o.winborder = "rounded"` for all floating windows (Neovim 0.11+)

### Snippet System (Claude Code Integration)
`snippets.lua` scans three locations per type at startup:

| Type | Glob Pattern | Trigger Format |
|------|-------------|----------------|
| Commands | `**/*.md` in `commands/` dirs | `/folder:command` |
| Skills | `*/SKILL.md` in `skills/` dirs | `/skill-name` |

**Scan order** (first match wins via `seen` table):
1. `~/.claude/commands/` or `~/.claude/skills/` (global)
2. `~/.claude_phoenix/commands/` or `~/.claude_phoenix/skills/` (phoenix)
3. `<cwd>/.claude/commands/` or `<cwd>/.claude/skills/` (project-local)

Skills get `[Skill]` prefix in description. Descriptions extracted from YAML frontmatter.

**Gotcha**: Scanning happens at startup only — new commands/skills require nvim restart.

### Completion (nvim-cmp)
- Sources: `nvim_lsp` > `luasnip` > `path` > `buffer` (fallback group)
- Windows: `bordered()` — uses global `winborder` for border style
- Menu labels: `cc` (snippets), `LSP`, `buf`, `path`
- Tab: smart — cycles menu items, expands/jumps snippets, or falls back to insert

### Dynamic Keymaps
- State file: `~/.dotfiles/vim/.vim/keymap_state` ("default" or "custom")
- Default: standard HJKL
- Custom: JKLÖ (Swedish keyboard layout)
- Hot-reload via external `vim-keymap-toggle.sh` script
- Module is optional — vim works without it

### LSP
- Mason auto-installs servers: `ts_ls`, `html`, `cssls`, `jsonls`, `lua_ls`, `pyright`
- `lua_ls` configured with `vim.env.VIMRUNTIME` library and `vim` global
- Keymaps: `gd` (definition), `gr` (references), `K` (hover), `<leader>ca` (code action), `<leader>rn` (rename)

### Git Integrations
- **gitsigns**: Inline signs, hunk navigation (`]g`/`[g`), stage/reset/blame
- **fugitive**: `<leader>gs` (status), `<leader>gc` (commit)
- **diffview**: `<leader>gd` (open), `<leader>gq` (close)
- **lazygit**: `<leader>gg`

## Key Gotchas

### FloatBorder background mismatch
Catppuccin's `FloatBorder` has a different bg than `Normal`. Fixed via `custom_highlights` setting bg to `colors.base`. Without this, float windows show a visible "thick border" effect.

### winborder vs cmp bordered()
`cmp.config.window.bordered()` calls `get_border()` which returns `vim.o.winborder` if set, else `'none'`. Without `vim.o.winborder = "rounded"` in init.lua, `bordered()` produces no visible border despite the function name.

### cmp winhighlight default
`bordered()` sets `Normal:Normal` — completion menu bg matches editor bg (no contrast). To add contrast, override with `Normal:Pmenu` in winhighlight. Current config uses default (no contrast, border-only distinction).

### Snippet cwd is startup-only
`vim.fn.getcwd()` in snippets.lua is evaluated once at load time. Changing directory after nvim starts won't rescan project-local commands/skills.

## Common Tasks

### Add a new plugin
Edit `nvim/.config/nvim/lua/plugins/init.lua`, add spec to the return table. Use lazy loading (`event`, `cmd`, or `keys`) where possible.

### Change completion window styling
Edit `window = { ... }` block in the cmp config section of `plugins/init.lua`. Override `bordered()` with opts: `border`, `winhighlight`, `side_padding`, `scrollbar`.

### Add new snippet scan directories
Edit `command_dirs` or `skill_dirs` tables in `snippets.lua`. Follow existing pattern.

### Override a highlight group
Add to `custom_highlights` function in catppuccin opts. Uses `colors` parameter for theme-aware values.
