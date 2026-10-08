require("hs.ipc")

-- Q10 layers each send a distinct modifier combo: L0 hyper, L1 l1, L2 alt+shift+cmd, L3 meh
local l1 = {"ctrl", "alt", "cmd"}
local meh = {"ctrl", "shift", "alt"}
hs.hotkey.bind(l1, "j", function() hs.window.focusedWindow():focusWindowWest(nil, true, true) end)
hs.hotkey.bind(l1, "k", function() hs.window.focusedWindow():focusWindowSouth(nil, true, true) end)
hs.hotkey.bind(l1, "l", function() hs.window.focusedWindow():focusWindowNorth(nil, true, true) end)
hs.hotkey.bind(l1, ";", function() hs.window.focusedWindow():focusWindowEast(nil, true, true) end)

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

hs.hotkey.bind({}, "f1", function()
  local win = hs.window.focusedWindow()
  if win then win:minimize() end
end)

hs.hotkey.bind({}, "f2", hs.spaces.toggleMissionControl)

local function mediaKey(name)
  return function()
    hs.eventtap.event.newSystemKeyEvent(name, true):post()
    hs.eventtap.event.newSystemKeyEvent(name, false):post()
  end
end
hs.hotkey.bind({}, "f7", mediaKey("PREVIOUS"))
hs.hotkey.bind({}, "f8", mediaKey("PLAY"))
hs.hotkey.bind({}, "f9", mediaKey("NEXT"))
hs.hotkey.bind({}, "f10", mediaKey("MUTE"))
volumeDownTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
  if e:getKeyCode() == hs.keycodes.map.f11 and next(e:getFlags()) == nil then
    mediaKey("SOUND_DOWN")()
    return true
  end
end):start()
hs.hotkey.bind({}, "f12", mediaKey("SOUND_UP"), nil, mediaKey("SOUND_UP"))

local lastDockMinimize = 0
dockScrollTap = hs.eventtap.new({hs.eventtap.event.types.scrollWheel}, function(e)
  local pos = hs.mouse.absolutePosition()
  local screen = hs.mouse.getCurrentScreen()
  if not screen or pos.y < screen:fullFrame().h - 110 then return false end
  local el = hs.axuielement.systemElementAtPosition(pos)
  if not el or el.AXSubrole ~= "AXApplicationDockItem" then return false end
  if e:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis1) < 0 and hs.timer.secondsSinceEpoch() - lastDockMinimize > 0.5 then
    lastDockMinimize = hs.timer.secondsSinceEpoch()
    local app = hs.application.find(el.AXTitle)
    if app then
      for _, win in ipairs(app:allWindows()) do win:minimize() end
    end
  end
  return true
end):start()

local function typeSlowly(text, delay, done)
  local i = 0
  local timer
  timer = hs.timer.doEvery(delay, function()
    i = i + 1
    hs.eventtap.keyStrokes(text:sub(i, i))
    if i == #text then
      timer:stop()
      if done then done() end
    end
  end)
end

hs.hotkey.bind(meh, "n", function()
  typeSlowly("/next ", 0.01, function() hs.eventtap.keyStroke({}, "return") end)
end)

hs.alert.show("Hammerspoon config loaded")
