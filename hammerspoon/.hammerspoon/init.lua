require("hs.ipc")

local mods = {"alt"}
hs.hotkey.bind(mods, "h", function() hs.window.focusedWindow():focusWindowWest(nil, true, true) end)
hs.hotkey.bind(mods, "l", function() hs.window.focusedWindow():focusWindowEast(nil, true, true) end)
hs.hotkey.bind(mods, "k", function() hs.window.focusedWindow():focusWindowNorth(nil, true, true) end)
hs.hotkey.bind(mods, "j", function() hs.window.focusedWindow():focusWindowSouth(nil, true, true) end)

local hyper = {"cmd", "alt", "ctrl", "shift"}
local apps = {
  q = "Obsidian",
  f = "Finder",
  a = "Spotify",
  h = "Claude",
  c = "Microsoft Edge",
  z = "Bitwarden",
  j = "ChatGPT",
  e = "X Pro",
  x = "Xcode",
  b = "BetterTouchTool",
  s = "Simulator",
}
for key, app in pairs(apps) do
  hs.hotkey.bind(hyper, key, function() hs.application.launchOrFocus(app) end)
end

hs.alert.show("Hammerspoon config loaded")
