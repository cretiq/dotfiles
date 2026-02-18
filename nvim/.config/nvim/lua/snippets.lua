local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

-- Dynamically scan directories for Claude Code slash commands
-- Trigger format: c<folder>:<command> → expands to /<folder>:<command>
-- Type "cgit:" to see all git commands, "cconfig:" for config, etc.
-- Descriptions are extracted from YAML frontmatter if present.

local command_dirs = {
  { path = vim.fn.expand("~/.claude/commands"), label = "global" },
  { path = vim.fn.expand("~/.claude_phoenix/commands"), label = "phoenix" },
}

-- Extract description from YAML frontmatter (--- ... ---)
local function get_description(filepath)
  local f = io.open(filepath, "r")
  if not f then return nil end

  local first_line = f:read("*l")
  if not first_line or first_line:match("^%-%-%-") == nil then
    f:close()
    return nil
  end

  for line in f:lines() do
    if line:match("^%-%-%-") then
      break
    end
    local desc = line:match("^description:%s*(.+)")
    if desc then
      f:close()
      return desc
    end
  end

  f:close()
  return nil
end

local snippets = {}
local seen = {} -- deduplicate across directories

for _, entry in ipairs(command_dirs) do
  local dir = entry.path
  local label = entry.label
  if vim.fn.isdirectory(dir) == 1 then
    local files = vim.fn.globpath(dir, "**/*.md", false, true)
    for _, file in ipairs(files) do
      local rel = file:sub(#dir + 2):gsub("%.md$", "")
      local cmd = rel:gsub("/", ":")
      local trigger = "/" .. cmd

      if not seen[trigger] then
        seen[trigger] = true
        local desc = "[" .. label .. "] " .. (get_description(file) or cmd)
        table.insert(snippets, s(
          { trig = trigger, desc = desc },
          { t("/" .. cmd .. " "), i(1) }
        ))
      end
    end
  end
end

ls.add_snippets("all", snippets)
