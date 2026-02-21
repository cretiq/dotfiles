-- Neovim Movement Keymaps (Dynamically managed)
-- Reads keymap state from ~/.dotfiles/vim/.vim/keymap_state
-- Auto-switches between default (HJKL) and custom (JKLÖ) modes

local M = {}

-- Read keymap state from file
local function get_keymap_state()
  local state_file = os.getenv("HOME") .. "/.dotfiles/vim/.vim/keymap_state"
  local file = io.open(state_file, "r")
  if not file then
    return "default"
  end
  local content = file:read("*a"):match("^%s*(.-)%s*$")
  file:close()
  return content or "default"
end

-- Get current state on load
M.mode = get_keymap_state()

function M.setup()
  if M.mode == "custom" then
    -- Custom JKLÖ navigation
    -- j = left, k = down, l = up, ö = right
    vim.keymap.set({'n', 'v', 'o'}, 'j', 'h', { noremap = true, desc = 'Move left' })
    vim.keymap.set({'n', 'v', 'o'}, 'k', 'j', { noremap = true, desc = 'Move down' })
    vim.keymap.set({'n', 'v', 'o'}, 'l', 'k', { noremap = true, desc = 'Move up' })
    vim.keymap.set({'n', 'v', 'o'}, 'ö', 'l', { noremap = true, desc = 'Move right' })
    vim.keymap.set({'n', 'v', 'o'}, 'h', 'j', { noremap = true, desc = 'Move down (original j)' })
  else
    -- Default HJKL navigation (standard Vim)
    vim.keymap.set({'n', 'v', 'o'}, 'h', 'h', { noremap = true, desc = 'Move left' })
    vim.keymap.set({'n', 'v', 'o'}, 'j', 'j', { noremap = true, desc = 'Move down' })
    vim.keymap.set({'n', 'v', 'o'}, 'k', 'k', { noremap = true, desc = 'Move up' })
    vim.keymap.set({'n', 'v', 'o'}, 'l', 'l', { noremap = true, desc = 'Move right' })
  end

  -- Cmd+S (via Ghostty CSI u) = save and quit
  vim.keymap.set({'n', 'i', 'v'}, '<M-s>', '<Cmd>wq<CR>', { noremap = true, desc = 'Save and quit' })

  -- Page up/down bindings
  vim.keymap.set('n', '<C-k>', '<C-d>', { noremap = true, desc = 'Page down' })
  vim.keymap.set('n', '<C-l>', '<C-u>', { noremap = true, desc = 'Page up' })
end

return M
