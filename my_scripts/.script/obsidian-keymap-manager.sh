#!/bin/bash

# Obsidian Vim Keymap Manager
# Manages dynamic keybinding switching for Obsidian Vim plugin via .obsidian.vimrc
# Integrates with the main vim-keymap-toggle.sh system

# Obsidian vault locations
OBSIDIAN_VAULTS_DIR="/mnt/c/Users/FilipM/Documents/Obsidian"
VIMRC_BACKUPS_DIR="$HOME/.dotfiles/vim/.vim/obsidian-backups"

# Ensure backup directory exists
mkdir -p "$VIMRC_BACKUPS_DIR"

# Function to find all Obsidian vaults
find_obsidian_vaults() {
    if [[ ! -d "$OBSIDIAN_VAULTS_DIR" ]]; then
        echo "none"
        return 1
    fi

    local vaults=()
    for vault_dir in "$OBSIDIAN_VAULTS_DIR"/*/; do
        if [[ -d "$vault_dir/.obsidian" ]]; then
            vaults+=("${vault_dir%/}")
        fi
    done

    if [[ ${#vaults[@]} -eq 0 ]]; then
        echo "none"
        return 1
    else
        printf '%s\n' "${vaults[@]}"
    fi
}

# Function to backup current vimrc
backup_vimrc() {
    local vimrc_file="$1"

    if [[ -f "$vimrc_file" ]]; then
        local backup_file="$VIMRC_BACKUPS_DIR/vimrc-$(date +%Y%m%d-%H%M%S).bak"
        cp "$vimrc_file" "$backup_file"
        echo "📁 Backup created: $backup_file"
    fi
}

# Function to get default HJKL vimrc
get_default_vimrc() {
    cat << 'EOF'
" Default HJKL navigation
" (Standard vim keybindings - minimal configuration)

" Have j and k navigate visual lines rather than logical ones
nmap j gj
nmap k gk

" H and L for beginning/end of line
nmap H ^
nmap L $

" Quickly remove search highlights
nmap <F9> :nohl<CR>

" Yank to system clipboard
set clipboard=unnamed

" Go back and forward with Ctrl+O and Ctrl+I
exmap back obcommand app:go-back
nmap <C-o> :back<CR>
exmap forward obcommand app:go-forward
nmap <C-i> :forward<CR>

" Workspace navigation
nmap <C-w>h :obcommand workspace:split-horizontal<CR>
nmap <C-w>v :obcommand workspace:split-vertical<CR>
EOF
}

# Function to get custom JKLÖ vimrc
get_custom_vimrc() {
    cat << 'EOF'
" Custom JKLÖ navigation (HJKL remapped)
" Physical keys: j=left, k=down, l=up, ö=right

" Normal mode navigation
nmap j h
nmap k j
nmap l k
nmap ö l

" Visual mode navigation
vmap j h
vmap k j
vmap l k
vmap ö l

" Operator pending mode navigation
omap j h
omap k j
omap l k
omap ö l

" Line navigation with J and K (shift versions)
nmap J ^
nmap K $

" Quick line navigation alternatives
nmap H 0
nmap L $

" Quickly remove search highlights
nmap <F9> :nohl<CR>

" Yank to system clipboard
set clipboard=unnamed

" Go back and forward with Ctrl+O and Ctrl+I
exmap back obcommand app:go-back
nmap <C-o> :back<CR>
exmap forward obcommand app:go-forward
nmap <C-i> :forward<CR>

" Workspace navigation
nmap <C-w>h :obcommand workspace:split-horizontal<CR>
nmap <C-w>v :obcommand workspace:split-vertical<CR>
EOF
}

# Function to update vimrc in a vault
update_vault_vimrc() {
    local vault_path="$1"
    local mode="$2"  # "default" or "custom"

    local vimrc_file="$vault_path/.obsidian.vimrc"

    # Backup existing vimrc if it exists
    if [[ -f "$vimrc_file" ]]; then
        backup_vimrc "$vimrc_file"
    fi

    # Write new vimrc based on mode
    if [[ "$mode" == "custom" ]]; then
        get_custom_vimrc > "$vimrc_file"
    else
        get_default_vimrc > "$vimrc_file"
    fi

    echo "✅ Updated: $vimrc_file"
}

# Function to apply keymap mode to all vaults
apply_keymap_mode() {
    local mode="$1"  # "default" or "custom"

    local vaults=$(find_obsidian_vaults)

    if [[ "$vaults" == "none" ]]; then
        echo "📝 No Obsidian vaults found. Skipping Obsidian integration."
        return 0
    fi

    echo "🔧 Updating Obsidian vaults for $mode mode..."

    while IFS= read -r vault_path; do
        update_vault_vimrc "$vault_path" "$mode"
    done <<< "$vaults"

    if [[ "$mode" == "custom" ]]; then
        echo "🎯 Obsidian: CUSTOM (JKLÖ) keybindings activated"
    else
        echo "🎯 Obsidian: DEFAULT (HJKL) keybindings activated"
    fi

    return 0
}

# Function to show current status
show_status() {
    local vaults=$(find_obsidian_vaults)

    echo "🔧 Obsidian Vim Integration Status"
    echo "===================================="

    if [[ "$vaults" == "none" ]]; then
        echo "Status: No Obsidian vaults found"
        return 0
    fi

    echo "Vaults found:"
    while IFS= read -r vault_path; do
        local vault_name=$(basename "$vault_path")
        local vimrc_file="$vault_path/.obsidian.vimrc"

        if [[ -f "$vimrc_file" ]]; then
            if grep -q "nmap j h" "$vimrc_file" 2>/dev/null; then
                echo "  • $vault_name: CUSTOM (JKLÖ)"
            else
                echo "  • $vault_name: DEFAULT (HJKL)"
            fi
        else
            echo "  • $vault_name: No .obsidian.vimrc found"
        fi
    done <<< "$vaults"

    echo ""
    echo "Backup directory: $VIMRC_BACKUPS_DIR"
}

# Main script logic
case "${1:-status}" in
    "default")
        apply_keymap_mode "default"
        ;;
    "custom")
        apply_keymap_mode "custom"
        ;;
    "status")
        show_status
        ;;
    *)
        echo "Usage: $0 [default|custom|status]"
        echo ""
        echo "Commands:"
        echo "  default - Apply default (HJKL) keybindings to Obsidian vaults"
        echo "  custom  - Apply custom (JKLÖ) keybindings to Obsidian vaults"
        echo "  status  - Show current Obsidian integration status"
        exit 1
        ;;
esac
