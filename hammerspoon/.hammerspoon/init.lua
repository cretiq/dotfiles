require("hs.ipc")

local mods = {"alt"}
hs.hotkey.bind(mods, "h", function() hs.window.focusedWindow():focusWindowWest(nil, true, true) end)
hs.hotkey.bind(mods, "l", function() hs.window.focusedWindow():focusWindowEast(nil, true, true) end)
hs.hotkey.bind(mods, "k", function() hs.window.focusedWindow():focusWindowNorth(nil, true, true) end)
hs.hotkey.bind(mods, "j", function() hs.window.focusedWindow():focusWindowSouth(nil, true, true) end)

hs.alert.show("Hammerspoon config loaded")
