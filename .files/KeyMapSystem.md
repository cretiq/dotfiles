# KeyMap System Wiki

## What We Built

A unified keymap toggle system that switches between **HJKL** (default) and **JKLÖ** (custom) navigation across multiple applications:

- **Terminal Vim**: Hot-reload with real-time switching
- **VSCode/Cursor**: Automatic settings.json updates
- **Ghostty Terminal**: Pane navigation keybinding updates
- **System-wide access**: FastScripts keyboard shortcuts, terminal commands

## How It Works

```
User Input (FastScripts/Terminal)
    ↓
Main Controller (vim-keymap-toggle.sh)
    ↓
State File (keymap_state: "default" or "custom")
    ↓
Application Adapters
    ├─ Terminal Vim (file-based hot-reload)
    ├─ VSCode/Cursor (JSON settings update)
    └─ Ghostty Terminal (config file update)
```

## File Structure

```
~/.dotfiles/
├── vim/
│   ├── .vimrc                          # Loads keymap system
│   └── .vim/
│       ├── keymap_state                # Current mode
│       ├── keymaps/
│       │   ├── default.vim             # HJKL mappings
│       │   ├── custom.vim              # JKLÖ mappings
│       │   ├── auto-load.vim           # State-aware loading
│       │   └── hotreload.vim           # Real-time detection
│       ├── vscode-backups/             # VSCode config backups
│       └── ghostty-backups/            # Ghostty config backups
├── my_scripts/.script/
│   ├── vim-keymap-toggle.sh            # Main controller
│   ├── vscode-vim-keymap-manager.sh    # VSCode adapter
│   ├── ghostty-keymap-manager.sh       # Ghostty adapter
│   └── update-vscode-keybindings.py    # JSON processor
├── ghostty/.config/ghostty/config      # Ghostty terminal config
├── zsh/.zshrc                          # Terminal aliases
└── ~/Library/Scripts/
    └── Toggle Vim Keymaps.sh           # FastScripts integration
```

## Daily Usage

```bash
# Toggle between modes
vimtoggle

# Check status
vimkeys status

# Force specific mode
vimkeys default    # HJKL mode
vimkeys custom     # JKLÖ mode
```

**Within Vim:**
```vim
:KeymapToggle      # Toggle modes
:KeymapStatus      # Show current mode
```

**FastScripts:** System-wide keyboard shortcut (set in FastScripts app)

## Key Mappings

### Vim & VSCode/Cursor
| Mode | j | k | l | ö |
|------|---|---|---|---|
| **Default** | down | up | right | *unused* |
| **Custom** | left | down | up | right |

### Ghostty Terminal (Pane Navigation)
| Mode | Cmd+J | Cmd+K | Cmd+L | Right Navigation |
|------|-------|-------|-------|-----------------|
| **Default** | left | down | up | Cmd+H |
| **Custom** | left | down | up | **Cmd+Opt+Ctrl+O** |

> **Note**: The ö key (Cmd+ö) was problematic in Ghostty due to QMK keyboard firmware custom mappings interfering with the key detection. The solution uses **Cmd+Opt+Ctrl+O** instead, which works reliably across all keyboard setups.

## Adding New Applications

### 1. Create Application Adapter

Create `my_scripts/.script/[app-name]-keymap-manager.sh`:

```bash
#!/bin/bash

APP_NAME="[app-name]"
CONFIG_FILE="[path-to-app-config]"
BACKUP_DIR="$HOME/.dotfiles/vim/.vim/${APP_NAME}-backups"

# Detect if app is installed
detect_app() {
    if command -v [app-command] &> /dev/null; then
        echo "installed"
    else
        echo "not-installed"
    fi
}

# Apply keymap mode
apply_keymap_mode() {
    local mode="$1"  # "default" or "custom"

    if [[ $(detect_app) == "not-installed" ]]; then
        echo "📝 $APP_NAME not installed. Skipping."
        return 0
    fi

    # Backup current config
    cp "$CONFIG_FILE" "$BACKUP_DIR/config-$(date +%Y%m%d-%H%M%S).ext"

    # Update config based on mode
    if [[ "$mode" == "custom" ]]; then
        # Add JKLÖ mappings to config file
        echo "🎯 $APP_NAME: CUSTOM (JKLÖ) activated"
    else
        # Add HJKL mappings to config file
        echo "🎯 $APP_NAME: DEFAULT (HJKL) activated"
    fi
}

case "${1:-status}" in
    "default"|"custom")
        apply_keymap_mode "$1"
        ;;
    "status")
        echo "🔧 $APP_NAME Status: $(detect_app)"
        ;;
esac
```

### 2. Integrate with Main System

Add to `vim-keymap-toggle.sh` in the `trigger_vim_reload` function:

```bash
# Add your new app manager
NEW_APP_MANAGER="$HOME/.dotfiles/my_scripts/.script/[app-name]-keymap-manager.sh"

if [[ -x "$NEW_APP_MANAGER" ]]; then
    echo "🔄 Updating [App Name] keybindings..."
    "$NEW_APP_MANAGER" "$state_mode"
fi
```

### 3. Test Integration

```bash
chmod +x ~/.dotfiles/my_scripts/.script/[app-name]-keymap-manager.sh
vimtoggle  # Should now include your app
```

## Configuration Examples

### JSON-based Apps (like VSCode)
```json
{
    "vim.normalModeKeyBindings": [
        {"before": ["j"], "after": ["h"]},  // j → left
        {"before": ["k"], "after": ["j"]},  // k → down
        {"before": ["l"], "after": ["k"]},  // l → up
        {"before": ["ö"], "after": ["l"]}   // ö → right
    ]
}
```

### Config File Apps
```bash
# Update key-value config files
sed -i '/^nav\./d' "$CONFIG_FILE"  # Remove existing
cat >> "$CONFIG_FILE" << 'EOF'     # Add new mappings
nav.left=j
nav.down=k
nav.up=l
nav.right=ö
EOF
```

### Vim Script Apps
```vim
" Add to app's vim config
nnoremap j h  " left
nnoremap k j  " down
nnoremap l k  " up
nnoremap ö l  " right
```

## Troubleshooting

**Keys not switching:**
```bash
# Check state file
cat ~/.dotfiles/vim/.vim/keymap_state

# Test in Vim
:KeymapReload
```

**VSCode not updating:**
```bash
# Test VSCode manager directly
~/.dotfiles/my_scripts/.script/vscode-vim-keymap-manager.sh status
```

**Ghostty not updating:**
```bash
# Test Ghostty manager directly
~/.dotfiles/my_scripts/.script/ghostty-keymap-manager.sh status

# Restart Ghostty or create new tab (Cmd+T) to apply changes
# Check for configuration errors in Ghostty
```

**FastScripts not working:**
```bash
# Check script exists and is executable
ls -la ~/Library/Scripts/Toggle\ Vim\ Keymaps.sh
chmod +x ~/Library/Scripts/Toggle\ Vim\ Keymaps.sh
```

**QMK/Custom Keyboard Issues:**
If you have custom keyboard firmware (QMK) or hardware-level key remapping:
- Some key combinations may not reach the application level
- Try alternative key combinations (like Cmd+Opt+Ctrl+O instead of Cmd+ö)
- Test keybinds in a simple text editor first to verify they're detected
- Check your QMK configuration for conflicting mappings

**Reset everything:**
```bash
echo "default" > ~/.dotfiles/vim/.vim/keymap_state
vimkeys default
```

## Extension Ideas

- **Neovim**: Similar to Vim but different config location
- **JetBrains IDEs**: XML keymap files
- **Emacs (Evil mode)**: Elisp configuration
- **Web browsers**: Browser extension for vim plugins
- **More toggle types**: Different key layouts, mouse sensitivity, etc.

The pattern is always the same: detect app → backup config → update mappings → integrate with main controller.