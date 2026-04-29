-- Neovim Movement Keymaps (Dynamically managed)
-- Reads keymap state from ~/.dotfiles/vim/.vim/keymap_state
-- Hot-reloads on FocusGained / CursorHold / keymap_trigger file
-- Mirrors ~/.dotfiles/vim/.vim/keymaps/hotreload.vim for parity with Vim

local M = {}

local state_file = os.getenv("HOME") .. "/.dotfiles/vim/.vim/keymap_state"
local trigger_file = os.getenv("HOME") .. "/.dotfiles/vim/.vim/keymap_trigger"

local function read_state()
  local f = io.open(state_file, "r")
  if not f then return "default" end
  local content = f:read("*a"):match("^%s*(.-)%s*$")
  f:close()
  if not content or content == "" then return "default" end
  return content
end

local function apply_mappings(mode)
  -- Drop bindings unique to custom mode before reapplying. pcall: no-op if unset.
  pcall(vim.keymap.del, { 'n', 'v', 'o' }, 'ö')

  if mode == "custom" then
    -- Custom JKLÖ: j=left, k=down, l=up, ö=right, h=down (original j)
    vim.keymap.set({ 'n', 'v', 'o' }, 'j', 'h', { noremap = true, desc = 'Move left' })
    vim.keymap.set({ 'n', 'v', 'o' }, 'k', 'j', { noremap = true, desc = 'Move down' })
    vim.keymap.set({ 'n', 'v', 'o' }, 'l', 'k', { noremap = true, desc = 'Move up' })
    vim.keymap.set({ 'n', 'v', 'o' }, 'ö', 'l', { noremap = true, desc = 'Move right' })
    vim.keymap.set({ 'n', 'v', 'o' }, 'h', 'j', { noremap = true, desc = 'Move down (original j)' })
  else
    -- Default HJKL (identity — restores standard Vim)
    vim.keymap.set({ 'n', 'v', 'o' }, 'h', 'h', { noremap = true, desc = 'Move left' })
    vim.keymap.set({ 'n', 'v', 'o' }, 'j', 'j', { noremap = true, desc = 'Move down' })
    vim.keymap.set({ 'n', 'v', 'o' }, 'k', 'k', { noremap = true, desc = 'Move up' })
    vim.keymap.set({ 'n', 'v', 'o' }, 'l', 'l', { noremap = true, desc = 'Move right' })
  end

  M.mode = mode
end

local function check_and_reload()
  local new_mode = read_state()
  if new_mode ~= M.mode then
    apply_mappings(new_mode)
    vim.schedule(function()
      local label = new_mode == "custom" and "CUSTOM (JKLÖ)" or "DEFAULT (HJKL)"
      vim.notify("Keymap hot-reload: " .. label, vim.log.levels.INFO)
    end)
  end
end

local function force_reload()
  if vim.fn.filereadable(trigger_file) == 1 then
    vim.fn.delete(trigger_file)
  end
  M.mode = nil
  check_and_reload()
end

M.mode = nil

function M.setup()
  apply_mappings(read_state())

  -- Pane navigation (mode-independent)
  vim.keymap.set('n', '<C-Left>', '<C-w>h', { noremap = true, desc = 'Pane left' })
  vim.keymap.set('n', '<C-Right>', '<C-w>l', { noremap = true, desc = 'Pane right' })
  vim.keymap.set('n', '<C-Up>', '<C-w>k', { noremap = true, desc = 'Pane up' })
  vim.keymap.set('n', '<C-Down>', '<C-w>j', { noremap = true, desc = 'Pane down' })

  -- Page up/down
  vim.keymap.set('n', '<C-k>', '<C-d>', { noremap = true, desc = 'Page down' })
  vim.keymap.set('n', '<C-l>', '<C-u>', { noremap = true, desc = 'Page up' })

  local group = vim.api.nvim_create_augroup("KeymapHotReload", { clear = true })
  vim.api.nvim_create_autocmd("FocusGained", { group = group, callback = check_and_reload })
  vim.api.nvim_create_autocmd("CursorHold", {
    group = group,
    callback = function()
      if vim.fn.filereadable(trigger_file) == 1 then
        force_reload()
      else
        check_and_reload()
      end
    end,
  })
  vim.api.nvim_create_autocmd("InsertEnter", { group = group, callback = check_and_reload })

  vim.api.nvim_create_user_command("KeymapReload", force_reload, {})
end

return M
