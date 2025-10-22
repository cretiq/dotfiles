# Unified Keymap Toggle System

## 🎯 Overview
Single command system to switch vim navigation keys across all applications:
- **Default Mode**: `h`←, `j`↓, `k`↑, `l`→ (standard vim)
- **Custom Mode**: `j`←, `k`↓, `l`↑, `ö`→ (your preferred layout)

## 🚀 Usage

```bash
vimtoggle           # Toggle between HJKL ↔ JKLÖ (all apps)
vimkeys status      # Show current state
vimkeys default     # Force HJKL mode
vimkeys custom      # Force JKLÖ mode
```

## 📱 Supported Applications

| Application | Status | Type |
|-------------|---------|------|
| **Terminal Vim** | ✅ | Real-time hot-reload |
| **VSCode/Cursor** | ✅ | Automatic settings update |
| **Ghostty Terminal** | ✅ | Automatic config update |
| **Vimium C (Edge)** | ✅ | Manual copy-paste required |
| **Superfile** | ✅ | Automatic hotkeys.toml update |

## 🔧 Individual App Commands

```bash
# Test individual apps
vscode-vim-keymap-manager.sh status
ghostty-keymap-manager.sh custom
vimium-keymap-manager.sh default
superfile-keymap-manager.sh status
```

## 📂 Key Files

- **Main Toggle**: `my_scripts/.script/vim-keymap-toggle.sh`
- **State File**: `vim/.vim/keymap_state`
- **Managers**: `my_scripts/.script/*-keymap-manager.sh`
- **Backups**: `vim/.vim/*/backups/`

## 🆕 Adding New Applications

Use the custom command to research integration:
```bash
/new-remapper [app_name]
```

This will thoroughly investigate the app's configuration system and create an implementation plan.

## 💡 Manual Setup Required

**Vimium C (Edge)**:
1. Run `vimtoggle` - copy the configuration shown
2. Open Edge → `edge://extensions/` → Vimium C → Options
3. Paste into "Custom key mappings" → Save

## 🔄 How It Works

1. **State Persistence**: Current mode saved in `keymap_state`
2. **Hot Reload**: Running vim instances update instantly
3. **Automatic Backups**: All changes create timestamped backups
4. **Unified Control**: One command updates all supported apps
5. **macOS Notifications**: Visual feedback when switching modes

## 🛠 Architecture

Each app has a dedicated manager script following this pattern:
- Detect installation
- Backup current config
- Apply keymap mode
- Trigger reload if possible
- Status reporting

The main toggle script orchestrates all managers and maintains global state.