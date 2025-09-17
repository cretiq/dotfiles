#!/usr/bin/env python3

import json
import re
import sys
import os
from datetime import datetime

def fix_json_with_comments(content):
    """Fix JSON content that may have comments and trailing commas."""
    lines = content.split('\n')
    cleaned_lines = []

    for line in lines:
        # Remove full comment lines
        if re.match(r'^\s*//', line):
            continue
        # Remove inline comments
        line = re.sub(r'//.*$', '', line)
        cleaned_lines.append(line)

    content = '\n'.join(cleaned_lines)
    # Fix trailing commas
    content = re.sub(r',(\s*[}\]])', r'\1', content)
    return content

def get_default_keybindings():
    return {
        "vim.normalModeKeyBindingsNonRecursive": [
            {"before": ["u"], "commands": ["undo"]},
            {"before": ["U"], "commands": ["redo"]}
        ]
    }

def get_custom_keybindings():
    return {
        "vim.normalModeKeyBindingsNonRecursive": [
            {"before": ["u"], "commands": ["undo"]},
            {"before": ["U"], "commands": ["redo"]},
            {"before": ["j"], "after": ["h"]},
            {"before": ["k"], "after": ["j"]},
            {"before": ["l"], "after": ["k"]},
            {"before": ["ö"], "after": ["l"]}
        ],
        "vim.visualModeKeyBindingsNonRecursive": [
            {"before": ["j"], "after": ["h"]},
            {"before": ["k"], "after": ["j"]},
            {"before": ["l"], "after": ["k"]},
            {"before": ["ö"], "after": ["l"]}
        ],
        "vim.operatorPendingModeKeyBindingsNonRecursive": [
            {"before": ["j"], "after": ["h"]},
            {"before": ["k"], "after": ["j"]},
            {"before": ["l"], "after": ["k"]},
            {"before": ["ö"], "after": ["l"]}
        ]
    }

def backup_file(settings_file, backup_dir):
    """Create a backup of the settings file."""
    os.makedirs(backup_dir, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_file = os.path.join(backup_dir, f"settings-{timestamp}.json")

    with open(settings_file, 'r') as src, open(backup_file, 'w') as dst:
        dst.write(src.read())

    print(f"📁 Backup created: {backup_file}")
    return backup_file

def update_vscode_keybindings(settings_file, mode, backup_dir):
    """Update VSCode/Cursor keybindings."""

    try:
        # Create backup
        backup_file(settings_file, backup_dir)

        # Read and fix JSON
        with open(settings_file, 'r') as f:
            content = f.read()

        fixed_content = fix_json_with_comments(content)
        settings = json.loads(fixed_content)

        # Remove existing vim keybinding configurations
        vim_keys = [
            'vim.normalModeKeyBindingsNonRecursive',
            'vim.visualModeKeyBindingsNonRecursive',
            'vim.operatorPendingModeKeyBindingsNonRecursive',
            'vim.insertModeKeyBindingsNonRecursive'
        ]

        for key in vim_keys:
            settings.pop(key, None)

        # Add new keybindings
        if mode == "custom":
            new_keybindings = get_custom_keybindings()
        else:
            new_keybindings = get_default_keybindings()

        settings.update(new_keybindings)

        # Write updated settings
        with open(settings_file, 'w') as f:
            json.dump(settings, f, indent=4)

        print(f"✅ VSCode/Cursor keybindings updated to {mode} mode")
        return True

    except Exception as e:
        print(f"❌ Error updating keybindings: {e}")
        return False

def main():
    if len(sys.argv) != 4:
        print("Usage: update-vscode-keybindings.py <settings_file> <mode> <backup_dir>")
        sys.exit(1)

    settings_file = sys.argv[1]
    mode = sys.argv[2]
    backup_dir = sys.argv[3]

    if not os.path.exists(settings_file):
        print(f"❌ Settings file not found: {settings_file}")
        sys.exit(1)

    if mode not in ["default", "custom"]:
        print("❌ Mode must be 'default' or 'custom'")
        sys.exit(1)

    success = update_vscode_keybindings(settings_file, mode, backup_dir)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()