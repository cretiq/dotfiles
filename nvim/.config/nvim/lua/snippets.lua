local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

-- Claude Code snippet completion for slash commands and skills.
-- Scans: project, personal, phoenix commands/skills + enabled plugin commands/skills.
-- Priority (first wins dedup): project > personal > phoenix > plugins.

local home = vim.fn.expand("~")

-- Parse YAML frontmatter fields from a markdown file.
-- Returns table of { field = value } for all fields found.
local function parse_frontmatter(filepath)
  local f = io.open(filepath, "r")
  if not f then return {} end
  local first = f:read("*l")
  if not first or not first:match("^%-%-%-") then
    f:close()
    return {}
  end
  local fields = {}
  for line in f:lines() do
    if line:match("^%-%-%-") then break end
    local key, val = line:match("^(%w[%w_-]*):%s*(.+)")
    if key and val then
      fields[key] = val:gsub("^[\"'](.+)[\"']$", "%1")
    end
  end
  f:close()
  return fields
end

-- Scan a commands directory. Returns list of { file, trigger }.
local function scan_commands(dir, prefix)
  if vim.fn.isdirectory(dir) ~= 1 then return {} end
  local items = {}
  for _, file in ipairs(vim.fn.globpath(dir, "**/*.md", false, true)) do
    local rel = file:sub(#dir + 2):gsub("%.md$", "")
    local cmd = rel:gsub("/", ":")
    local trigger = prefix and ("/" .. prefix .. ":" .. cmd) or ("/" .. cmd)
    table.insert(items, { file = file, trigger = trigger })
  end
  return items
end

-- Scan a skills directory. Returns list of { file, trigger, frontmatter }.
local function scan_skills(dir, prefix)
  if vim.fn.isdirectory(dir) ~= 1 then return {} end
  local items = {}
  for _, file in ipairs(vim.fn.globpath(dir, "*/SKILL.md", false, true)) do
    local dir_name = file:match("([^/]+)/SKILL%.md$")
    if dir_name then
      local fm = parse_frontmatter(file)
      local name = fm.name or dir_name
      local trigger = prefix and ("/" .. prefix .. ":" .. name) or ("/" .. name)
      table.insert(items, { file = file, trigger = trigger, frontmatter = fm })
    end
  end
  return items
end

-- Find the latest version directory by modification time.
local function latest_version_dir(base)
  if vim.fn.isdirectory(base) ~= 1 then return nil end
  local dirs = vim.fn.globpath(base, "*", false, true)
  if #dirs == 0 then return nil end
  table.sort(dirs, function(a, b)
    return vim.fn.getftime(a) > vim.fn.getftime(b)
  end)
  return dirs[1]
end

-- Read enabledPlugins from settings.json and resolve cache paths.
local function get_enabled_plugins()
  local f = io.open(home .. "/.claude/settings.json", "r")
  if not f then return {} end
  local ok, settings = pcall(vim.json.decode, f:read("*a"))
  f:close()
  if not ok or not settings.enabledPlugins then return {} end
  local plugins = {}
  for key, enabled in pairs(settings.enabledPlugins) do
    if enabled then
      local name, marketplace = key:match("^(.+)@(.+)$")
      if name and marketplace then
        local base = home .. "/.claude/plugins/cache/" .. marketplace .. "/" .. name
        local ver_dir = latest_version_dir(base)
        if ver_dir then
          table.insert(plugins, { name = name, path = ver_dir })
        end
      end
    end
  end
  return plugins
end

-- Build source list in priority order (first wins dedup).
local cwd = vim.fn.getcwd()
local sources = {
  { label = "project",       items = scan_commands(cwd .. "/.claude/commands") },
  { label = "project-skill", items = scan_skills(cwd .. "/.claude/skills") },
  { label = "global",        items = scan_commands(home .. "/.claude/commands") },
  { label = "skill",         items = scan_skills(home .. "/.claude/skills") },
  { label = "phoenix",       items = scan_commands(home .. "/.claude_phoenix/commands") },
  { label = "phoenix-skill", items = scan_skills(home .. "/.claude_phoenix/skills") },
}

for _, plugin in ipairs(get_enabled_plugins()) do
  table.insert(sources, {
    label = plugin.name,
    items = scan_skills(plugin.path .. "/skills", plugin.name),
  })
  table.insert(sources, {
    label = plugin.name,
    items = scan_commands(plugin.path .. "/commands", plugin.name),
  })
end

-- Generate snippets from all sources.
local snippets = {}
local seen = {}

for _, source in ipairs(sources) do
  for _, item in ipairs(source.items) do
    if not seen[item.trigger] then
      seen[item.trigger] = true
      local fm = item.frontmatter or parse_frontmatter(item.file)
      local desc = "[" .. source.label .. "] " .. (fm.description or item.trigger:sub(2))
      table.insert(snippets, s(
        { trig = item.trigger, desc = desc },
        { t(item.trigger .. " "), i(1) }
      ))
    end
  end
end

ls.add_snippets("all", snippets)
