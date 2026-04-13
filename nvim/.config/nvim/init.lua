-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Leader key (must be before lazy)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Fugitive worktree support
vim.g.fugitive_force_bash_on_windows = 1

-- General settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.equalalways = false
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- WSL clipboard integration via WSLg Wayland (native, no Windows .exe overhead)
vim.g.clipboard = {
  name = "wl-clipboard",
  copy = {
    ["+"] = "wl-copy",
    ["*"] = "wl-copy",
  },
  paste = {
    ["+"] = "wl-paste --no-newline",
    ["*"] = "wl-paste --no-newline",
  },
  cache_enabled = 0,
}
vim.opt.clipboard = "unnamedplus"
vim.opt.scrolloff = 8
vim.opt.cursorline = true
vim.o.winborder = "rounded"

-- Windows Terminal tab title: 📝 <worktree>
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local gitdir = vim.fn.system("git rev-parse --git-dir 2>/dev/null"):gsub("%s+$", "")
    local wt = "nvim"
    if gitdir:match("/worktrees/") then
      wt = gitdir:match("/worktrees/(.+)$")
    elseif gitdir == ".git" or gitdir:match("/.git$") then
      wt = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    end
    io.write(string.format("\027]0;[NVIM] - %s\a", wt))
  end,
})
vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    io.write("\027]0;\a")
  end,
})

-- Open nvim-tree on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    require("nvim-tree.api").tree.open()
  end,
})

-- Auto save on focus lost
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  pattern = "*",
  callback = function()
    if vim.bo.modified and vim.bo.buftype == "" then
      vim.cmd("silent! write")
    end
  end,
})

-- Clear search highlight
vim.keymap.set('n', '<C-0>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })

-- LSP window borders
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
vim.diagnostic.config({
  float = { border = "rounded" },
})

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  install = {
    missing = true,
    colorscheme = { "OceanicNext", "habamax" }
  },
  checker = { enabled = true, notify = false },
})

vim.keymap.set({'n', 'i'}, '<C-A-s>', '<cmd>wq<CR>', { noremap = true, desc = 'Save and quit' })

-- Load custom keymaps (managed by neovim-keymap-manager.sh)
local ok, keymaps = pcall(require, "keymaps")
if ok and keymaps.setup then
  keymaps.setup()
end
