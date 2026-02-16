# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS containing configuration files and scripts for various development tools and applications. The repository uses a bare git repository approach for dotfiles management.

## Key Tools and Applications

### Terminal and Shell
- **Ghostty**: Modern terminal emulator with glass effects and theme support
  - Config: `ghostty/.config/ghostty/config`
  - Theme: Uses dark:nightfox,light:catppuccin-latte.conf
  - Font: JetBrains Mono, size 15
- **Zsh**: Shell with Oh My Zsh framework
  - Config: `zsh/.zshrc`, `zsh/worktree-nav.zsh`
  - Theme: af-magic
  - Git plugin enabled

### Development Environment
- **Vim**: Text editor with minimal plugin setup
  - Config: `vim/.vimrc`
  - Plugin manager: vim-plug
  - Theme: catppuccin-latte
  - Cursor shapes configured for Ghostty terminal
- **SPF (Superfile)**: Terminal file manager
  - Config: `spf/.spf.toml`
  - Theme: catppuccin-latte
  - Editor: vim
- **Ranger**: Terminal file manager with HJKL/JKLÖ keymap integration
  - Config: `~/.config/ranger/rc.conf`
  - Copymap bindings toggle with main vim-keymap-toggle system
  - Alias: `r`

### Applications
- **MacroWhisper**: Voice-to-text application
  - Config: `macrowhisper/.config/macrowhisper/`
- **MyPaint**: Digital painting application
  - Config: `mypaint/.config/mypaint/`
- **iTerm2**: Alternative terminal (legacy configuration)
  - Config: `iterm/Default.json` and `iterm/Untitled.itermkeymap`

## Git Configuration Management

This repository uses the bare repository approach for dotfiles management:

```bash
# Main command alias for managing dotfiles
alias config='/usr/bin/git --git-dir=/Users/filipmellqvist/.dotfiles/ --work-tree=/Users/filipmellqvist'

# Usage examples:
config status
config add .vimrc
config commit -m "update vim config"
config push
```

## Development Aliases and Scripts

### Vim Keymap Management
Dynamic keymap switching system supporting both terminal Vim and VSCode/Cursor:
- `vimtoggle`: Toggle between default (HJKL) and custom (JKLÖ) keymaps
- `vimkeys status`: Show current keymap status
- `vimkeys default`: Force default HJKL mode
- `vimkeys custom`: Force custom JKLÖ mode

**Integration Features:**
- **Real-time hot-reload**: All running Vim instances switch automatically
- **VSCode/Cursor support**: Dynamically updates VSCodeVim extension settings
- **State persistence**: Remembers keymap choice across sessions
- **FastScripts integration**: System-wide keyboard shortcut access
- **Visual feedback**: Status line indicators and macOS notifications

**Key Files:**
- Main script: `my_scripts/.script/vim-keymap-toggle.sh`
- VSCode manager: `my_scripts/.script/vscode-keymap-manager.sh`
- Obsidian manager: `my_scripts/.script/obsidian-keymap-manager.sh`
- Ranger manager: `my_scripts/.script/ranger-keymap-manager.sh`
- State file: `vim/.vim/keymap_state`
- FastScripts: `~/Library/Scripts/Toggle Vim Keymaps.sh`
- Backups: `vim/.vim/vscode-backups/`, `vim/.vim/obsidian-backups/`, `vim/.vim/ranger-backups/`

#### VSCode HJKL/JKLÖ Mapping Approach (Updated)

**Problem Solved:**
Previously, VSCode keybindings were binding movement keys in ALL Vim modes (Normal, Visual, VisualLine, VisualBlock, Replace), which caused a critical bug in Visual Line mode where:
- Selection would only select characters to the column where cursor landed
- Delete would only delete the original line, not all selected lines
- Linewise selection semantics were completely broken

**Root Cause:**
VSCode keybindings were intercepting movement keys BEFORE VSCodeVim could process them with proper mode-specific behavior. In Visual Line mode, `cursorDownSelect` (character-level) was firing instead of VSCodeVim's linewise selection logic.

**Solution Implemented:**
Movement key bindings (h/j/k/l and j/k/l/ö) are now ONLY bound in:
- **Normal mode** ✅ (standard navigation)
- **Replace mode** ✅ (character replacement)

Movement keys are NOT bound in:
- **Visual mode** ✅ (character selection - handled by VSCodeVim)
- **VisualLine mode** ✅ (linewise selection - handled by VSCodeVim)
- **VisualBlock mode** ✅ (block selection - handled by VSCodeVim)

**Technical Details:**
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

**Result:**
✅ Visual Line mode now works correctly
✅ Linewise selection includes full lines
✅ Delete in Visual Line deletes all selected lines
✅ All custom keybindings remain preserved
✅ Normal mode navigation still works with HJKL/JKLÖ override

### Windows Terminal Settings
Config: `/mnt/c/Users/FilipM/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json`
- Frequently edited — keybindings, profiles, color schemes, behavior
- Hot-reloads on save
- Default profile: Ubuntu (WSL), Font: JetBrains Mono size 10, Theme: Banana Blueberry
- **Unbound keys** (`"id": null`): `Ctrl+A`, `Ctrl+W` — passed through to CLI apps (Claude Code needs them)
- **Ctrl+V** → Paste (kept bound — required for speech-to-text/MacroWhisper clipboard paste)
- **Custom bindings**: `Ctrl+Shift+W` close pane (built-in default), `Ctrl+H/J/K/L` move focus, `Ctrl+Backspace` delete word, `Alt+-` split down
- To unbind a key: `{ "id": null, "keys": "ctrl+x" }` in the `keybindings` array

### Keyboard Remap Toggle Menu
Interactive menu: `C:\Users\FilipM\Desktop\Keys\interactive-menu-toggle-remaps.bat`
- Toggle ESC/CapsLock, Alt+HJKL, Vim/VSCode/Rider/Neovim/Obsidian/Ranger HJKL/JKLÖ remaps
- Batch set all to Standard or Voyager mode
- Uses: `bash-toggle-esc.sh`, `bash-toggle-alt-hjkl.sh`, `toggle-vim-layout-hjkl-jkloe.bat`, `get-all-status.sh`, `hotkeys-and-remaps.ahk`

### Port Management
Zsh port management aliases:
- `kill3000`, `kill3001`, `kill3002`, `kill3003`, `kill5555`: Kill processes on specific ports
- `3000`, `3001`, `3002`, `3003`: Kill port processes and start development servers
- `npm3001`, `npm3002`, `npm3003`: Start npm dev servers on specific ports
- `5555`: Kill port 5555 and start Prisma Studio
- `killnpmall`: Kill all npm development ports (3000-3002)

### Application Shortcuts
- `sp`: Start SPF file manager with config
- `mw`: Start MacroWhisper
- `r`: Start ranger file manager
- `obs`: Open Obsidian vault directory in ranger
- `tm`: Start task-master
- `sz`: Source/reload `~/.zshrc`

### Worktree Navigation (@prefix)
Quick navigation to Phoenix worktrees in `C:\Dev` (Windows) or `/mnt/c/Dev` (WSL).

**Usage:**
- `cd @` + Tab → lists worktrees (`phoenix`, `phoenix-export`, `server`)
- `cd @phoenix` → root folder (flat: `/mnt/c/Dev/phoenix`, nested: `.../Phoenix`)
- `cd @phoenix/s` → server folder, `cd @phoenix/c` → client folder
- `c @phoenix` → cd to worktree + launch Claude Code
- `c @phoenix/s` → cd to server + launch Claude Code
- `c @phoenix --resume` → cd + launch with extra args
- Partial match: `cd @exp/s` → `phoenix-export/server`
- Exact match priority: `cd @phoenix` matches `phoenix` before `phoenix-export`

**Note:** `c` is a function (not an alias) defined in `worktree-nav.zsh`. Plain `c` launches claude, `c @...` navigates + launches.

**Detection:** Auto-detects worktrees with `.git` (file or folder) + `server/Phoenix` path.
**Structure:** Auto-detects flat (`server/Phoenix` at root) vs nested (`Phoenix/server/Phoenix`).

**Config files (keep in sync):**
- PowerShell 5.1: `C:\Users\FilipM\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
- PowerShell 7+: `C:\Users\FilipM\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
- Zsh: `zsh/worktree-nav.zsh` (sourced from `.zshrc`)

### Development Environment
- OpenJDK 11 configured at `/opt/homebrew/opt/openjdk@11/bin`
- Bun runtime configured
- Node.js development focused with TypeScript script execution

## Script Collection

The `my_scripts/.script/` directory contains various utility scripts:

### Certificate Management
- `ca-cert-creator/`: Scripts for creating CA certificates and SSL certificates
  - `creator.sh`, `creator_noconf.sh`, `creator_CA.sh`

### Audio Configuration
- `pulseaudio/`: PulseAudio configuration scripts
- `pulseaudio_volume.sh`: Volume control script
- `pulseaudio_sink_switch.sh`: Audio sink switching
- `sony_wh-1000xm3.sh`: Sony headphones configuration

### System Utilities
- `wacom-config.sh`, `wacom_precision_toggler.sh`: Wacom tablet configuration
- `feh_random_wallpaper.sh`, `feh_95_wallpaper.sh`: Wallpaper management
- `keyboard_layouts/`: Keyboard layout configurations
- `miniscripts/`: Collection of small utility scripts

## Configuration Patterns

### Theme Consistency
All applications use consistent theming:
- **Light theme**: catppuccin-latte
- **Dark theme**: catppuccin-mocha/nightfox
- **Font**: JetBrains Mono across all applications

### Editor Integration
- Vim configured with terminal cursor shape integration
- Consistent editor (vim) across file managers and configuration tools
- System clipboard integration enabled

## File Structure

```
.
├── ghostty/          # Terminal emulator config
├── vim/              # Vim editor configuration and plugins
├── zsh/              # Zsh shell configuration
│   ├── .zshrc
│   └── worktree-nav.zsh  # @prefix worktree navigation
├── spf/              # Superfile manager config
├── macrowhisper/     # Voice-to-text app config
├── mypaint/          # Digital painting app config
├── iterm/            # Legacy iTerm2 configuration
├── my_scripts/       # Collection of utility scripts
└── MW Macros.kmmacros # Keyboard Maestro macros
```

## Best Practices

When modifying configurations:
1. Test changes in the target application before committing
2. Use the `config` alias for all git operations in this repository
3. Maintain theme consistency across applications
4. Back up existing configurations before major changes
5. Document any new aliases or scripts added to the zsh configuration